# Discipline su iPhone

Discipline è la stessa app su Android e iPhone. Su iPhone però Apple
permette di installare app fuori dall'App Store solo in modi limitati:

| Modo | Costo | Limiti |
|---|---|---|
| **AltStore o SideStore** con il file `.ipa` delle Releases | gratis | va "rinnovata" ogni 7 giorni; massimo 3 app così |
| Xcode su un Mac, collegando l'iPhone | gratis | serve un Mac; anche qui scade dopo 7 giorni |
| App Store / TestFlight | 99 $ all'anno (Apple Developer Program) | nessuno, aggiornamenti automatici |

Per ora Discipline pubblica il file `.ipa` **senza firma**: lo firma lo
strumento che usi per installarlo, con il tuo ID Apple gratuito.

## Con AltStore (Windows o Mac + iPhone)

1. Sul computer installa **AltServer** da [altstore.io](https://altstore.io)
   e, da lì, installa **AltStore** sull'iPhone collegato con il cavo
   (ti chiede il tuo ID Apple: serve ad Apple per firmare l'app sul tuo
   telefono, non viene dato a Discipline).
2. Sull'iPhone: **Impostazioni → Privacy e sicurezza → Modalità sviluppatore**
   attiva (iOS 16 e successivi), poi riavvia.
3. Dall'iPhone apri le [Releases](https://github.com/owaismounir206-art/Discipline/releases),
   scarica `discipline-vX.Y.Z.ipa`, poi in AltStore **My Apps → +** e scegli
   il file.
4. Ogni 7 giorni AltStore rinnova la firma da solo, se iPhone e computer
   (con AltServer acceso) sono sulla stessa rete Wi-Fi.

[SideStore](https://sidestore.io) funziona allo stesso modo ma rinnova la
firma direttamente dall'iPhone, senza tenere acceso il computer.

## Aggiornamenti

Quando esce una versione nuova, l'app te lo dice nella schermata **Oggi** e
"Scarica" apre la pagina della release: scarica il nuovo `.ipa` e
installalo da AltStore sopra quello vecchio. I dati restano.

## Funziona tutto?

Sì: allenamenti, timer, sfide, cibo, scanner, promemoria e conteggio con la
fotocamera (ML Kit funziona anche su iPhone, dal modello con iOS 15.5 in
su). È però compilata e provata automaticamente, non ancora su un iPhone
vero: se qualcosa non va, apri una issue.
