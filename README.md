# Al-Fakhir System

Application de gestion restaurant : caisse (POS), menu, finances, impression tickets thermiques, API NestJS + PostgreSQL, client Flutter Windows.

## Prérequis

- Windows 10+
- [Flutter](https://docs.flutter.dev/get-started/install/windows) (desktop)
- [Node.js](https://nodejs.org/) LTS
- [PostgreSQL](https://www.postgresql.org/)

## Installation rapide

1. Copier `backend/.env.example` vers `backend/.env` et adapter (base de données, mots de passe).
2. Démarrer PostgreSQL, puis l’API :
   ```powershell
   .\run_backend.ps1
   ```
3. Déployer sur ce PC (build + raccourci Bureau) :
   ```powershell
   .\deploy_windows.ps1
   ```
   Ou mise à jour de l’app déjà installée :
   ```powershell
   .\mettre_a_jour_desktop.ps1
   ```

## Scripts utiles

| Script | Rôle |
|--------|------|
| `deploy_windows.ps1` | Installation complète (`%LOCALAPPDATA%\Programs\Al-Fakhir`) |
| `mettre_a_jour_desktop.ps1` | Rebuild + copie de l’app desktop |
| `install/scripts/sync_backend.ps1` | Copie API uniquement + redémarrage |
| `install/scripts/restart_api.ps1` | Redémarrer l’API |

## Structure

- `alfakhir_desktop/` — application Flutter (Windows)
- `backend/dist/` — API NestJS compilée
- `install/` — scripts d’installation et raccourcis

## Sécurité

Ne commitez **jamais** `backend/.env` (mots de passe, JWT). Le fichier `.env.example` sert de modèle sans secrets réels.
