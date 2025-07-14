import 'dart:async';
import 'dart:io'; // For Platform.isAndroid/isIOS if needed for rotation
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:camera/camera.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// Import ML Kit Text Recognition
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_translation/models/translation_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ... (Keep existing keys, controllers, and translation variables)
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

  OnDeviceTranslator? _onDeviceTranslator;
  TranslateLanguage _sourceLanguage = TranslateLanguage.spanish;
  TranslateLanguage _targetLanguage = TranslateLanguage.english;
  final OnDeviceTranslatorModelManager _translationModelManager = OnDeviceTranslatorModelManager();
  bool _isSourceModelDownloaded = false;
  bool _isTargetModelDownloaded = false;

  Timer? _debounceTranslation;
  bool _isTranslating = false;

  // --- ML Kit Text Recognition ---
  TextRecognizer? _textRecognizer;
  bool _isTextRecognizerBusy = false; // To prevent processing multiple frames simultaneously
  // --- End ML Kit Text Recognition ---


  @override
  void initState() {
    super.initState();
    _initializeCameraAndDependencies(); // Combined initialization
    _loadTranslations();
    _originalTextController.addListener(_onOriginalTextChangedForTranslation); // Renamed for clarity
  }

  Future<void> _initializeCameraAndDependencies() async {
    // Initialize Camera
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high, // Good for text recognition
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid // Setting specific format for MLKit
              ? ImageFormatGroup.nv21 // NV21 works well for ML Kit on Android
              : ImageFormatGroup.bgra8888, // BGRA8888 for iOS
        );
        await _cameraController!.initialize();
        if (!mounted) return;

        // Start image stream for text recognition if camera is shown
        if (_showCamera) {
          _cameraController!.startImageStream(_processCameraImage);
        }

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        _showErrorSnackbar('No cameras available on this device.');
      }
    } catch (e) {
      _showErrorSnackbar('Error initializing camera: $e');
      print("Camera Initialization Error: $e");
    }

    // Initialize ML Kit Text Recognizer
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin); // Default to Latin script

    // Initialize ML Kit Translator (as before)
    _initializeTranslator();
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }


  Future<void> _initializeTranslator() async {
    // ... (Keep existing _initializeTranslator and _checkAndDownloadModels logic)
    await _checkAndDownloadModels();
    if (_isSourceModelDownloaded && _isTargetModelDownloaded) {
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
    } else {
      print("Translation models not ready.");
      // SnackBar shown in _checkAndDownloadModels if needed
    }
  }

  Future<void> _checkAndDownloadModels() async {
    // ... (Keep existing _checkAndDownloadModels logic)
    _isSourceModelDownloaded = await _translationModelManager.isModelDownloaded(_sourceLanguage.bcpCode);
    if (!_isSourceModelDownloaded) {
      print('Downloading source model: ${_sourceLanguage.bcpCode}');
      final bool downloaded = await _translationModelManager.downloadModel(_sourceLanguage.bcpCode, isWifiRequired: false);
      _isSourceModelDownloaded = downloaded;
      print('Source model ${_sourceLanguage.bcpCode} downloaded: $_isSourceModelDownloaded');
    }

    _isTargetModelDownloaded = await _translationModelManager.isModelDownloaded(_targetLanguage.bcpCode);
    if (!_isTargetModelDownloaded) {
      print('Downloading target model: ${_targetLanguage.bcpCode}');
      final bool downloaded = await _translationModelManager.downloadModel(_targetLanguage.bcpCode, isWifiRequired: false);
      _isTargetModelDownloaded = downloaded;
      print('Target model ${_targetLanguage.bcpCode} downloaded: $_isTargetModelDownloaded');
    }

    if (_isSourceModelDownloaded && _isTargetModelDownloaded && _onDeviceTranslator == null) {
      _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage,
        targetLanguage: _targetLanguage,
      );
      print("OnDeviceTranslator initialized after model download.");
    }
    if (mounted) setState(() {});
  }

  void _loadTranslations() {
    setState(() {
      _translations = TranslationModel.getTranslations();
    });
  }

  // This function is now specifically for triggering TRANSLATION
  void _onOriginalTextChangedForTranslation() {
    if (_debounceTranslation?.isActive ?? false) _debounceTranslation!.cancel();
    _debounceTranslation = Timer(const Duration(milliseconds: 700), () async {
      final textToTranslate = _originalTextController.text;

      if (!_showCamera || textToTranslate.length < 3) {
        if (textToTranslate.isEmpty && _showCamera) _translatedTextController.clear();
        if(mounted) setState(() { _isTranslating = false;});
        return;
      }
      // ... (rest of the translation logic remains the same)
      if (_onDeviceTranslator == null || !_isSourceModelDownloaded || !_isTargetModelDownloaded) {
        _translatedTextController.text = "Models not ready";
        if(mounted) setState(() { _isTranslating = false; });
        await _checkAndDownloadModels();
        return;
      }

      if(mounted) setState(() {
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
          _translatedTextController.text = 'Error: ${e.toString().substring(0,min(e.toString().length, 50))}';
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

  void _toggleCameraView() async {
    setState(() {
      _showCamera = !_showCamera;
    });

    if (_showCamera && _isCameraInitialized && _cameraController != null) {
      if (!_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream(_processCameraImage);
        print("Image stream started.");
      }
      // Ensure translation models are checked when camera opens
      _checkAndDownloadModels().then((_) {
        if (_originalTextController.text.length >= 3) {
          _onOriginalTextChangedForTranslation();
        }
      });
    } else if (!_showCamera && _cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
      print("Image stream stopped.");
      _isTextRecognizerBusy = false; // Reset busy flag
      // Clear text fields when closing camera
      _originalTextController.clear();
      _translatedTextController.clear();
      if (_debounceTranslation?.isActive ?? false) _debounceTranslation!.cancel();
      if(mounted) setState(() {_isTranslating = false;});
    } else if (_showCamera && !_isCameraInitialized) {
      // If toggling to show camera but it's not initialized yet, initialize it.
      _initializeCameraAndDependencies();
    }
  }


  Future<void> _processCameraImage(CameraImage image) async {
    if (_textRecognizer == null || _isTextRecognizerBusy || !_showCamera || !_isCameraInitialized) {
      return;
    }

    _isTextRecognizerBusy = true; // Mark as busy
    print("Processing camera image...");

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    // Determine camera sensor orientation for correct rotation
    final camera = _cameras![_cameraController!.description.lensDirection == CameraLensDirection.front ? 1 : 0]; // Adjust index if needed
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;


    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;


    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

    try {
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      // --- Update originalTextController with recognized text ---
      if (recognizedText.text.isNotEmpty) {
        // To avoid rapid, jarring updates, you might want to only update
        // if the new text is significantly different or after a pause.
        // For simplicity, we'll update directly here.
        if (mounted && _originalTextController.text != recognizedText.text) {
          // Check if the current text is just the placeholder from translation
          bool isPlaceholder = _originalTextController.text == "Translating (on-device)..." ||
              _originalTextController.text == "Models not ready" ||
              _originalTextController.text.startsWith("Error:");

          // Update only if it's not a placeholder or if recognized text is different and confidence is high
          if(isPlaceholder || _originalTextController.text != recognizedText.text) {
            bool passedScore = true;
            // for(TextBlock block in recognizedText.blocks) {
            //   for (TextLine line in block.lines) {
            //     print("Line Text: ${line.text}, Confidence: ${line.confidence}");
            //     if ((line.confidence ?? 0) < 0.4) {
            //       passedScore = false;
            //       break;
            //     }
            //   }
            // }

            if(passedScore) {
              _originalTextController.text = recognizedText.text;
              // The listener on _originalTextController will trigger translation
            }
          }
        }
      }
      // print("Recognized Text: ${recognizedText.text}"); // For debugging
    } catch (e) {
      print("Text Recognition Error: $e");
    } finally {
      print("Processing camera image complete.");
      if(mounted) {
        _isTextRecognizerBusy = false; // Release the busy flag
      }
    }
  }


  void _captureAndAddTranslation() {
    // ... (Keep existing capture logic)
    final String originalText = _originalTextController.text;
    final String translatedText = _translatedTextController.text;

    if (originalText.isNotEmpty && translatedText.isNotEmpty &&
        !_isTranslating &&
        !translatedText.startsWith("Translating") &&
        !translatedText.startsWith("Models not ready") &&
        !translatedText.startsWith("Error:")) {
      final newTranslation = TranslationModel(
        originalText: originalText,
        translatedText: translatedText,
        languageCode: _targetLanguage.bcpCode,
        dateAndTime: DateTime.now(),
      );
      setState(() {
        _translations.insert(0, newTranslation);
        // Don't clear fields immediately after capture if user wants to refine
        // _showCamera = false; // Optionally close camera after capture
        // _originalTextController.clear();
        // _translatedTextController.clear();
        // if (_debounceTranslation?.isActive ?? false) _debounceTranslation!.cancel();
        // _isTranslating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation Captured!')),
      );
    } else if (_isTranslating || translatedText.startsWith("Translating")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for translation to complete.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter text and ensure it is translated correctly.')),
      );
    }
  }


  @override
  void dispose() {
    _cameraController?.dispose();
    _originalTextController.removeListener(_onOriginalTextChangedForTranslation);
    _originalTextController.dispose();
    _translatedTextController.dispose();
    _debounceTranslation?.cancel();
    _onDeviceTranslator?.close();
    _textRecognizer?.close(); // Close the TextRecognizer
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // ... (Scaffold and AppBar are mostly the same)
    // Add a loading indicator if camera is initializing for the first time
    if (!_isCameraInitialized && _showCamera) {
      return Scaffold(
        appBar: AppBar(title: const Text("Initializing Camera...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        key: appBarKey,
        title: Text('(${_sourceLanguage.name} -> ${_targetLanguage.name})'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.download_for_offline,
                color: (_isSourceModelDownloaded && _isTargetModelDownloaded) ? Colors.green : Colors.grey),
            onPressed: _checkAndDownloadModels,
            tooltip: "Check/Download Translation Models",
          ),
          IconButton(
            key: addPhotoButtonKey,
            icon: Icon(_showCamera ? Icons.camera_alt : Icons.add_a_photo_outlined), // Change icon
            onPressed: _toggleCameraView, // Directly call toggle
          ),
        ],
      ),
      body: _showCamera && _isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized
          ? _buildCameraLayout()
          : _buildTranslationsView(),
    );
  }

  Widget _buildCameraLayout() {
    // ... (CameraPreview and TextFields layout remains largely the same)
    // Ensure camera controller is initialized before building preview
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

    return ListView( // Using ListView as before
      children: <Widget>[
        Padding( // Added padding around CameraPreview
          padding: const EdgeInsets.all(16.0),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0) // Optional: Rounded corners for the preview
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
        // Original Text Field
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
                labelText: 'Original Text (from Camera / min. 3 chars to translate)',
                hintText: 'Text from camera appears here...',
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Translated Text Field
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
                labelText: 'Translated Text (to ${_targetLanguage.name})',
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
        // Capture Translation Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            key: captureTranslationButtonKey,
            onPressed: (_isSourceModelDownloaded && _isTargetModelDownloaded)
                ? _captureAndAddTranslation
                : null,
            child: const Text('Capture Translation'),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationsView() {
    // ... (This widget remains the same)
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