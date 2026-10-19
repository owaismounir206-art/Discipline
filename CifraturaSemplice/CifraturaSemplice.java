import javax.swing.*;
import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Optional;

/** Interfaccia grafica Swing per cifrare, decifrare o forzare file di testo (Cesare / Vigenère). */
public class CifraturaSemplice extends JFrame {
    private final JTextField fileOrigine = new JTextField(28);
    private final JTextField fileDestinazione = new JTextField(28);
    private final JTextField chiave = new JTextField(6);
    private final JTextField indizio = new JTextField(14);
    private final JComboBox<String> algoritmo = new JComboBox<>(new String[]{"Cesare", "Vigenère"});
    private final JRadioButton cifra = new JRadioButton("Cifra", true);
    private final JRadioButton decifra = new JRadioButton("Decifra");
    private final JRadioButton bruteForce = new JRadioButton("Brute force");
    private final JButton avvia = new JButton("Avvia");
    private final JTextArea log = new JTextArea(6, 40);

    public CifraturaSemplice() {
        super("Cifrature semplici");
        setDefaultCloseOperation(EXIT_ON_CLOSE);

        ButtonGroup g = new ButtonGroup();
        g.add(cifra); g.add(decifra); g.add(bruteForce);
        log.setEditable(false);

        JPanel p = new JPanel(new GridBagLayout());
        p.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        GridBagConstraints c = new GridBagConstraints();
        c.insets = new Insets(3, 3, 3, 3);
        c.anchor = GridBagConstraints.WEST;

        JButton sfoglia = new JButton("Sfoglia…");
        sfoglia.addActionListener(e -> scegliFile());
        riga(p, c, 0, "File di testo:", fileOrigine, sfoglia);
        riga(p, c, 1, "Parola indizio:", indizio, null);
        riga(p, c, 2, "Algoritmo:", algoritmo, null);
        riga(p, c, 3, "Chiave (max 4):", chiave, null);

        JPanel modo = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 0));
        modo.add(cifra); modo.add(decifra); modo.add(bruteForce);
        riga(p, c, 4, "Modalità:", modo, null);
        riga(p, c, 5, "File di destinazione:", fileDestinazione, null);

        c.gridx = 1; c.gridy = 6;
        p.add(avvia, c);
        c.gridx = 0; c.gridy = 7; c.gridwidth = 3; c.fill = GridBagConstraints.BOTH;
        p.add(new JScrollPane(log), c);

        bruteForce.addActionListener(e -> aggiornaModo());
        cifra.addActionListener(e -> aggiornaModo());
        decifra.addActionListener(e -> aggiornaModo());
        algoritmo.addActionListener(e -> aggiornaModo());
        avvia.addActionListener(e -> avviaOperazione());
        aggiornaModo();

        setContentPane(p);
        pack();
        setLocationRelativeTo(null);
    }

    private static void riga(JPanel p, GridBagConstraints c, int y, String etichetta, JComponent campo, JComponent extra) {
        c.gridy = y; c.gridwidth = 1; c.fill = GridBagConstraints.NONE;
        c.gridx = 0; p.add(new JLabel(etichetta), c);
        c.gridx = 1; p.add(campo, c);
        if (extra != null) { c.gridx = 2; p.add(extra, c); }
    }

    private void aggiornaModo() {
        chiave.setEnabled(!bruteForce.isSelected());
        indizio.setEnabled(bruteForce.isSelected());
    }

    private void scegliFile() {
        JFileChooser fc = new JFileChooser();
        if (fc.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            fileOrigine.setText(fc.getSelectedFile().getAbsolutePath());
        }
    }

    private void avviaOperazione() {
        String origine = fileOrigine.getText().trim();
        String dest = fileDestinazione.getText().trim();
        if (origine.isEmpty() || dest.isEmpty()) { errore("Indica file di origine e di destinazione."); return; }
        boolean vig = algoritmo.getSelectedIndex() == 1;
        boolean bf = bruteForce.isSelected();
        String k = chiave.getText().trim();
        String ind = indizio.getText();

        if (bf) {
            if (ind.isEmpty()) { errore("Per il brute force serve la parola indizio."); return; }
        } else if (vig ? !Cifrari.chiaveValida(k) : !k.matches("\\d{1,4}")) {
            errore(vig ? "Chiave Vigenère: da 1 a 4 caratteri alfanumerici (A-Z, a-z, 0-9)."
                       : "Chiave Cesare: un numero di al massimo 4 cifre.");
            return;
        }

        String testo;
        try {
            testo = Files.readString(new File(origine).toPath(), StandardCharsets.UTF_8);
        } catch (IOException ex) {
            errore("Impossibile leggere il file: " + ex.getMessage());
            return;
        }

        avvia.setEnabled(false);
        log.setText(bf ? "Brute force in corso…\n" : "");
        new SwingWorker<String, Void>() {
            @Override protected String doInBackground() throws Exception {
                String risultato;
                String nota;
                if (bf) {
                    Optional<Cifrari.Trovata> t = vig ? Cifrari.forzaVigenere(testo, ind) : Cifrari.forzaCesare(testo, ind);
                    if (t.isEmpty()) return "Nessuna chiave trovata: l'indizio \"" + ind + "\" non compare in nessun testo decifrato.";
                    risultato = t.get().testo();
                    nota = "Cifratura rotta. Chiave trovata: " + t.get().chiave();
                } else {
                    risultato = vig ? Cifrari.vigenere(testo, k, cifra.isSelected())
                                    : Cifrari.cesare(testo, Integer.parseInt(k), cifra.isSelected());
                    nota = (cifra.isSelected() ? "Cifrato" : "Decifrato") + " con successo.";
                }
                Files.writeString(new File(dest).toPath(), risultato, StandardCharsets.UTF_8);
                return nota + "\nCreato il file: " + dest;
            }
            @Override protected void done() {
                avvia.setEnabled(true);
                try { log.setText(get()); }
                catch (Exception ex) { log.setText("Errore: " + (ex.getCause() != null ? ex.getCause() : ex).getMessage()); }
            }
        }.execute();
    }

    private void errore(String m) {
        JOptionPane.showMessageDialog(this, m, "Errore", JOptionPane.ERROR_MESSAGE);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new CifraturaSemplice().setVisible(true));
    }
}
