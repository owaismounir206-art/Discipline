# Pubblicare Discipline gratuitamente

Discipline non ha costi di pubblicazione obbligatori: il modo gratuito è
**GitHub Releases** (APK da scaricare). Gli store ufficiali hanno costi
o requisiti propri, spiegati sotto.

## 1. Una volta sola: la chiave di firma Android

Serve per far riconoscere gli aggiornamenti come provenienti da te.
**Conservala al sicuro: se la perdi non potrai più aggiornare l'app.**

```bash
keytool -genkey -v -keystore ~/discipline-release.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias discipline
base64 -w0 ~/discipline-release.jks   # su Mac: base64 -i ~/discipline-release.jks
```

Nel repository: **Settings → Secrets and variables → Actions → New secret**:

| Segreto | Valore |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | l'output di `base64` |
| `ANDROID_KEYSTORE_PASSWORD` | password del keystore |
| `ANDROID_KEY_PASSWORD` | password della chiave |
| `ANDROID_KEY_ALIAS` | `discipline` |

Mai nel codice, mai in una issue. Per compilare in locale con la stessa
chiave copia `android/key.properties.example` in `android/key.properties`.

## 2. Pubblicare una versione

1. Aggiorna `version` in `pubspec.yaml` (es. `0.2.0+1`) e committa.
2. Crea e invia il tag:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```
   In alternativa: scheda **Actions → Rilascio → Run workflow**: legge la
   versione da `pubspec.yaml` e crea lei tag e release.
3. L'azione **Rilascio** esegue analisi e test, compila `.apk` e `.aab` e
   crea la release su GitHub con le impronte `SHA256SUMS.txt`.

## 3. Store (facoltativo)

- **F-Droid** (gratuito, solo software libero): è il posto naturale per
  Discipline. Si propone una richiesta nel repository `fdroiddata`. Discipline usa
  ML Kit (Google), che F-Droid considera non libero: per entrare servirebbe
  una variante senza conteggio automatico. Valuta insieme alla community.
- **Google Play**: account sviluppatore a pagamento una tantum (25 $).
  Si carica il file `.aab`. Servono scheda dello store, screenshot
  (`docs/screenshots`), l'informativa privacy (`PRIVACY.md` pubblicato come
  pagina web, ad esempio con GitHub Pages) e i test chiusi richiesti da
  Google per i nuovi account personali.
- **App Store (iOS)**: Apple Developer Program a pagamento (99 $/anno).
  L'azione CI compila già per iOS senza firma; per l'invio serve firmare
  su un Mac con Xcode e App Store Connect.

Prima di aprire a tutti: prova il conteggio con la fotocamera su più
telefoni e controlla che backup e ripristino funzionino passando da un
telefono all'altro.
