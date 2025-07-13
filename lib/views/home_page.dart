import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ocr_translation/models/translation_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const Key appBarKey = ValueKey('homePageAppBar');
  static const Key addPhotoButtonKey = ValueKey('addPhotoButton');
  static const Key cameraPreviewWidgetKey = ValueKey('cameraPreviewWidget'); // Key for the CameraPreview itself
  static const Key translationsListKey = ValueKey('translationsListView');
  static const Key originalTextFieldKey = ValueKey('originalTextField');
  static const Key translatedTextFieldKey = ValueKey('translatedTextField');
  static const Key captureTranslationButtonKey = ValueKey('captureTranslationButton');

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showCamera = false;

  List<TranslationModel> _translations = [];

  // Controllers for the TextFields
  final TextEditingController _originalTextController = TextEditingController();
  final TextEditingController _translatedTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadTranslations();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // Selects the first camera (often the rear one)
          ResolutionPreset.high, // Use a higher resolution if taking pictures for OCR
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
    setState(() {
      _translations = TranslationModel.getTranslations(); // Initial load
    });
  }

  void _toggleCameraView() {
    setState(() {
      _showCamera = !_showCamera;
      if (!_showCamera) {
        // Clear text fields when closing camera view if desired
        _originalTextController.clear();
        _translatedTextController.clear();
      }
    });
  }

  void _captureAndAddTranslation() {
    final String originalText = _originalTextController.text;
    final String translatedText = _translatedTextController.text;

    if (originalText.isNotEmpty && translatedText.isNotEmpty) {
      // For simplicity, using "auto" as language code.
      // You'd determine this based on your translation mechanism.
      final newTranslation = TranslationModel(
        originalText: originalText,
        translatedText: translatedText,
        languageCode: "auto", // Placeholder, determine appropriately
        dateAndTime: DateTime.now(),
      );

      setState(() {
        _translations.insert(0, newTranslation); // Add to the beginning of the list
        _showCamera = false; // Close the camera preview
        _originalTextController.clear();
        _translatedTextController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation Captured!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both original and translated text.')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _originalTextController.dispose();
    _translatedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        key: appBarKey,
        title: const Text('Home Page'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
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
          ? _buildCameraLayout() // Use the new layout method
          : _buildTranslationsView(),
    );
  }

  Widget _buildCameraLayout() {
    // Ensure camera controller is initialized and preview is ready
    if (!_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    // Calculate aspect ratio for CameraPreview
    // Use a default if aspect ratio is 0 or invalid to prevent errors
    final screenAspectRatio = MediaQuery.of(context).size.aspectRatio;
    final previewAspectRatio = _cameraController!.value.aspectRatio > 0
        ? _cameraController!.value.aspectRatio
        : screenAspectRatio; // fallback to screen AR

    return ListView(
      children: <Widget>[
        // Camera Preview
        // AspectRatio widget helps maintain the camera's aspect ratio
        AspectRatio(
          aspectRatio: previewAspectRatio,
          child: CameraPreview(
            _cameraController!,
            key: cameraPreviewWidgetKey, // Key for the actual CameraPreview widget
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
                labelText: 'Original Text',
                hintText: 'Text captured from camera...',
                border: InputBorder.none,
              ),
              maxLines: 3, // Allow multiple lines
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
              color: Colors.lightBlue.shade100,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              key: translatedTextFieldKey,
              controller: _translatedTextController,
              decoration: const InputDecoration(
                labelText: 'Translated Text',
                hintText: 'Translation will appear here...',
                border: InputBorder.none,
              ),
              maxLines: 3, // Allow multiple lines
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Capture Translation Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            key: captureTranslationButtonKey,
            onPressed: _captureAndAddTranslation,
            child: const Text('Capture Translation'),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationsView() {
    if (_translations.isEmpty) {
      return const Center( // Center the message
        child: Text(
          'No translations yet. Add some!',
          key: ValueKey('noTranslationsText'),
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
