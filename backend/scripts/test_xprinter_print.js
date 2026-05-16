/**
 * Test d'impression ESC/POS Xprinter XP-58IIT sous Windows.
 * Usage: node scripts/test_xprinter_print.js [nom_imprimante]
 * Exemple: node scripts/test_xprinter_print.js XP-58C
 */
const { execFileSync } = require('child_process');
const path = require('path');

const printerName = process.argv[2] || 'XP-58C';
const ps1 = path.join(__dirname, 'test_xprinter_print.ps1');

try {
  const out = execFileSync(
    'powershell.exe',
    [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      ps1,
      '-PrinterName',
      printerName,
      '-Line2',
      'Commande #123 - 2 Pizzas',
    ],
    { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] },
  );
  console.log(out);
  process.exit(0);
} catch (e) {
  console.error(e.stderr?.toString() || e.message);
  process.exit(1);
}
