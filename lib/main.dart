import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Text Extractor',
      home: MyHomePage(),
    );
  }
}

Future<String> extractTextFromImage(XFile file) async {
  final inputImage = InputImage.fromFilePath(file.path);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  } finally {
    await textRecognizer.close();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  String? _extractedText;
  bool _isExtracting = false;
  String? _errorMessage;

  Future<void> _pickAndExtract(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null) return;

      setState(() {
        _pickedFile = file;
        _extractedText = null;
        _errorMessage = null;
        _isExtracting = true;
      });

      final text = await extractTextFromImage(file);

      setState(() {
        _extractedText = text.isEmpty ? 'Aucun texte détecté.' : text;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isExtracting = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_extractedText == null) return;
    Clipboard.setData(ClipboardData(text: _extractedText!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extraction de texte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _pickedFile == null
                    ? const Center(child: Text('Aucune image sélectionnée'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_pickedFile!.path), fit: BoxFit.contain),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndExtract(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickAndExtract(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isExtracting)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red))
              else if (_extractedText != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Texte extrait', style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copier',
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(_extractedText!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}