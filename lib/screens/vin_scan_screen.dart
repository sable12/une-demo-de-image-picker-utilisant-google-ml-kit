import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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

class VinScanScreen extends StatefulWidget {
  const VinScanScreen({super.key});

  @override
  State<VinScanScreen> createState() => _VinScanScreenState();
}

class _VinScanScreenState extends State<VinScanScreen> {
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
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isExtracting = false;
      });
    }
  }

  void _copyVin() {
    if (_detectedVin == null) return;
    Clipboard.setData(ClipboardData(text: _detectedVin!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('VIN copié')),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _manualVinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.background,
        elevation: 0,
        title: const Text(
          'Scanner VIN',
          style: TextStyle(
            color: _AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
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
              if (_isExtracting) _buildLoadingCard(),
              if (_errorMessage != null) _buildErrorCard(),
              if (!_isExtracting && _detectedVin != null) _buildVinCard(),
              if (!_isExtracting && _detectedVin == null && _rawText != null)
                _buildNoVinCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
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
                  const Icon(Icons.directions_car_filled_outlined,
                      color: _AppColors.textSecondary, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Photographiez la plaque VIN',
                    style: TextStyle(color: _AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover, width: double.infinity),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'Caméra',
            onTap: () => _pickAndExtract(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_outlined,
            label: 'Galerie',
            onTap: () => _pickAndExtract(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _AppColors.accent),
          ),
          SizedBox(width: 10),
          Text('Lecture du VIN...', style: TextStyle(color: _AppColors.textSecondary)),
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
      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildNoVinCard() {
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
          const Text(
            'Aucun VIN valide détecté (17 caractères attendus). Réessayez avec un cadrage plus net, ou corrigez manuellement ci-dessous.',
            style: TextStyle(color: _AppColors.textSecondary),
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
              hintText: 'Saisir le VIN manuellement (17 caractères)',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('VIN copié')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: _AppColors.accent),
                  label: const Text('Copier', style: TextStyle(color: _AppColors.accent)),
                ),
              ),
            ),
          if (_rawText != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Texte brut lu par l\'OCR (debug) :',
              style: TextStyle(color: _AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            SelectableText(
              _rawText!,
              style: const TextStyle(color: _AppColors.textPrimary, fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVinCard() {
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
              const Icon(Icons.verified_outlined, color: _AppColors.accent, size: 18),
              const SizedBox(width: 6),
              const Text(
                'VIN DÉTECTÉ',
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
                icon: const Icon(Icons.copy, color: _AppColors.textSecondary, size: 18),
                tooltip: 'Copier',
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
  const _ActionButton({required this.icon, required this.label, required this.onTap});

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
              Text(label, style: const TextStyle(color: _AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}