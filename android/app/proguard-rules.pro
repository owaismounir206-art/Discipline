# Ritmo — regole per R8 (ottimizzatore delle build di release).
# Senza queste, R8 elimina classi che Android crea "per nome" e l'app si
# chiude appena aperta.

# WorkManager (usato dai plugin) crea il suo database Room per riflessione.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# LiveKit / WebRTC: classi usate dal codice nativo (JNI).
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
