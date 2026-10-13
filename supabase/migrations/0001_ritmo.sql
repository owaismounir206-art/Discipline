-- Ritmo — app di calisthenics libera e gratuita.
-- Copyright (C) 2026 Ritmo contributors
-- SPDX-License-Identifier: GPL-3.0-or-later
--
-- Schema del server (Supabase / PostgreSQL) per account, amici, sfide in
-- tempo reale e backup. Si applica una volta sola: vedi docs/SERVER.md.
--
-- Principi:
-- - si salva il minimo indispensabile (nome scelto, codice amico, livello,
--   ultima attività, sfide e un backup che l'utente decide di caricare);
-- - Row Level Security ovunque: ognuno vede solo i propri dati e quelli
--   degli amici che ha aggiunto;
-- - le sfide si modificano solo tramite funzioni che controllano le regole
--   (i conteggi possono solo salire, il via lo decide l'orologio del server).

create extension if not exists pgcrypto;

-- ------------------------------------------------------------------ Profili

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  friend_code text not null unique check (friend_code ~ '^[A-HJ-NP-Z2-9]{6}$'),
  level text check (char_length(level) <= 20),
  status text not null default 'offline'
    check (status in ('online', 'training', 'offline')),
  last_seen timestamptz not null default now()
);

-- Codice amico casuale: 6 caratteri senza 0/O e 1/I.
create function public.new_friend_code() returns text
language plpgsql volatile set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code text;
begin
  loop
    code := '';
    for i in 1..6 loop
      code := code || substr(alphabet, 1 + floor(random() * 32)::int, 1);
    end loop;
    exit when not exists (
      select 1 from public.profiles p where p.friend_code = code
    );
  end loop;
  return code;
end $$;

-- Alla registrazione crea il profilo con il nome scelto nell'app.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, name, friend_code)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), 'Atleta'), 40),
    public.new_friend_code()
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -------------------------------------------------------------------- Amici

create table public.friendships (
  user_id uuid not null references public.profiles (id) on delete cascade,
  friend_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

create function public.is_friend(other uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships f
    where f.user_id = auth.uid() and f.friend_id = other
  );
$$;

-- Aggiunge un amico con il suo codice (l'amicizia vale nei due sensi).
create function public.add_friend_by_code(code text)
returns table (id uuid, name text, level text, status text, last_seen timestamptz)
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  other uuid;
begin
  if me is null then raise exception 'Accedi per aggiungere amici'; end if;
  select p.id into other from public.profiles p
  where p.friend_code = upper(regexp_replace(code, '[\s-]', '', 'g'));
  if other is null then raise exception 'Nessuno ha questo codice'; end if;
  if other = me then raise exception 'Questo è il tuo codice'; end if;
  insert into public.friendships (user_id, friend_id)
  values (me, other), (other, me)
  on conflict do nothing;
  return query
    select p.id, p.name, p.level, p.status, p.last_seen
    from public.profiles p where p.id = other;
end $$;

create function public.remove_friend(other uuid) returns void
language sql security definer set search_path = '' as $$
  delete from public.friendships
  where (user_id = auth.uid() and friend_id = other)
     or (user_id = other and friend_id = auth.uid());
$$;

-- -------------------------------------------------------------------- Sfide

create table public.challenge_rooms (
  id uuid primary key default gen_random_uuid(),
  mode text not null check (mode in ('headToHead', 'raceTo50', 'team')),
  host_id uuid not null references public.profiles (id) on delete cascade,
  invited_id uuid references public.profiles (id) on delete cascade,
  -- id → nome, id → ripetizioni, id → ripetizioni contate a mano.
  players jsonb not null default '{}'::jsonb,
  counts jsonb not null default '{}'::jsonb,
  manual jsonb not null default '{}'::jsonb,
  start_at timestamptz,
  cancelled boolean not null default false,
  created_at timestamptz not null default now()
);

create index challenge_rooms_invited on public.challenge_rooms (invited_id);

create function public.server_now() returns timestamptz
language sql stable as $$ select now(); $$;

create function public.my_name() returns text
language sql stable security definer set search_path = '' as $$
  select p.name from public.profiles p where p.id = auth.uid();
$$;

create function public.create_room(p_mode text, p_friend uuid default null)
returns uuid
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  room uuid;
begin
  if me is null then raise exception 'Accedi per sfidare gli amici'; end if;
  if p_friend is not null and not public.is_friend(p_friend) then
    raise exception 'Puoi sfidare solo i tuoi amici';
  end if;
  insert into public.challenge_rooms (mode, host_id, invited_id, players)
  values (p_mode, me, p_friend, jsonb_build_object(me::text, public.my_name()))
  returning id into room;
  return room;
end $$;

create function public.join_room(p_room uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
begin
  update public.challenge_rooms r
  set players = r.players || jsonb_build_object(me::text, public.my_name())
  where r.id = p_room and r.invited_id = me
    and r.start_at is null and not r.cancelled;
  if not found then raise exception 'La sfida non è più disponibile'; end if;
end $$;

-- Il via lo dà l'host: 3 secondi di conto alla rovescia, ora del server.
create function public.start_room(p_room uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.challenge_rooms r
  set start_at = now() + interval '3 seconds'
  where r.id = p_room and r.host_id = auth.uid()
    and r.start_at is null and not r.cancelled;
  if not found then raise exception 'Impossibile avviare la sfida'; end if;
end $$;

-- I conteggi possono solo salire: rimandare lo stesso valore dopo una
-- riconnessione non fa danni. Accettati solo durante la sfida (+10 s).
create function public.report_count(p_room uuid, p_count int, p_manual int)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  me text := auth.uid()::text;
begin
  if p_count < 0 or p_count > 500 or p_manual < 0 or p_manual > p_count then
    raise exception 'Conteggio non valido';
  end if;
  update public.challenge_rooms r
  set counts = r.counts || jsonb_build_object(
        me, greatest(coalesce((r.counts ->> me)::int, 0), p_count)),
      manual = r.manual || jsonb_build_object(
        me, greatest(coalesce((r.manual ->> me)::int, 0), p_manual))
  where r.id = p_room and r.players ? me and not r.cancelled
    and r.start_at is not null and now() >= r.start_at - interval '1 second'
    and now() <= r.start_at
      + case when r.mode = 'headToHead' then interval '60 seconds'
             else interval '5 minutes' end
      + interval '10 seconds';
end $$;

-- Uscire prima del via annulla la sfida.
create function public.leave_room(p_room uuid) returns void
language sql security definer set search_path = '' as $$
  update public.challenge_rooms r
  set cancelled = true
  where r.id = p_room and r.start_at is null
    and (r.host_id = auth.uid() or r.invited_id = auth.uid());
$$;

-- ------------------------------------------------------------------- Backup

create table public.backups (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

-- Cancella l'account e, a cascata, profilo, amicizie, sfide e backup.
create function public.delete_my_account() returns void
language sql security definer set search_path = '' as $$
  delete from auth.users where id = auth.uid();
$$;

-- --------------------------------------------------------------------- RLS

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.challenge_rooms enable row level security;
alter table public.backups enable row level security;

create policy "Vedo me e i miei amici" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_friend(id));

create policy "Modifico solo me" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- Il codice amico non si cambia a mano.
revoke update on public.profiles from authenticated;
grant update (name, level, status, last_seen) on public.profiles to authenticated;

create policy "Vedo le mie amicizie" on public.friendships
  for select to authenticated using (user_id = auth.uid());

create policy "Vedo le mie sfide" on public.challenge_rooms
  for select to authenticated
  using (
    host_id = auth.uid() or invited_id = auth.uid()
    or players ? (auth.uid()::text)
  );

create policy "Il mio backup" on public.backups
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Le funzioni si usano solo da utenti registrati.
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.add_friend_by_code(text),
  public.remove_friend(uuid),
  public.create_room(text, uuid),
  public.join_room(uuid),
  public.start_room(uuid),
  public.report_count(uuid, int, int),
  public.leave_room(uuid),
  public.server_now(),
  public.is_friend(uuid),
  public.delete_my_account()
to authenticated;

-- ---------------------------------------------------------------- Realtime

alter publication supabase_realtime
  add table public.profiles, public.friendships, public.challenge_rooms;
