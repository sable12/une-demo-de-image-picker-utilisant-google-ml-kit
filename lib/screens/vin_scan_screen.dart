import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_text/l10n/app_localizations.dart';

import '../providers/language_provider.dart';
import '../services/ocr_service.dart';
import '../utils/vin_utils.dart';

// Palette "tableau de bord" générique — sombre, technique, accent électrique.
class _AppColors {
  static const background = Color(0xFF121417);
  static const surface = Color(0xFF1D2126);
  static const border = Color(0xFF2A2F36);
  static const accent = Color(0xFF3DDC84); // vert "statut OK" façon dashboard
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9AA3AE);
}

class VinScanScreen extends ConsumerStatefulWidget {
  const VinScanScreen({super.key});

  @override
  ConsumerState<VinScanScreen> createState() => _VinScanScreenState();
}

class _VinScanScreenState extends ConsumerState<VinScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  XFile? _pickedFile;
  String? _rawText;
  String? _detectedVin;
  bool _isExtracting = false;
  String? _errorMessage;

  final TextEditingController _manualVinController = TextEditingController();
  String? _manualVin;

  Future<void> _pickAndExtract(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      setState(() {
        _pickedFile = file;
        _rawText = null;
        _detectedVin = null;
        _errorMessage = null;
        _isExtracting = true;
        _manualVin = null;
        _manualVinController.clear();
      });

      final text = await _ocrService.extractText(file);
      final vin = VinUtils.extractVin(text);

      setState(() {
        _rawText = text.isEmpty ? null : text;
        _detectedVin = vin;
        _isExtracting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${l10n.errorPrefix}: $e';
        _isExtracting = false;
      });
    }
  }

  void _copyVin() {
    final l10n = AppLocalizations.of(context)!;
    if (_detectedVin == null) return;
    Clipboard.setData(ClipboardData(text: _detectedVin!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.vinCopied)));
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _manualVinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.background,
        elevation: 0,
        title: Text(
          l10n.scanVinTitle,
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: locale.languageCode,
            icon: const Icon(Icons.language, color: _AppColors.textPrimary),
            tooltip: l10n.language,
            onSelected: (code) =>
                ref.read(appLanguageProvider.notifier).setLocaleByCode(code),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'en', child: Text(l10n.english)),
              PopupMenuItem(value: 'fr', child: Text(l10n.french)),
              PopupMenuItem(value: 'es', child: Text(l10n.spanish)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 24),
              if (_isExtracting) _buildLoadingCard(l10n),
              if (_errorMessage != null) _buildErrorCard(),
              if (!_isExtracting && _detectedVin != null) _buildVinCard(l10n),
              if (!_isExtracting && _detectedVin == null && _rawText != null)
                _buildNoVinCard(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border),
      ),
      child: _pickedFile == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car_filled_outlined,
                    color: _AppColors.textSecondary,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.takeVinPhoto,
                    style: TextStyle(color: _AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_pickedFile!.path),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_outlined,
            label: l10n.camera,
            onTap: () => _pickAndExtract(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_outlined,
            label: l10n.gallery,
            onTap: () => _pickAndExtract(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.readingVin,
            style: const TextStyle(color: _AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildNoVinCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.noValidVinDetected,
            style: const TextStyle(color: _AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _manualVinController,
            style: const TextStyle(
              color: _AppColors.textPrimary,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 17,
            decoration: InputDecoration(
              hintText: l10n.manualVinHint,
              hintStyle: const TextStyle(color: _AppColors.textSecondary),
              counterStyle: const TextStyle(color: _AppColors.textSecondary),
              filled: true,
              fillColor: _AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _AppColors.border),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _manualVin = value.toUpperCase().trim();
              });
            },
          ),
          if (_manualVin != null && _manualVin!.length == 17)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _manualVin!));
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.vinCopied)));
                  },
                  icon: const Icon(
                    Icons.copy,
                    size: 16,
                    color: _AppColors.accent,
                  ),
                  label: Text(
                    l10n.copy,
                    style: const TextStyle(color: _AppColors.accent),
                  ),
                ),
              ),
            ),
          if (_rawText != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.ocrRawTextDebug,
              style: const TextStyle(
                color: _AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              _rawText!,
              style: const TextStyle(
                color: _AppColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVinCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: _AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.vinDetected,
                style: TextStyle(
                  color: _AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _copyVin,
                icon: const Icon(
                  Icons.copy,
                  color: _AppColors.textSecondary,
                  size: 18,
                ),
                tooltip: l10n.copy,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            _detectedVin!,
            style: const TextStyle(
              color: _AppColors.textPrimary,
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: _AppColors.accent, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
