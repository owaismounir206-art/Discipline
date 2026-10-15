# Privacy di Discipline

Ultimo aggiornamento: 14 ottobre 2026 (versione senza server).

Discipline è un'app libera e gratuita. Non ha pubblicità, non vende dati e non
usa strumenti di tracciamento pubblicitario.

## Dati che restano sul telefono

Profilo atleta, allenamenti, streak, progressi e diario del cibo sono salvati
**solo sul tuo telefono**. Se disinstalli l'app, vengono cancellati.

Non c'è nessun account e nessun server di Discipline: i punti, le sfide e
i risultati restano sul telefono.

## Dati inviati a servizi esterni

- **Ricerca degli alimenti**: il testo che cerchi o il codice a barre
  scansionato vengono inviati a [Open Food Facts](https://world.openfoodfacts.org)
  per trovare i valori nutrizionali.
- **Aggiornamenti**: una volta al giorno l'app chiede a GitHub
  (`api.github.com`) qual è l'ultima versione pubblicata. Non viene inviato
  nessun tuo dato, solo la richiesta con il nome dell'app. Puoi spegnerlo in
  Impostazioni > Controlla gli aggiornamenti.

- **AI (facoltativa, spenta di base)**: se inserisci una tua chiave di Groq
  o di Google AI Studio, quello che chiedi viene inviato a quel servizio
  con la tua chiave, secondo le sue condizioni d'uso:
  - diario del cibo: il testo che scrivi ("due uova e una fetta di pane")
    oppure la foto del piatto che scatti o scegli;
  - coach AI e "Cosa cucino?": la domanda più un riassunto di livello,
    giorni di allenamento, luogo, varianti attuali, età, peso, altezza,
    obiettivo, dieta, allergie, valori mangiati oggi e serie di giorni.
  Il tuo nome non viene mai inviato e le conversazioni non vengono salvate. La chiave resta nel portachiavi protetto del telefono
  (Android Keystore / iOS Keychain) e non finisce nei backup. Puoi
  cancellarla in Impostazioni > AI per il diario del cibo.

Sono gli unici collegamenti a internet.

## Sfide con gli amici

Quando sfidi un amico, l'app crea un codice con il nome che hai scelto, la
sfida e il tuo punteggio. Sei tu a mandarlo (WhatsApp, Telegram...): l'app
non lo invia a nessuno.

## Backup

Il backup è un file che crei tu dalle impostazioni e salvi dove vuoi.
Contiene tutti i tuoi dati: tienilo al sicuro.

## Fotocamera

Il conteggio dei push-up con la fotocamera avviene **interamente sul
telefono**: le immagini non vengono salvate né inviate.

## Permessi

Fotocamera (conteggio e scanner dei codici a barre), notifiche (promemoria
che scegli tu) e rete (ricerca degli alimenti e controllo degli aggiornamenti). Nessun microfono,
nessuna posizione, nessun contatto, nessun identificativo pubblicitario.

## Dati sanitari

Peso, altezza ed età servono solo a calcolare il fabbisogno e restano sul
telefono (e nel backup, se lo esporti). I valori nutrizionali sono stime e non
sostituiscono un nutrizionista.

## Contatti

Per domande apri una issue nel repository GitHub del progetto.

Quando aggiungeremo un servizio esterno, aggiorneremo questa pagina prima
di pubblicare la nuova versione.
