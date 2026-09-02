import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../core/models/app_metadata.dart';
import '../../core/services/appimage_builder_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/file_picker_field.dart';
import '../widgets/build_console_dialog.dart';
import '../widgets/about_studio_dialog.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<Locale?>? onLocaleChanged;
  final Locale? currentLocale;

  const HomeScreen({
    super.key,
    this.onLocaleChanged,
    this.currentLocale,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _metadata = AppMetadata();

  final _appNameController = TextEditingController();
  final _executableController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');
  final _descriptionController = TextEditingController();

  List<String> _detectedExecutables = [];

  @override
  void initState() {
    super.initState();
    final home = Platform.environment['HOME'] ?? '';
    final desktop = p.join(home, 'Desktop');
    if (Directory(desktop).existsSync()) {
      _metadata.outputPath = desktop;
    } else {
      _metadata.outputPath = home;
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _executableController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onBundlePathSelected(String path) {
    setState(() {
      _metadata.bundlePath = path;

      final dirName = p.basename(path);
      if (_appNameController.text.trim().isEmpty || _appNameController.text == 'bundle') {
        final candidateName = dirName == 'bundle' ? p.basename(p.dirname(path)) : dirName;
        _appNameController.text = candidateName;
        _metadata.appName = candidateName;
      }

      _scanForExecutables(path);
      _scanForIcon(path);
    });
  }

  Future<void> _scanForExecutables(String bundlePath) async {
    final dir = Directory(bundlePath);
    final executables = <String>[];

    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          if (!filename.endsWith('.so') && !filename.endsWith('.json') && !filename.endsWith('.txt')) {
            final stat = await entity.stat();
            if (stat.mode & 0x49 != 0) {
              executables.add(filename);
            }
          }
        }
      }
    } catch (_) {}

    setState(() {
      _detectedExecutables = executables;
      if (executables.isNotEmpty) {
        final match = executables.firstWhere(
          (e) => e.toLowerCase() == _metadata.appName.toLowerCase(),
          orElse: () => executables.first,
        );
        _executableController.text = match;
        _metadata.executableName = match;
      }
    });
  }

  Future<void> _scanForIcon(String bundlePath) async {
    final dir = Directory(bundlePath);
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.png' || ext == '.svg') {
            final name = p.basename(entity.path).toLowerCase();
            if (name.contains('icon') || name.contains('app')) {
              setState(() {
                _metadata.iconPath = entity.path;
              });
              break;
            }
          }
        }
      }
    } catch (_) {}
  }

  void _startBuild() {
    final l10n = AppLocalizations.of(context)!;
    _metadata.appName = _appNameController.text.trim();
    _metadata.executableName = _executableController.text.trim();
    _metadata.version = _versionController.text.trim();
    _metadata.description = _descriptionController.text.trim();

    if (!_metadata.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final builderService = AppImageBuilderService();
    final buildFuture = builderService.build(_metadata);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BuildConsoleDialog(
        logStream: builderService.logStream,
        buildFuture: buildFuture,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSourceCard(),
                  const SizedBox(height: 20),
                  _buildMetadataCard(),
                  const SizedBox(height: 20),
                  _buildOutputCard(),
                  const SizedBox(height: 28),
                  _buildBuildButton(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  primary.withAlpha(35),
                  secondary.withAlpha(45),
                ]
              : [
                  primary.withAlpha(20),
                  secondary.withAlpha(25),
                ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withAlpha(isDark ? 80 : 120)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary),
              boxShadow: [
                BoxShadow(
                  color: primary.withAlpha(isDark ? 60 : 40),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.all_inclusive, color: primary, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(isDark ? 30 : 25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primary.withAlpha(isDark ? 120 : 180)),
                      ),
                      child: Text(
                        l10n.appVersion,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.appSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // About App Dialog Button
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              tooltip: l10n.aboutTooltip,
              icon: Icon(Icons.info_outline, color: secondary, size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AboutStudioDialog(),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Language Switcher Button
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: PopupMenuButton<Locale?>(
              tooltip: l10n.switchLanguage,
              icon: Icon(Icons.language, color: primary, size: 20),
              onSelected: (loc) {
                widget.onLocaleChanged?.call(loc);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('النظام الافتراضي (System Default)'),
                ),
                const PopupMenuItem(
                  value: Locale('ar'),
                  child: Text('العربية (Arabic)'),
                ),
                const PopupMenuItem(
                  value: Locale('en'),
                  child: Text('English (الإنجليزية)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard() {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppTheme.getPrimary(context);
    final textMuted = AppTheme.getTextMuted(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_zip_outlined, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.sourceCardTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilePickerField(
              label: l10n.bundleDirLabel,
              hint: l10n.bundleDirHint,
              value: _metadata.bundlePath,
              icon: Icons.folder,
              isDirectory: true,
              onChanged: _onBundlePathSelected,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.executableLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _executableController,
                        decoration: InputDecoration(
                          hintText: l10n.executableHint,
                          prefixIcon: Icon(Icons.terminal, size: 18, color: primary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_detectedExecutables.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.autoDetectedExecutables,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _detectedExecutables.contains(_executableController.text)
                              ? _executableController.text
                              : _detectedExecutables.first,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _detectedExecutables.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _executableController.text = val;
                                _metadata.executableName = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppTheme.getPrimary(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.metadataCardTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 1: App Name Full Width
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appNameLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _appNameController,
                  decoration: InputDecoration(
                    hintText: l10n.appNameHint,
                    prefixIcon: Icon(Icons.label_important_outline, size: 18, color: primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: Version and Category
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.versionLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _versionController,
                        decoration: InputDecoration(
                          hintText: l10n.versionHint,
                          prefixIcon: Icon(Icons.tag, size: 18, color: primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.categoryLabel,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AppCategory>(
                        initialValue: _metadata.category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: AppCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.getLocalizedLabel(l10n),
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _metadata.category = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilePickerField(
              label: l10n.iconLabel,
              hint: l10n.iconHint,
              value: _metadata.iconPath ?? '',
              icon: Icons.image_outlined,
              allowedExtensions: const ['png', 'svg', 'jpg', 'jpeg'],
              onChanged: (path) {
                setState(() {
                  _metadata.iconPath = path;
                });
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.descriptionLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: l10n.descriptionHint,
                    prefixIcon: Icon(Icons.description_outlined, size: 18, color: primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final borderColor = AppTheme.getBorder(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.output_outlined, color: primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.outputCardTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilePickerField(
              label: l10n.outputDirLabel,
              hint: l10n.outputDirHint,
              value: _metadata.outputPath,
              icon: Icons.drive_folder_upload,
              isDirectory: true,
              onChanged: (path) {
                setState(() {
                  _metadata.outputPath = path;
                });
              },
            ),
            const SizedBox(height: 16),
            Material(
              color: isDark ? AppTheme.surfaceElevated : AppTheme.lightSurfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CheckboxListTile(
                  value: _metadata.integrateInMenu,
                  activeColor: primary,
                  checkColor: isDark ? Colors.black : Colors.white,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.integrateMenuTitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.integrateMenuSubtitle,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _metadata.integrateInMenu = val ?? false;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildButton() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(context);
    final secondary = AppTheme.getSecondary(context);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [primary, secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(isDark ? 70 : 90),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startBuild,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rocket_launch, color: isDark ? Colors.black87 : Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              l10n.buildButton,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.black87 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.cardBackground.withAlpha(120)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.borderSubtle.withAlpha(100)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          l10n.developedBy,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
