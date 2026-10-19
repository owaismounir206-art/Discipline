import java.util.Optional;

/** Cifrario di Cesare e di Vigenère su alfabeto alfanumerico (A-Z, a-z, 0-9). */
public final class Cifrari {
    public static final String ALFABETO =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    public static final int N = ALFABETO.length();
    public static final int MAX_CHIAVE = 4;

    public record Trovata(String chiave, String testo) {}

    private Cifrari() {}

    /** Cesare: chiave = intero di al massimo 4 cifre (lo scostamento viene ridotto modulo 62). */
    public static String cesare(String testo, int chiave, boolean cifra) {
        int k = Math.floorMod(cifra ? chiave : -chiave, N);
        StringBuilder sb = new StringBuilder(testo.length());
        for (int i = 0; i < testo.length(); i++) {
            char c = testo.charAt(i);
            int p = ALFABETO.indexOf(c);
            sb.append(p < 0 ? c : ALFABETO.charAt((p + k) % N));
        }
        return sb.toString();
    }

    /** Vigenère: chiave alfanumerica di 1-4 caratteri; i caratteri fuori alfabeto non avanzano la chiave. */
    public static String vigenere(String testo, String chiave, boolean cifra) {
        int[] k = new int[chiave.length()];
        for (int i = 0; i < k.length; i++) k[i] = ALFABETO.indexOf(chiave.charAt(i));
        return vigenere(testo, k, cifra);
    }

    private static String vigenere(String testo, int[] k, boolean cifra) {
        StringBuilder sb = new StringBuilder(testo.length());
        int j = 0;
        for (int i = 0; i < testo.length(); i++) {
            char c = testo.charAt(i);
            int p = ALFABETO.indexOf(c);
            if (p < 0) { sb.append(c); continue; }
            int s = cifra ? k[j % k.length] : -k[j % k.length];
            sb.append(ALFABETO.charAt(Math.floorMod(p + s, N)));
            j++;
        }
        return sb.toString();
    }

    public static boolean chiaveValida(String chiave) {
        if (chiave.isEmpty() || chiave.length() > MAX_CHIAVE) return false;
        for (char c : chiave.toCharArray()) if (ALFABETO.indexOf(c) < 0) return false;
        return true;
    }

    /** Brute force su Cesare: prova tutti gli scostamenti 0..61. */
    public static Optional<Trovata> forzaCesare(String cifrato, String indizio) {
        for (int k = 0; k < N; k++) {
            String t = cesare(cifrato, k, false);
            if (t.contains(indizio)) return Optional.of(new Trovata(String.valueOf(k), t));
        }
        return Optional.empty();
    }

    /** Brute force su Vigenère: tutte le chiavi di lunghezza 1..4 (62^4 ≈ 14,8 milioni al massimo). */
    public static Optional<Trovata> forzaVigenere(String cifrato, String indizio) {
        for (int len = 1; len <= MAX_CHIAVE; len++) {
            int[] k = new int[len];
            while (true) {
                String t = vigenere(cifrato, k, false);
                if (t.contains(indizio)) {
                    StringBuilder ch = new StringBuilder();
                    for (int v : k) ch.append(ALFABETO.charAt(v));
                    return Optional.of(new Trovata(ch.toString(), t));
                }
                int i = len - 1;
                while (i >= 0 && ++k[i] == N) k[i--] = 0;
                if (i < 0) break;
            }
        }
        return Optional.empty();
    }
}
