# Privacy di Ritmo

Ultimo aggiornamento: 14 ottobre 2026.

Ritmo è un'app libera e gratuita. Non ha pubblicità, non vende dati e non
usa strumenti di tracciamento pubblicitario.

## Dati che restano sul telefono

Profilo atleta, allenamenti, streak, progressi e diario del cibo sono salvati
**solo sul tuo telefono**. Se disinstalli l'app, vengono cancellati.

## Dati inviati a servizi esterni

Solo quando usi queste funzioni (le prime due richiedono che chi distribuisce
l'app abbia collegato un server, vedi `docs/SERVER.md`):

- **Account e backup** (facoltativo): se crei un account, sul server
  (Supabase) restano email, nome scelto, codice amico, livello, stato
  online/offline, amicizie e sfide. Il backup dei tuoi dati viene caricato
  **solo se lo chiedi tu**. Dalle impostazioni puoi cancellare l'account: il
  server elimina tutto, a cascata.
- **Sfide con gli amici**: nome, codice utente e contatori della sfida sono
  condivisi con l'amico che sfidi. Il video e l'audio della sfida, se li attivi
  (richiedono un server LiveKit), passano solo tra i partecipanti e non
  vengono registrati.
- **Ricerca degli alimenti**: il testo che cerchi o il codice a barre
  scansionato vengono inviati a [Open Food Facts](https://world.openfoodfacts.org)
  per trovare i valori nutrizionali.

## Fotocamera e microfono

Il conteggio dei push-up con la fotocamera avviene **interamente sul
telefono**: le immagini non vengono salvate né inviate. Il
microfono si usa solo se accendi l'audio durante una sfida.

## Permessi

Fotocamera (conteggio e video), microfono (audio della sfida), notifiche
(promemoria che scegli tu) e rete (cibo, account, sfide). Nessuna posizione,
nessun contatto, nessun identificativo pubblicitario.

## Dati sanitari

Peso, altezza ed età servono solo a calcolare il fabbisogno e restano sul
telefono, salvo backup scelto da te. I valori nutrizionali sono stime e non
sostituiscono un nutrizionista.

## Contatti

Per domande apri una issue nel repository GitHub del progetto.

Quando aggiungeremo un servizio esterno, aggiorneremo questa pagina prima
di pubblicare la nuova versione.
