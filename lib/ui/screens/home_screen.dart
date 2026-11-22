import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../core/models/app_metadata.dart';
import '../../core/services/appimage_builder_service.dart';
import '../../core/services/preset_service.dart';
import '../../core/services/project_detector_service.dart';
import '../../core/services/build_script_generator_service.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/file_picker_field.dart';
import '../widgets/build_console_dialog.dart';
import '../widgets/about_studio_dialog.dart';
import '../widgets/live_preview_card.dart';

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
  bool _isDragging = false;
  DateTime _lastDropProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const MethodChannel _nativeDropChannel = MethodChannel('appimage_studio/native_drop');

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

    // Native GTK3 drag-and-drop channel
    _nativeDropChannel.setMethodCallHandler(_handleNativeDropCall);

    // Attach listeners so LivePreviewCard updates live as the user types
    _appNameController.addListener(() {
      if (_metadata.appName != _appNameController.text) {
        setState(() => _metadata.appName = _appNameController.text);
      }
    });
    _executableController.addListener(() {
      if (_metadata.executableName != _executableController.text) {
        setState(() => _metadata.executableName = _executableController.text);
      }
    });
    _versionController.addListener(() {
      if (_metadata.version != _versionController.text) {
        setState(() => _metadata.version = _versionController.text);
      }
    });
    _descriptionController.addListener(() {
      if (_metadata.description != _descriptionController.text) {
        setState(() => _metadata.description = _descriptionController.text);
      }
    });
  }

  @override
  void dispose() {
    _nativeDropChannel.setMethodCallHandler(null);
    _appNameController.dispose();
    _executableController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncMetadataFromControllers() {
    _metadata.appName = _appNameController.text.trim();
    _metadata.executableName = _executableController.text.trim();
    _metadata.version = _versionController.text.trim();
    _metadata.description = _descriptionController.text.trim();
  }

  Future<void> _applyLoadedPreset(AppMetadata preset) async {
    setState(() {
      _metadata.appName = preset.appName;
      _metadata.executableName = preset.executableName;
      _metadata.version = preset.version;
      _metadata.description = preset.description;
      _metadata.category = preset.category;
      _metadata.bundlePath = preset.bundlePath;
      _metadata.iconPath = preset.iconPath;
      if (preset.outputPath.isNotEmpty) {
        _metadata.outputPath = preset.outputPath;
      }
      _metadata.integrateInMenu = preset.integrateInMenu;

      _appNameController.text = preset.appName;
      _executableController.text = preset.executableName;
      _versionController.text = preset.version;
      _descriptionController.text = preset.description;
    });

    await _scanForExecutables(preset.bundlePath);
    if (preset.executableName.isNotEmpty) {
      setState(() {
        _executableController.text = preset.executableName;
        _metadata.executableName = preset.executableName;
      });
    }

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              Text(l10n.presetLoaded),
            ],
          ),
          backgroundColor: const Color(0xFF161E2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _sanitizePath(String raw) {
    String clean = raw.trim();
    if (clean.isEmpty || clean.startsWith('#')) return '';
    if (clean.startsWith('file://')) {
      try {
        clean = Uri.parse(clean).toFilePath();
      } catch (_) {
        clean = clean.replaceFirst('file://', '');
      }
    }
    try {
      if (clean.contains('%')) {
        clean = Uri.decodeFull(clean);
      }
    } catch (_) {}
    if (clean.length > 1 && clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  Future<dynamic> _handleNativeDropCall(MethodCall call) async {
    switch (call.method) {
      case 'dragEntered':
        if (!_isDragging && mounted) {
          setState(() => _isDragging = true);
        }
        break;
      case 'dragExited':
        if (_isDragging && mounted) {
          setState(() => _isDragging = false);
        }
        break;
      case 'dragDropped':
        if (_isDragging && mounted) {
          setState(() => _isDragging = false);
        }
        final List<dynamic> args = (call.arguments as List<dynamic>?) ?? const [];
        final rawStrings = args.map((e) => e.toString()).toList();
        await _processDroppedPayload(rawStrings);
        break;
    }
  }

  Future<void> _processDroppedPayload(List<String> rawInputs) async {
    final now = DateTime.now();
    if (now.difference(_lastDropProcessedTime).inMilliseconds < 400) {
      return; // Deduplicate between native channel, raw listener and DropTarget callback
    }
    _lastDropProcessedTime = now;

    final expandedLines = <String>[];
    for (final input in rawInputs) {
      for (final line in input.split(RegExp(r'[\r\n]+'))) {
        if (line.trim().isNotEmpty) {
          expandedLines.add(line.trim());
        }
      }
    }

    final sanitizedPaths = expandedLines
        .map(_sanitizePath)
        .where((path) => path.isNotEmpty && (Directory(path).existsSync() || File(path).existsSync()))
        .toSet()
        .toList();
    if (sanitizedPaths.isEmpty) return;

    final directories = sanitizedPaths.where((path) => Directory(path).existsSync()).toList();
    final files = sanitizedPaths.where((path) => File(path).existsSync()).toList();

    // Case 1: Multiple items dropped (e.g. user opened the bundle folder, selected all contents "ما بدخله"
    // such as [executable, data/, lib/], and dropped them together).
    if (sanitizedPaths.length > 1) {
      final parentDir = p.dirname(sanitizedPaths.first);
      if (Directory(parentDir).existsSync()) {
        await _onBundlePathSelected(parentDir);

        final imageFiles = files.where((f) {
          final ext = p.extension(f).toLowerCase();
          return ['.png', '.svg', '.jpg', '.jpeg'].contains(ext);
        }).toList();

        if (imageFiles.isNotEmpty) {
          setState(() {
            _metadata.iconPath = imageFiles.first;
          });
        }

        for (final file in files) {
          if (await _isExecutableCandidate(File(file))) {
            final filename = p.basename(file);
            setState(() {
              _executableController.text = filename;
              _metadata.executableName = filename;
            });
            break;
          }
        }
        _showDropSuccessFeedback(p.basename(parentDir));
        return;
      }
    }

    // Case 2: A single directory was dropped ("المجلد كاملاً")
    if (directories.length == 1 && files.isEmpty) {
      String targetDir = directories.first;
      final base = p.basename(targetDir).toLowerCase();
      // If user accidentally dropped a 'data' or 'lib' subfolder of a bundle, step up to the bundle parent
      if ((base == 'data' || base == 'lib') && Directory(p.dirname(targetDir)).existsSync()) {
        final parent = p.dirname(targetDir);
        final parentHasExec = await _directoryHasExecutable(parent);
        if (parentHasExec) {
          targetDir = parent;
        }
      }
      await _onBundlePathSelected(targetDir);
      _showDropSuccessFeedback(p.basename(targetDir));
      return;
    }

    // Case 3: A single file was dropped
    if (files.isEmpty) return;
    final singleFile = files.first;
    final fileName = p.basename(singleFile);
    final ext = p.extension(singleFile).toLowerCase();

    // Case 3A: Preset YAML file
    if (fileName == 'appimage_studio.yaml' || ext == '.yaml' || ext == '.yml') {
      final preset = await PresetService.loadPreset(p.dirname(singleFile));
      if (preset != null) {
        await _applyLoadedPreset(preset);
        _showDropSuccessFeedback(fileName);
        return;
      }
    }

    // Case 3B: Image icon file
    if (['.png', '.svg', '.jpg', '.jpeg'].contains(ext)) {
      setState(() {
        _metadata.iconPath = singleFile;
      });
      _showDropSuccessFeedback(fileName);
      return;
    }

    // Case 3C: Single executable or bundle file dropped from inside the folder
    final parentDir = p.dirname(singleFile);
    if (Directory(parentDir).existsSync()) {
      await _onBundlePathSelected(parentDir);
      if (await _isExecutableCandidate(File(singleFile))) {
        setState(() {
          _executableController.text = fileName;
          _metadata.executableName = fileName;
        });
      }
      _showDropSuccessFeedback(p.basename(parentDir));
    }
  }

  Future<bool> _directoryHasExecutable(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return false;
    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File && await _isExecutableCandidate(entity)) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  void _showDropSuccessFeedback(String name) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = l10n != null ? l10n.dragDropSuccess(name) : 'Loaded $name';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF161E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _isExecutableCandidate(File file) async {
    final ext = p.extension(file.path).toLowerCase();
    const nonExecExts = {
      '.png', '.svg', '.jpg', '.jpeg', '.gif', '.ico',
      '.desktop', '.md', '.yaml', '.yml', '.xml', '.html',
      '.so', '.a', '.dylib', '.dll', '.json', '.txt', '.log',
      '.css', '.js', '.ts', '.map', '.c', '.cpp', '.h', '.dart'
    };
    if (nonExecExts.contains(ext)) return false;

    try {
      final stat = await file.stat();
      if (stat.mode & 0x49 != 0) return true;

      // Check ELF magic bytes (0x7F 'E' 'L' 'F') or Shebang ('#' '!')
      final raf = await file.open(mode: FileMode.read);
      try {
        final header = await raf.read(4);
        if (header.length >= 4 &&
            header[0] == 0x7F &&
            header[1] == 0x45 &&
            header[2] == 0x4C &&
            header[3] == 0x46) {
          return true;
        }
        if (header.length >= 2 && header[0] == 0x23 && header[1] == 0x21) {
          return true;
        }
      } finally {
        await raf.close();
      }
    } catch (_) {}
    return false;
  }

  Future<void> _onBundlePathSelected(String path) async {
    // 1. Run smart project detector
    final detection = await ProjectDetectorService.detect(path);

    if (detection.loadedPreset != null) {
      await _applyLoadedPreset(detection.loadedPreset!);
      return;
    }

    final effectiveBundlePath = detection.bundlePath ?? path;
    const genericDirNames = {
      'bundle', 'release', 'debug', 'x64', 'arm64', 'linux', 'build', 'dist', 'desktop', 'appdir'
    };

    setState(() {
      _metadata.bundlePath = effectiveBundlePath;

      if (detection.appName != null && detection.appName!.isNotEmpty) {
        _appNameController.text = detection.appName!;
        _metadata.appName = detection.appName!;
      } else {
        final dirName = p.basename(effectiveBundlePath);
        final candidateName = genericDirNames.contains(dirName.toLowerCase())
            ? p.basename(p.dirname(effectiveBundlePath))
            : dirName;
        _appNameController.text = candidateName;
        _metadata.appName = candidateName;
      }

      if (detection.executableName != null && detection.executableName!.isNotEmpty) {
        _executableController.text = detection.executableName!;
        _metadata.executableName = detection.executableName!;
      } else {
        _executableController.clear();
        _metadata.executableName = '';
      }

      if (detection.version != null && detection.version!.isNotEmpty) {
        _versionController.text = detection.version!;
        _metadata.version = detection.version!;
      } else if (_versionController.text.trim().isEmpty) {
        _versionController.text = '1.0.0';
        _metadata.version = '1.0.0';
      }

      if (detection.description != null && detection.description!.isNotEmpty) {
        _descriptionController.text = detection.description!;
        _metadata.description = detection.description!;
      }

      if (detection.category != null) {
        _metadata.category = detection.category!;
      }

      _metadata.iconPath = detection.iconPath;
    });

    // Sequentially scan for executables and icons to prevent async overwrite races
    await _scanForExecutables(effectiveBundlePath);
    if (_metadata.iconPath == null) {
      await _scanForIcon(effectiveBundlePath);
    }

    // If appName is still a generic directory name (e.g., 'bundle', 'release', 'Desktop')
    // and an executable was found, derive a clean human-readable appName from the executable!
    if (genericDirNames.contains(_metadata.appName.toLowerCase()) &&
        _metadata.executableName.isNotEmpty) {
      final formatted = _metadata.executableName
          .split(RegExp(r'[-_.]'))
          .where((s) => s.isNotEmpty)
          .map((s) => s[0].toUpperCase() + s.substring(1))
          .join(' ');
      if (formatted.isNotEmpty && mounted) {
        setState(() {
          _appNameController.text = formatted;
          _metadata.appName = formatted;
        });
      }
    }

    if (mounted && detection.type != DetectedProjectType.generic) {
      final l10n = AppLocalizations.of(context)!;
      final message = detection.type == DetectedProjectType.preset
          ? l10n.presetLoaded
          : l10n.projectDetectedNotification(detection.frameworkName ?? detection.type.name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.primaryCyan, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF161E2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.primaryCyan),
          ),
        ),
      );
    }
  }

  Future<void> _scanForExecutables(String bundlePath) async {
    final dir = Directory(bundlePath);
    if (!await dir.exists()) return;
    final executables = <String>[];

    try {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          if (await _isExecutableCandidate(entity)) {
            executables.add(p.basename(entity.path));
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _detectedExecutables = executables;
      if (executables.isNotEmpty) {
        final normalizedApp = _metadata.appName.toLowerCase().replaceAll(' ', '_');
        final match = executables.firstWhere(
          (e) =>
              e.toLowerCase() == _metadata.appName.toLowerCase() ||
              e.toLowerCase() == normalizedApp,
          orElse: () => executables.first,
        );
        _executableController.text = match;
        _metadata.executableName = match;
      }
    });
  }

  Future<void> _scanForIcon(String bundlePath) async {
    final dir = Directory(bundlePath);
    if (!await dir.exists()) return;
    String? fallbackImage;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.png' || ext == '.svg') {
            final name = p.basename(entity.path).toLowerCase();
            if (name.contains('icon') || name.contains('app') || name.contains('logo')) {
              if (mounted) {
                setState(() {
                  _metadata.iconPath = entity.path;
                });
              }
              return;
            }
            fallbackImage ??= entity.path;
          }
        }
      }
      if (fallbackImage != null && mounted) {
        setState(() {
          _metadata.iconPath = fallbackImage;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreset() async {
    final l10n = AppLocalizations.of(context)!;
    if (_metadata.bundlePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _syncMetadataFromControllers();
    final targetDir = Directory(_metadata.bundlePath).existsSync() ? _metadata.bundlePath : Directory.current.path;
    await PresetService.savePreset(targetDir, _metadata);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              Text(l10n.savePresetSuccess),
            ],
          ),
          backgroundColor: const Color(0xFF161E2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportBuildScript() async {
    final l10n = AppLocalizations.of(context)!;
    _syncMetadataFromControllers();
    if (!_metadata.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final targetDir = Directory(_metadata.bundlePath).existsSync() ? _metadata.bundlePath : Directory.current.path;
    final scriptFile = await BuildScriptGeneratorService.generateScript(
      targetDirectory: targetDir,
      metadata: _metadata,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.terminal, color: AppTheme.primaryCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${l10n.exportBuildScriptSuccess} (${p.basename(scriptFile.path)})')),
            ],
          ),
          backgroundColor: const Color(0xFF161E2E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startBuild() {
    final l10n = AppLocalizations.of(context)!;
    _syncMetadataFromControllers();

    if (!_metadata.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.validationError),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final builderService = AppImageBuilderService();
    final buildFuture = builderService.build(_metadata, isArabic: isArabic);

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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      const SizedBox(height: 20),
                      LivePreviewCard(metadata: _metadata),
                      const SizedBox(height: 24),
                      _buildActionButtonsRow(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildDragOverlay(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: const Color(0xDD0D1117),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          width: double.infinity,
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E).withAlpha(220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryCyan, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCyan.withAlpha(80),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.file_download_outlined,
                  size: 64,
                  color: AppTheme.primaryCyan,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.dragAndDropPrompt,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dragAndDropSubtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
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
                          key: ValueKey('exec_dd_${_executableController.text}'),
                          initialValue: _detectedExecutables.contains(_executableController.text)
                              ? _executableController.text
                              : (_detectedExecutables.isNotEmpty ? _detectedExecutables.first : null),
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
                // Save Preset Button
                OutlinedButton.icon(
                  onPressed: _metadata.bundlePath.isNotEmpty ? _savePreset : null,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 15),
                  label: Text(l10n.savePresetButton, style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildActionButtonsRow() {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppTheme.getPrimary(context);

    return Column(
      children: [
        _buildBuildButton(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _metadata.isValid ? _exportBuildScript : null,
              icon: Icon(Icons.terminal_rounded, size: 16, color: primary),
              label: Text(
                l10n.exportBuildScriptButton,
                style: TextStyle(fontSize: 13, color: primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary.withAlpha(120)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
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
