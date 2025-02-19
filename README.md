# Auto-ReVanced Builder

Automated builder for ReVanced applications with a modular and maintainable codebase.

## Directory Structure

```
src/
  ├── core/           # Core utilities and shared functions
  │   ├── utils.sh    # Common utilities
  │   ├── download.sh # Download related functions
  │   └── patch.sh    # Patching related functions
  ├── builders/       # Individual build scripts
  │   ├── revanced.sh # ReVanced builder
  │   └── ...
  ├── config/         # Configuration files
  │   └── options/    # App-specific options
  └── ci/             # CI related scripts
      ├── check.sh    # Version check script
      └── ...
```

## Features

- Modular and maintainable codebase
- Automated builds via GitHub Actions
- Support for multiple architectures (arm64-v8a, armeabi-v7a)
- Version tracking and automatic updates
- Configurable patch options

## Usage

### Local Building

1. Build YouTube:
   ```bash
   ./src/builders/revanced.sh youtube [version] [arch]
   ```

2. Build YouTube Music:
   ```bash
   ./src/builders/revanced.sh youtube-music [version] [arch]
   ```

Options:
- `version`: Specific app version (optional)
- `arch`: Target architecture (default: arm64-v8a)

### GitHub Actions

The repository includes GitHub Actions workflows for automated builds:

1. Scheduled builds run daily at 9 AM UTC
2. Manual builds can be triggered via workflow dispatch
3. Supports building specific targets or all apps

## Configuration

### Patch Configuration

Patch configurations are stored in `src/patches/<app>/`:
- `include-patches`: List of patches to include
- `exclude-patches`: List of patches to exclude

Format:
```
patch_name|options  # With options
patch_name          # Without options
```

## Development

### Adding New Apps

1. Create a new builder script in `src/builders/`
2. Add patch configurations in `src/patches/`
3. Update CI workflow if needed

### Core Utilities

- `utils.sh`: Common utilities for logging, version handling, etc.
- `download.sh`: Functions for downloading from GitHub and APKMirror
- `patch.sh`: ReVanced patching utilities

## Requirements

- Java 17 or higher
- wget, unzip, jq
- GitHub CLI (for releases)

## License

This project is licensed under the MIT License - see the LICENSE file for details. 