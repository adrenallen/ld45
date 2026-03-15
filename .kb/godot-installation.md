# Installing Godot 4 (Headless, Linux x86_64)

## Quick Install

```bash
# Download Godot 4.6.1 stable
wget -q https://github.com/godotengine/godot-builds/releases/download/4.6.1-stable/Godot_v4.6.1-stable_linux.x86_64.zip -O /tmp/godot.zip

# Extract and install
cd /tmp && unzip -o godot.zip
chmod +x Godot_v4.6.1-stable_linux.x86_64
mv Godot_v4.6.1-stable_linux.x86_64 /usr/local/bin/godot

# Verify
godot --version
```

## Updating to a Newer Version

Replace `4.6.1` in the download URL with the desired version. Check available versions at:
- https://github.com/godotengine/godot/releases
- https://godotengine.org/download/linux/

The download URL pattern is:
```
https://github.com/godotengine/godot-builds/releases/download/<VERSION>-stable/Godot_v<VERSION>-stable_linux.x86_64.zip
```

## First Run: Import Project

Before running tests or exports, import the project resources:

```bash
cd /path/to/project
godot --headless --import
```

This generates the `.godot/` cache directory with imported assets.

## Running GUT Tests

```bash
godot --headless -s addons/gut/gut_cmdln.gd
```

Exit code 0 = all tests pass. Exit code 1 = failures exist.

## Notes

- Godot is a single self-contained binary — no system dependencies needed beyond basic libs.
- The `--headless` flag runs without a display server (no GUI).
- The `.godot/` directory is generated on import and should be gitignored.
