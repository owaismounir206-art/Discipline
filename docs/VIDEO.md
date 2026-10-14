# Video durante le sfide (facoltativo)

Le sfide funzionano **senza video**: i contatori si aggiornano comunque in
tempo reale. Se vuoi che gli amici si vedano e si sentano mentre si
sfidano, puoi attivare [LiveKit](https://livekit.io) (open source).

## Costi e privacy

- LiveKit Cloud ha un piano gratuito con una quota mensile di minuti.
  Oltre la quota si paga: tienine conto prima di distribuire l'app.
- Si può ospitare da soli ([guida](https://docs.livekit.io/home/self-hosting/)):
  è gratuito, ma serve un server (non basta un hosting statico).
- Il video passa tra i telefoni (WebRTC) attraverso il server LiveKit.
  Ritmo non registra nulla.
- **Contare i push-up con la fotocamera è sempre locale**: le immagini
  restano sul telefono (ML Kit).

## Attivazione

1. Crea un progetto LiveKit e copia URL (`wss://...`), API key e API secret.
2. Pubblica la funzione che dà l'accesso alle stanze:
   ```bash
   supabase functions deploy livekit-token
   supabase secrets set LIVEKIT_API_KEY=... LIVEKIT_API_SECRET=...
   ```
   Il secret resta **solo** sul server Supabase, mai nell'app.
3. In `config/ritmo.json` imposta `LIVEKIT_URL` con l'URL `wss://...`.

La funzione dà il biglietto solo a chi partecipa alla sfida (lo controlla
con le stesse regole RLS del database) e vale 15 minuti.

## Durante la sfida

Con il video attivo la fotocamera è usata dal video, quindi le ripetizioni
si contano a mano con **+1**. Senza video, la fotocamera conta da sola i
push-up (pulsante fotocamera). Il microfono si accende solo se lo
tocchi.
