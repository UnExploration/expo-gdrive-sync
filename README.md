# Expo GDrive Sync

Automated build and upload scripts for Expo React Native projects. Build Android variants (debug, release APK, Play Store AAB) and upload to Google Drive via rclone.

Designed to work as a git submodule within your Expo project, providing a simple CLI interface for common build tasks without cloud build services.

## Features

- Build debug, release APK, and Play Store AAB
- Automatic signing configuration
- Upload to Google Drive
- Build cleanup
- Cross-platform (Linux, macOS, Windows)

## Prerequisites

- Node.js (v14+) and npm
- Expo CLI (`npm install -g expo-cli`)
- Android SDK with `ANDROID_HOME` environment variable
  - Download from [Android Studio](https://developer.android.com/studio) or [command line tools](https://developer.android.com/studio#command-tools)
  - Set `ANDROID_HOME` to SDK location (e.g., `export ANDROID_HOME=$HOME/Android/Sdk`)
- rclone (v1.50+) for uploads ([installation guide](https://rclone.org/install/))

## Installation

Add as a submodule to your Expo project:

```bash
git submodule add https://github.com/UnExploration/expo-gdrive-sync.git expo-gdrive-sync
```

Or clone directly into your project:

```bash
cd your-expo-project
git clone https://github.com/UnExploration/expo-gdrive-sync.git expo-gdrive-sync
```

## Quick Start

```bash
# 1. Ensure Android project exists (run from your Expo project root)
npx expo prebuild

# 2. Configure signing (for release builds)
./expo-gdrive-sync/exb setup-signing

# 3. Configure rclone with Google Drive
rclone config
# Create a new remote named "gdrive" when prompted

# 4. Build and upload
./expo-gdrive-sync/exb workflow playstore
```

## Configuration

Edit `expo-gdrive-sync/lib/config.sh` for custom settings:

```bash
GDRIVE_REMOTE="gdrive:"              # rclone remote name
TEMP_DIR="./builds"                  # Build output directory
DEFAULT_UPLOAD_FOLDER="Builds"       # Google Drive upload folder
```

For local overrides, create `expo-gdrive-sync/lib/config.local.sh` (automatically gitignored).

### Build Output Location

By default, builds are saved to `./builds/` relative to your project root.

Customize via environment variable:

```bash
export EXPO_BUILD_OUTPUT="/custom/path/to/builds"
./expo-gdrive-sync/exb build debug
```

Or via `expo-gdrive-sync/lib/config.local.sh`:

```bash
# In your-expo-project/expo-gdrive-sync/lib/config.local.sh
TEMP_DIR="/custom/path/to/builds"
```

## Commands

Usage: `./expo-gdrive-sync/exb <command> [args...]`

### build

```bash
./expo-gdrive-sync/exb build [debug|release|playstore]
```

- `debug` - Debug APK (no signing)
- `release` - Signed release APK
- `playstore` - Signed AAB for Play Store

### upload

```bash
./expo-gdrive-sync/exb upload <files> [folder]
```

Examples:
```bash
./expo-gdrive-sync/exb upload ./builds/*.apk
./expo-gdrive-sync/exb upload ./builds/* MyApp/Builds
```

### workflow

```bash
./expo-gdrive-sync/exb workflow [debug|release|playstore] [folder]
```

Build and upload in one command.

### cleanup

```bash
./expo-gdrive-sync/exb cleanup [OPTIONS]
```

Options: `-k N` (keep last N), `-g` (clean gradle), `-d` (dry-run), `-f` (force)

Examples:
```bash
./expo-gdrive-sync/exb cleanup --keep 3
./expo-gdrive-sync/exb cleanup --gradle
```

### setup-signing

```bash
./expo-gdrive-sync/exb setup-signing
```

Interactive signing configuration wizard.

## Signing Configuration

Release builds require Android signing:

```bash
./expo-gdrive-sync/exb setup-signing
```

Wizard guides keystore setup, validates credentials, and saves config to `.signing-config` (gitignored). Survives `expo prebuild --clean`.

## Project Structure

```
your-expo-project/
├── expo-gdrive-sync/
│   ├── exb                   # Main CLI (run this!)
│   ├── bin/                  # Commands
│   ├── lib/                  # Shared code
│   └── docs/
├── .signing-config           # Signing (gitignored)
├── builds/                   # Output (gitignored)
└── app.json
```

## Disk Space

Builds: 30-80 MB each. Gradle cache: several GB over time.

```bash
./expo-gdrive-sync/exb cleanup --keep 5
./expo-gdrive-sync/exb cleanup --gradle
```

## Troubleshooting

### Build fails with SDK errors

- Ensure Android SDK is configured with `ANDROID_HOME` environment variable
- Run `npx expo prebuild` if `android/` directory is missing

### Upload fails

- Verify rclone is installed: `rclone version`
- Check remote configuration: `rclone listremotes`
- Test connection: `rclone lsd gdrive:`

### Signing errors

- Verify environment variables are set correctly
- Check keystore file exists and is readable
- Validate keystore: `keytool -list -v -keystore my-release-key.keystore`

### Google Drive rate limiting

The upload script includes retry logic and rate limiting protection. If issues persist, wait 1-2 hours before retrying.

## License

MIT
