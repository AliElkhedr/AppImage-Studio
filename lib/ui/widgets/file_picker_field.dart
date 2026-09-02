import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class FilePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final IconData icon;
  final bool isDirectory;
  final List<String>? allowedExtensions;
  final ValueChanged<String> onChanged;

  const FilePickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.icon,
    this.isDirectory = false,
    this.allowedExtensions,
    required this.onChanged,
  });

  Future<void> _handlePick(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (isDirectory) {
        final result = await FilePicker.platform.getDirectoryPath(
          dialogTitle: label,
        );
        if (result != null && result.isNotEmpty) {
          onChanged(result);
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          dialogTitle: label,
          type: allowedExtensions != null ? FileType.custom : FileType.any,
          allowedExtensions: allowedExtensions,
        );
        if (result != null && result.files.single.path != null) {
          onChanged(result.files.single.path!);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.filePickError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.getPrimary(context);
    final borderColor = AppTheme.getBorder(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _handlePick(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceElevated : AppTheme.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value.isNotEmpty ? primaryColor.withAlpha(140) : borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : hint,
                    style: TextStyle(
                      color: value.isNotEmpty
                          ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                          : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
                      fontSize: 13,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.cardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDirectory ? Icons.folder_open : Icons.file_open,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.browseButton,
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
