#!/usr/bin/env bash
set -e

echo "🚀 [1/4] Building Flutter Linux Release..."
flutter build linux --release

echo "📁 [2/4] Preparing AppDir Structure..."
rm -rf build/AppDir
mkdir -p build/AppDir

# Copy release bundle
cp -r build/linux/x64/release/bundle/* build/AppDir/

# Copy desktop file and icon
cp linux/appimage.desktop build/AppDir/ 2>/dev/null || cat << 'EOF' > build/AppDir/appimage.desktop
[Desktop Entry]
Type=Application
Name=AppImage Studio
Comment=Package and distribute Linux applications as AppImage
Exec=AppRun %U
Icon=app_icon
Categories=Development;Utility;
Terminal=false
StartupNotify=true
EOF

# Copy Icon
if [ -f "assets/images/app_icon.png" ]; then
  cp assets/images/app_icon.png build/AppDir/app_icon.png
  cp assets/images/app_icon.png build/AppDir/.DirIcon
fi

# Create Smart Portable AppRun
cat << 'EOF' > build/AppDir/AppRun
#!/bin/sh
set -e
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${HERE}:${LD_LIBRARY_PATH}"
export PATH="${HERE}:${PATH}"
if [ -d "${HERE}/share/glib-2.0/schemas" ]; then
  export GSETTINGS_SCHEMA_DIR="${HERE}/share/glib-2.0/schemas:${GSETTINGS_SCHEMA_DIR}"
fi
export XDG_DATA_DIRS="${HERE}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
cd "${HERE}"
exec "${HERE}/appimage_studio" "$@"
EOF

chmod +x build/AppDir/AppRun
chmod +x build/AppDir/appimage_studio

echo "🔨 [3/4] Packaging AppImage..."
mkdir -p dist
export ARCH=x86_64

# Use bundled appimagetool or system one
if [ -f "assets/bin/appimagetool" ]; then
  ./assets/bin/appimagetool build/AppDir dist/AppImageStudio-x86_64.AppImage
elif which appimagetool > /dev/null 2>&1; then
  appimagetool build/AppDir dist/AppImageStudio-x86_64.AppImage
else
  echo "Downloading appimagetool..."
  curl -L -o /tmp/appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x /tmp/appimagetool
  /tmp/appimagetool build/AppDir dist/AppImageStudio-x86_64.AppImage
fi

chmod +x dist/AppImageStudio-x86_64.AppImage
echo "🎉 [4/4] Successfully created: dist/AppImageStudio-x86_64.AppImage"
