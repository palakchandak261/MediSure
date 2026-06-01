# 💊 MediSure

MediSure is an open-source Flutter app for prescription management, medicine reminders, ordering from nearby pharmacies, and simple health vitals tracking.

This repository is a local copy of the project. Use the instructions below to run the app locally and to push changes to the GitHub repository at https://github.com/palakchandak261/MediSure.

**Status:** Development — mobile (Android) and web targets supported.

---

## Key Features

- Nearby pharmacy discovery (OpenStreetMap/Overpass)
- Medicine reminders with snooze and adherence tracking
- Prescription upload with OCR (mobile/web fallback)
- Order flow with UPI payment support and order tracking
- Family profiles and health vitals logging

---

## Quick Start (Development)

Prerequisites:

- Flutter SDK (>= 3.10)
- Dart SDK (matching Flutter)
- Android Studio or VS Code
- Chrome (for web) or an Android device/emulator

Steps:

```bash
# Clone your fork (or change URL to your remote)
git clone https://github.com/palakchandak261/MediSure.git
cd MediSure

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on connected Android device/emulator
flutter run -d android
```

If you need to use a remote backend or API keys, see the "Configuration" section below.

---

## Configuration

Sensitive values (API keys, backend URLs) should not be committed. Use Dart defines or environment variables during runtime:

```bash
flutter run \
  --dart-define=ENABLE_REMOTE_BACKEND=true \
  --dart-define=BACKEND_BASE_URL=https://example.com \
  --dart-define=BACKEND_API_KEY=your_key \
  --dart-define=MAPS_API_KEY=your_maps_key
```

There is a `backend/` folder containing a Node.js example backend; configure its `.env` before running:

```powershell
cd backend
copy .env.example .env
# then edit .env to add keys and DB URLs
```

---

## How to Update This Repo (Git + GitHub)

If you want to push local changes to the GitHub repo `palakchandak261/MediSure`, use these commands.

- If the remote hasn't been set yet (one-time):

```bash
# set remote to your GitHub repo
git remote add origin https://github.com/palakchandak261/MediSure.git
# ensure main is default branch locally
git branch -M main
# push and set upstream
git push -u origin main
```

- Common workflow for updates (recommended):

```bash
# create a feature branch
git checkout -b update/readme

# stage and commit your changes
git add README.md
git commit -m "docs: improve README and setup instructions"

# push branch to origin
git push -u origin update/readme
```

Then open a Pull Request on GitHub from `update/readme` into `main` and request review.

If you prefer to commit directly to `main` locally (not recommended):

```bash
git add .
git commit -m "chore: update docs"
git push origin main
```

If Git rejects pushes due to diverged history, fetch and rebase/merge first:

```bash
git fetch origin
git pull --rebase origin main
# resolve conflicts if any, then
git push
```

---

## Contributing

- Create an issue for major changes or feature requests.
- Fork the repository, implement changes on a branch, and open a PR.
- Follow conventional commits for commit messages (e.g., `feat:`, `fix:`, `docs:`).

---

## Contact

If you have questions about running or contributing to this project, open an issue or contact the maintainer via GitHub.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

