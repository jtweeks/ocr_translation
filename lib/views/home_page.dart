import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:ocr_translation/models/translation_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ... (Keep existing keys and camera variables)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const Key appBarKey = ValueKey('homePageAppBar');
  static const Key addPhotoButtonKey = ValueKey('addPhotoButton');
  static const Key cameraPreviewWidgetKey = ValueKey('cameraPreviewWidget');
  static const Key translationsListKey = ValueKey('translationsListView');
  static const Key originalTextFieldKey = ValueKey('originalTextField');
  static const Key translatedTextFieldKey = ValueKey('translatedTextField');
  static const Key captureTranslationButtonKey = ValueKey('captureTranslationButton');

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showCamera = false;

  List<TranslationModel> _translations = [];

  final TextEditingController _originalTextController = TextEditingController();
  final TextEditingController _translatedTextController = TextEditingController();

  // --- ML Kit On-Device Translation ---
  OnDeviceTranslator? _onDeviceTranslator;
  TranslateLanguage _sourceLanguage = TranslateLanguage.spanish; // Default, can be auto-detected or set
  TranslateLanguage _targetLanguage = TranslateLanguage.english; // Example: translate to Spanish
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  bool _isSourceModelDownloaded = false;
  bool _isTargetModelDownloaded = false;
  // --- End ML Kit ---

  Timer? _debounce;
  bool _isTranslating = false;


  @override
  void initState() {
    super.initState();
    // _initializeCamera();
    _loadTranslations();
    _originalTextController.addListener(_onOriginalTextChanged);

    // Initialize ML Kit Translator
    _initializeTranslator();
  }

  Future<void> _initializeTranslator() async {
    await _checkAndDownloadModels();

    if (_isSourceModelDownloaded && _isTargetModelDownloaded) {
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
    } else {
      print("Translation models not ready. Please connect to the internet to download them.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Translation models need to be downloaded. Check internet connection.')),
        );
      }
    }
  }

  Future<void> _checkAndDownloadModels() async {
    // Check and download source language model (e.g., English)
    // For auto-detection, you might skip explicit source model download if you're confident
    // in the languages you'll be translating from or if you handle detection separately.
    // However, if you set a specific source, ensure it's downloaded.
    _isSourceModelDownloaded = await _modelManager.isModelDownloaded(_sourceLanguage.bcpCode);
    if (!_isSourceModelDownloaded) {
      print('Downloading source model: ${_sourceLanguage.bcpCode}');
      final bool downloaded = await _modelManager.downloadModel(_sourceLanguage.bcpCode, isWifiRequired: false);
      _isSourceModelDownloaded = downloaded;
      print('Source model ${_sourceLanguage.bcpCode} downloaded: $_isSourceModelDownloaded');
    }


    _isTargetModelDownloaded = await _modelManager.isModelDownloaded(_targetLanguage.bcpCode);
    if (!_isTargetModelDownloaded) {
      print('Downloading target model: ${_targetLanguage.bcpCode}');
      // isWifiRequired: false - allows download over mobile data. Set true to enforce Wi-Fi.
      final bool downloaded = await _modelManager.downloadModel(_targetLanguage.bcpCode, isWifiRequired: false);
      _isTargetModelDownloaded = downloaded;
      print('Target model ${_targetLanguage.bcpCode} downloaded: $_isTargetModelDownloaded');
    }

    // After attempting downloads, re-instantiate the translator if models are now ready
    if (_isSourceModelDownloaded && _isTargetModelDownloaded && _onDeviceTranslator == null) {
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
      print("OnDeviceTranslator initialized after model download.");
      _initializeCamera();
    }
    setState(() {}); // Update UI if model status changed
  }


  Future<void> _initializeCamera() async {
    // ... (same as before)
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available on this device.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  void _loadTranslations() {
    // ... (same as before)
    setState(() {
      _translations = TranslationModel.getTranslations();
    });
  }

  void _onOriginalTextChanged() {
    print("onTextChanged");
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final textToTranslate = _originalTextController.text;

      if (!_showCamera || textToTranslate.length < 3) {
        if (textToTranslate.isEmpty && _showCamera) _translatedTextController.clear();
        setState(() { _isTranslating = false;});
        return;
      }

      if (_onDeviceTranslator == null || !_isSourceModelDownloaded || !_isTargetModelDownloaded) {
        _translatedTextController.text = "Models not ready";
        setState(() { _isTranslating = false; });
        // Optionally, try to re-download or prompt user
        await _checkAndDownloadModels(); // Attempt to re-check/download
        return;
      }

      setState(() {
        _isTranslating = true;
        _translatedTextController.text = "Translating (on-device)...";
      });

      try {
        final String? translatedText = await _onDeviceTranslator!.translateText(textToTranslate);
        if (mounted) {
          _translatedTextController.text = translatedText ?? 'Error translating';
        }
      } catch (e) {
        if (mounted) {
          _translatedTextController.text = 'Error: ${e.toString().substring(0,min(e.toString().length, 50))}'; // Show a snippet of the error
        }
        print("ML Kit Translation error: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isTranslating = false;
          });
        }
      }
    });
  }

  void _toggleCameraView() {
    // ... (same as before, ensure _isTranslating and debounce are handled)
    setState(() {
      _showCamera = !_showCamera;
      if (!_showCamera) {
        _cameraController?.dispose();
        _originalTextController.clear();
        _translatedTextController.clear();
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _isTranslating = false;
      } else {
        // When camera view opens, if there's text in original, trigger translation
        // Also ensure models are checked/ready
        _checkAndDownloadModels().then((_) { // Ensure models are checked before potential translation
          print("models are downloaded");
          _initializeCamera();
          print("camera initialized");
          if (_originalTextController.text.length >=3) {
            _onOriginalTextChanged();
          }
        });
      }
    });
  }

  void _captureAndAddTranslation() {
    // ... (same as before, but use _targetLanguage.bcpCode for languageCode)
    final String originalText = _originalTextController.text;
    final String translatedText = _translatedTextController.text;

    if (originalText.isNotEmpty && translatedText.isNotEmpty &&
        !_isTranslating && // Ensure not currently translating
        !translatedText.startsWith("Translating") &&
        !translatedText.startsWith("Models not ready") &&
        !translatedText.startsWith("Error:")) {
      final newTranslation = TranslationModel(
        originalText: originalText,
        translatedText: translatedText,
        languageCode: _targetLanguage.bcpCode, // Use BCP-47 code from ML Kit
        dateAndTime: DateTime.now(),
      );

      setState(() {
        _translations.insert(0, newTranslation);
        _showCamera = false;
        _originalTextController.clear();
        _translatedTextController.clear();
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation Captured!')),
      );
    } else if (_isTranslating || translatedText.startsWith("Translating")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for translation to complete.')),
      );
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter text and ensure it is translated correctly.')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _originalTextController.removeListener(_onOriginalTextChanged);
    _originalTextController.dispose();
    _translatedTextController.dispose();
    _debounce?.cancel();
    _onDeviceTranslator?.close(); // Close the translator
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Scaffold and AppBar are the same)
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        key: appBarKey,
        title: Text('(${_sourceLanguage.name} -> ${_targetLanguage.name})'), // Show current langs
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          // Optional: Add a button to manually check/download models
          IconButton(
            icon: Icon(Icons.download_for_offline,
                color: (_isSourceModelDownloaded && _isTargetModelDownloaded) ? Colors.green : Colors.grey),
            onPressed: _checkAndDownloadModels,
            tooltip: "Check/Download Translation Models",
          ),
          IconButton(
            key: addPhotoButtonKey,
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () {
              if (_isCameraInitialized) {
                _toggleCameraView();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera not ready yet.')),
                );
              }
            },
          ),
        ],
      ),
      body: _showCamera && _isCameraInitialized && _cameraController != null
          ? _buildCameraLayout()
          : _buildTranslationsView(),
    );
  }

  Widget _buildCameraLayout() {
    // ... (CameraPreview part is mostly the same)
    if (!_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final screenAspectRatio = MediaQuery.of(context).size.aspectRatio;
    final previewAspectRatio = 0.66;

    String translatedHintText = 'Translation appears here...';
    if (_isTranslating) {
      translatedHintText = 'Translating (on-device)...';
    } else if (!(_isSourceModelDownloaded && _isTargetModelDownloaded)) {
      translatedHintText = 'Models not ready. Tap download icon in AppBar.';
    }


    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0)
            ),
            child: AspectRatio(
              aspectRatio: previewAspectRatio,
              child: CameraPreview(
                _cameraController!,
                key: cameraPreviewWidgetKey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              key: originalTextFieldKey,
              controller: _originalTextController,
              decoration: const InputDecoration(
                labelText: 'Original Text (min. 3 chars to translate)',
                hintText: 'Type or paste text here...',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              key: translatedTextFieldKey,
              controller: _translatedTextController,
              decoration: InputDecoration(
                labelText: 'Translated Text (to ${_targetLanguage.name})', // Show language name
                hintText: translatedHintText,
                border: InputBorder.none,
                suffixIcon: _isTranslating
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : null,
              ),
              readOnly: true,
              maxLines: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            key: captureTranslationButtonKey,
            onPressed: (_isSourceModelDownloaded && _isTargetModelDownloaded) // Enable only if models are ready
                ? _captureAndAddTranslation
                : null, // Disable button if models aren't ready
            child: const Text('Capture Translation'),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationsView() {
    // ... (This widget remains the same, displaying the list of captured translations)
    if (_translations.isEmpty) {
      return const Center(
        child: Text(
          'No translations yet. Capture some using the camera icon!',
          key: ValueKey('noTranslationsText'),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return ListView.builder(
        key: translationsListKey,
        itemCount: _translations.length,
        itemBuilder: (context, index) {
          final TranslationModel translation = _translations[index];
          return ListTile(
            key: ValueKey('translation_item_${translation.originalText}_${translation.dateAndTime.millisecondsSinceEpoch}'),
            title: Text(translation.originalText),
            subtitle: Text('${translation.translatedText} (${translation.languageCode.toUpperCase()})'),
            trailing: Text(
              '${translation.dateAndTime.day}/${translation.dateAndTime.month}/${translation.dateAndTime.year}',
            ),
          );
        },
      );
    }
  }
}