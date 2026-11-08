import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/app_metadata.dart';

class BuildScriptGeneratorService {
  static const String scriptFileName = 'build_appimage.sh';

  /// Generates a standalone bash build script for the application
  static Future<File> generateScript({
    required String targetDirectory,
    required AppMetadata metadata,
  }) async {
    final scriptFile = File(p.join(targetDirectory, scriptFileName));
    final cleanAppName = metadata.appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');

    final content = '''#!/usr/bin/env bash
# ==============================================================================
# AppImage Studio - Standalone Build Script
# Generated for project: ${metadata.appName}
# ==============================================================================
set -e

APP_NAME="${metadata.appName}"
CLEAN_NAME="$cleanAppName"
EXEC_NAME="${metadata.executableName}"
VERSION="${metadata.version}"
CATEGORY="${metadata.category.freedesktopName}"
DESCRIPTION="${metadata.description}"
BUNDLE_DIR="\$(cd "\$(dirname "\$0")" && pwd)/${p.relative(metadata.bundlePath, from: targetDirectory)}"
OUTPUT_DIR="${metadata.outputPath.isNotEmpty ? metadata.outputPath : '\$(pwd)'}"
ICON_PATH="${metadata.iconPath != null ? metadata.iconPath! : ''}"

echo "=========================================================="
echo "🚀 Building AppImage for \$APP_NAME (v\$VERSION)"
echo "=========================================================="

# 1. Verify bundle directory and executable
if [ ! -d "\$BUNDLE_DIR" ]; then
  # Fallback to absolute bundle path
  BUNDLE_DIR="${metadata.bundlePath}"
fi

if [ ! -d "\$BUNDLE_DIR" ]; then
  echo "❌ Error: Bundle directory not found: \$BUNDLE_DIR"
  exit 1
fi

# 2. Check for appimagetool
APPIMAGETOOL=\$(command -v appimagetool || true)
if [ -z "\$APPIMAGETOOL" ]; then
  if [ -f "\$HOME/.local/bin/appimagetool" ]; then
    APPIMAGETOOL="\$HOME/.local/bin/appimagetool"
  elif [ -f "/tmp/appimagetool" ]; then
    APPIMAGETOOL="/tmp/appimagetool"
  else
    echo "⬇️ Downloading appimagetool..."
    curl -sL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
  fi
fi

# 3. Prepare AppDir
TEMP_DIR="/tmp/appimage_studio_\${CLEAN_NAME}_AppDir"
echo "📁 Preparing temporary AppDir: \$TEMP_DIR"
rm -rf "\$TEMP_DIR"
mkdir -p "\$TEMP_DIR"

echo "📦 Copying files from \$BUNDLE_DIR..."
cp -r "\$BUNDLE_DIR"/* "\$TEMP_DIR"/
chmod +x "\$TEMP_DIR/\$EXEC_NAME" 2>/dev/null || true

# 4. Generate AppRun
echo "⚙️ Generating AppRun launcher..."
cat << 'EOF' > "\$TEMP_DIR/AppRun"
#!/bin/sh
set -e
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\${HERE}/lib:\${HERE}:\${LD_LIBRARY_PATH}"
export PATH="\${HERE}:\${PATH}"
if [ -d "\${HERE}/share/glib-2.0/schemas" ]; then
  export GSETTINGS_SCHEMA_DIR="\${HERE}/share/glib-2.0/schemas:\${GSETTINGS_SCHEMA_DIR}"
fi
export XDG_DATA_DIRS="\${HERE}/share:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
cd "\${HERE}"
exec "\${HERE}/${metadata.executableName}" "\$@"
EOF
chmod +x "\$TEMP_DIR/AppRun"

# 5. Setup Icon
ICON_NAME="\$CLEAN_NAME"
if [ -n "\$ICON_PATH" ] && [ -f "\$ICON_PATH" ]; then
  EXT="\${ICON_PATH##*.}"
  cp "\$ICON_PATH" "\$TEMP_DIR/\${ICON_NAME}.\${EXT}"
  cp "\$ICON_PATH" "\$TEMP_DIR/.DirIcon"
fi

# 6. Generate .desktop file
cat << EOF > "\$TEMP_DIR/\${CLEAN_NAME}.desktop"
[Desktop Entry]
Type=Application
Name=\$APP_NAME
Exec=\$EXEC_NAME
Icon=\$ICON_NAME
Comment=\$DESCRIPTION
Categories=\$CATEGORY;
Terminal=false
StartupNotify=true
EOF

# 7. Package AppImage
mkdir -p "\$OUTPUT_DIR"
TARGET_APPIMAGE="\$OUTPUT_DIR/\${CLEAN_NAME}-\${VERSION}.AppImage"

echo "🗜️ Packaging with \$APPIMAGETOOL..."
ARCH=x86_64 "\$APPIMAGETOOL" "\$TEMP_DIR" "\$TARGET_APPIMAGE"
chmod +x "\$TARGET_APPIMAGE"

echo "=========================================================="
echo "✅ AppImage successfully built!"
echo "📍 Location: \$TARGET_APPIMAGE"
echo "=========================================================="
''';

    await scriptFile.writeAsString(content);
    await Process.run('chmod', ['+x', scriptFile.path]);
    return scriptFile;
  }
}

