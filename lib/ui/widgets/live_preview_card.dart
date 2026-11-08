import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/models/app_metadata.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class LivePreviewCard extends StatelessWidget {
  final AppMetadata metadata;

  const LivePreviewCard({
    super.key,
    required this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final borderColor = AppTheme.getBorder(context);

    final displayTitle = metadata.appName.trim().isNotEmpty ? metadata.appName : l10n.appNameHint;
    final displayVersion = metadata.version.trim().isNotEmpty ? metadata.version : '1.0.0';
    final displayDesc = metadata.description.trim().isNotEmpty
        ? metadata.description
        : l10n.descriptionHint;
    final cleanName = metadata.appName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final filename = cleanName.isNotEmpty
        ? (displayVersion.isNotEmpty ? '$cleanName-$displayVersion.AppImage' : '$cleanName.AppImage')
        : 'app-1.0.0.AppImage';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.livePreviewTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(isDark ? 30 : 20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.liveBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  // App Icon Preview Tile (GNOME / KDE Launcher Style)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withAlpha(80)),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(isDark ? 40 : 25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildIconPreview(primary),
                  ),
                  const SizedBox(width: 18),
                  // App Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: secondary.withAlpha(isDark ? 40 : 30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v$displayVersion',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                metadata.category.getLocalizedLabel(l10n),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              metadata.executableName.isNotEmpty ? './${metadata.executableName}' : './executable',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.insert_drive_file_outlined, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                filename,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPreview(Color primary) {
    if (metadata.iconPath != null && metadata.iconPath!.isNotEmpty) {
      final file = File(metadata.iconPath!);
      if (file.existsSync()) {
        final ext = file.path.toLowerCase();
        if (ext.endsWith('.svg')) {
          return Padding(
            padding: const EdgeInsets.all(10),
            child: SvgPicture.file(file, fit: BoxFit.contain),
          );
        } else {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(primary),
          );
        }
      }
    }
    return _buildFallbackIcon(primary);
  }

  Widget _buildFallbackIcon(Color primary) {
    return Center(
      child: Icon(
        Icons.rocket_launch_outlined,
        color: primary,
        size: 36,
      ),
    );
  }
}
