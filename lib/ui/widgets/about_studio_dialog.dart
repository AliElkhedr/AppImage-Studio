import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AboutStudioDialog extends StatelessWidget {
  const AboutStudioDialog({super.key});

  static const String githubRepoUrl = 'https://github.com/AliElkhedr/AppImage-Studio';
  static const String contributorsUrl = 'https://github.com/AliElkhedr/AppImage-Studio/graphs/contributors';
  static const String licenseUrl = 'https://github.com/AliElkhedr/AppImage-Studio/blob/main/LICENSE';
  static const String websiteUrl = 'https://alielkhedr.com';
  static const String blogPostUrl = 'https://www.alielkhedr.com/2026/09/appimage-studio.html';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {
      try {
        await Process.run('xdg-open', [url]);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Dialog(
      backgroundColor: isDark ? AppTheme.cardBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Container(
        width: 530,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Logo & Version
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(isDark ? 80 : 40),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.all_inclusive,
                          color: primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(isDark ? 30 : 25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withAlpha(isDark ? 120 : 180)),
                    ),
                    child: Text(
                      l10n.appVersion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Description
            Text(
              l10n.aboutAppDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),

            // Developer & Website Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground.withAlpha(150) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: secondary.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                      border: Border.all(color: secondary.withAlpha(120)),
                    ),
                    child: Icon(Icons.code, color: secondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.developerLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.developerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.websiteTooltip,
                    icon: Icon(Icons.language, color: primary, size: 20),
                    onPressed: () => _openUrl(websiteUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Community & Blog Article Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground.withAlpha(150) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, color: primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.contributorsSectionTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.contributorsPrompt,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Blog Post Link Button
                  InkWell(
                    onTap: () => _openUrl(blogPostUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: secondary.withAlpha(isDark ? 25 : 20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: secondary.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined, size: 15, color: secondary),
                          const SizedBox(width: 6),
                          Text(
                            l10n.blogPostButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 12, color: secondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(contributorsUrl),
                    icon: const Icon(Icons.groups, size: 16),
                    label: Text(l10n.contributorsButton, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: secondary),
                      foregroundColor: secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openUrl(githubRepoUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(
                      l10n.githubRepoButton,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.black87 : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Footer License and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _openUrl(licenseUrl),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      l10n.licenseNotice,
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
