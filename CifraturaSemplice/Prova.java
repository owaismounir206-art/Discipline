public class Prova {
    public static void main(String[] a) {
        String t = "Ciao mondo 2026, il SEGRETO e' qui.";
        for (int k : new int[]{0, 5, 61, 1234}) {
            String c = Cifrari.cesare(t, k, true);
            check(Cifrari.cesare(c, k, false).equals(t), "cesare " + k);
        }
        for (String k : new String[]{"a", "Zk", "x9Q", "Ab3z"}) {
            String c = Cifrari.vigenere(t, k, true);
            check(Cifrari.vigenere(c, k, false).equals(t), "vig " + k);
        }
        var r = Cifrari.forzaCesare(Cifrari.cesare(t, 37, true), "SEGRETO");
        check(r.isPresent() && r.get().chiave().equals("37") && r.get().testo().equals(t), "bf cesare");
        long s = System.currentTimeMillis();
        var v = Cifrari.forzaVigenere(Cifrari.vigenere(t, "Ab3z", true), "SEGRETO");
        check(v.isPresent() && v.get().testo().equals(t), "bf vig " + v.map(Cifrari.Trovata::chiave) + " " + (System.currentTimeMillis() - s) + "ms");
        check(Cifrari.forzaCesare("xyz", "NONC").isEmpty(), "bf nessuno");
    }
    static void check(boolean ok, String n) { System.out.println((ok ? "OK   " : "FAIL ") + n); }
}
