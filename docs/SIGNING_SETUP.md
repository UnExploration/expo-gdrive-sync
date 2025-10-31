# Android App Signing Setup

Android requires all release builds to be signed with a keystore. Debug and preview builds use an automatic debug keystore. Release APKs and Play Store AABs require your own production keystore.

## Quick Setup

Use the interactive setup wizard:

```bash
./expo-build-tools/setup-signing.sh
```

The wizard will:
1. Detect or generate keystore
2. Validate credentials
3. Save configuration to `.signing-config` (gitignored)
4. Auto-inject signing config after each build

Then build:

```bash
./expo-build-tools/build.sh release
./expo-build-tools/build.sh playstore
```

## Manual Setup

### Generate a Keystore

```bash
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore my-release-key.keystore \
  -alias my-key-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

Parameters:
- `-storetype PKCS12` - Modern keystore format
- `-keystore` - Output filename
- `-alias` - Key alias (needed later)
- `-validity 10000` - Valid for ~27 years

You will be prompted for:
1. Keystore password (remember this)
2. Key password (can be same as keystore password)
3. Distinguished name fields (name, organization, etc.)

### Configure app.json

```json
{
  "expo": {
    "name": "Your App Name",
    "slug": "your-app-slug",
    "version": "1.0.0",
    "android": {
      "package": "com.yourcompany.yourapp",
      "versionCode": 1
    }
  }
}
```

Important fields:
- `android.package` - Unique identifier (cannot change after first Play Store upload)
- `android.versionCode` - Integer version (increment for each release)
- `version` - Human-readable version string

### Configure Gradle Signing

#### Method 1: Environment Variables

Edit `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            if (System.getenv("KEYSTORE_PATH")) {
                storeFile file(System.getenv("KEYSTORE_PATH"))
                storePassword System.getenv("KEYSTORE_PASSWORD")
                keyAlias System.getenv("KEY_ALIAS")
                keyPassword System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
        }
    }
}
```

Set environment variables:

```bash
export KEYSTORE_PATH="/path/to/my-release-key.keystore"
export KEYSTORE_PASSWORD="your-keystore-password"
export KEY_ALIAS="my-key-alias"
export KEY_PASSWORD="your-key-password"
```

#### Method 2: Use Setup Wizard

The setup wizard handles this automatically by creating `.signing-config` and injecting the gradle configuration after each prebuild.

## Security

### Never Commit Keystores or Passwords

Add to `.gitignore`:

```gitignore
*.keystore
*.jks
signing.properties
.signing-config
android/app/release.keystore
android/app/*.keystore
```

### Backup Your Keystore

Store your keystore in multiple secure locations:
- Password manager (encrypted)
- Encrypted cloud storage
- Secure offline backup

Losing your keystore means you cannot publish updates to your existing Play Store app.

### Use Strong Passwords

- Minimum 12 characters
- Mix of letters, numbers, symbols
- Store in password manager

### CI/CD Secrets

For CI/CD pipelines:
- Use platform secret managers (GitHub Secrets, GitLab CI/CD Variables)
- Enable "masked" and "protected" flags
- Never log passwords or keystore contents

Encode keystore as base64 for storage:

```bash
# Encode
base64 my-release-key.keystore > keystore.base64.txt

# Decode in CI
echo "$KEYSTORE_BASE64" | base64 -d > release.keystore
```

## Troubleshooting

### Failed to read key from keystore

Cause: Incorrect password or alias

Solution:
- Verify `KEYSTORE_PASSWORD` matches
- Verify `KEY_ALIAS` matches exactly (case-sensitive)
- List aliases: `keytool -list -v -keystore my-release-key.keystore`

### Keystore file not found

Cause: `KEYSTORE_PATH` points to wrong location

Solution:
- Use absolute path: `/home/user/project/my-release-key.keystore`
- Verify file exists: `ls -la $KEYSTORE_PATH`

### INSTALL_FAILED_UPDATE_INCOMPATIBLE

Cause: APK signed with different keystore than installed version

Solution:
- Uninstall existing app: `adb uninstall com.yourcompany.yourapp`
- Use same keystore for all builds of same app

### Signing config missing after expo prebuild --clean

Cause: `expo prebuild` regenerates `android/` directory

Solution:
- Use environment variables (Method 1) - survives prebuild
- Or use setup wizard - auto-injects after each prebuild

### Play Store rejects AAB

Causes:
1. Version code not incremented
2. Package name doesn't match
3. Unsigned or incorrectly signed

Solutions:
- Increment `versionCode` in `app.json`
- Verify package name matches Play Store listing
- Verify AAB is signed: `jarsigner -verify -verbose -certs app-release.aab`

### Execution failed for validateSigningRelease

Cause: Signing configuration incomplete or invalid

Solution:
- Verify all 4 environment variables are set
- Check for typos in variable names
- Ensure keystore is readable: `chmod 644 my-release-key.keystore`

## Additional Resources

- [Expo documentation](https://docs.expo.dev/distribution/app-stores/)
- [Android signing documentation](https://developer.android.com/studio/publish/app-signing)
- [rclone documentation](https://rclone.org/drive/)

Remember: Your keystore is irreplaceable. Back it up securely.
