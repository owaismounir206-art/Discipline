# Server di Ritmo (facoltativo)

Ritmo funziona **tutta offline**: allenamenti, streak, diario del cibo e
progressi stanno sul telefono. Il server serve solo per:

- account e **backup** dei dati;
- **amici** (con codice o link d'invito) e **sfide in tempo reale**;
- (facoltativo) **video** durante le sfide, con LiveKit.

Usiamo [Supabase](https://supabase.com): è open source, ha un piano gratuito
e si può anche ospitare da soli. Nessuna chiave è nel repository.

## 1. Crea il progetto (gratis)

1. Crea un account su supabase.com e un nuovo progetto.
2. In **SQL Editor** incolla ed esegui il file
   `supabase/migrations/0001_ritmo.sql` (una volta sola).
3. In **Authentication → Providers → Email** lascia attivo l'accesso con
   email. Se non vuoi la conferma via email (comodo per provare), disattiva
   "Confirm email".
4. In **Project Settings → API Keys** copia l'URL del progetto e la
   *publishable key* (o la vecchia *anon*). **Non** usare mai la chiave
   *secret* / *service_role* nell'app.

## 2. Configura l'app

```bash
cp config/ritmo.example.json config/ritmo.json
# apri config/ritmo.json e incolla URL e publishable key
flutter run --dart-define-from-file=config/ritmo.json
```

`config/ritmo.json` è escluso da git. Per le build di release in GitHub
Actions metti gli stessi valori nei *secrets* del repository
(`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `LIVEKIT_URL`).

La chiave *publishable* è pensata per stare dentro le app: la sicurezza
sta nelle regole **Row Level Security** dello schema (ognuno vede solo i
propri dati e quelli degli amici; i conteggi delle sfide possono solo
salire; il via lo decide l'orologio del server).

## 3. Cosa viene salvato sul server

| Dato | Perché |
|---|---|
| email (gestita da Supabase Auth) | accedere |
| nome scelto, codice amico, livello, stato online | farti trovare dagli amici |
| amicizie | elenco amici |
| sfide (conteggi, orari) | gioco in tempo reale |
| backup (solo se lo carichi tu) | ripristino su un altro telefono |

Dalle impostazioni puoi cancellare l'account: sparisce tutto, a cascata.

## 4. Video con LiveKit (facoltativo)

Vedi `docs/VIDEO.md`.

## 5. Ospitarlo da soli

Supabase si può installare con Docker
([guida ufficiale](https://supabase.com/docs/guides/self-hosting)):
applica la stessa migrazione e usa l'URL del tuo server.

## Come provarlo in locale senza server

Senza `config/ritmo.json` l'app mostra "Sfide online non attive" e permette
le sfide **da solo** (allenamento a tempo). I test usano un server finto
(`MemoryBackend`) che simula account, amici e avversario.
