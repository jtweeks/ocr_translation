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
  static const Key cameraPreviewKey = ValueKey('cameraPreview');
  static const Key translationsListKey = ValueKey('translationsListView'); // Key for the ListView

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showCamera = false;

  // List to hold translations
  List<TranslationModel> _translations = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadTranslations(); // Load translations
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
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

  // Method to load translations
  void _loadTranslations() {
    setState(() {
      // Get translations from your TranslationModel
      _translations = TranslationModel.getTranslations();
    });
  }

  void _toggleCameraView() {
    setState(() {
      _showCamera = !_showCamera;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
      body: Center(
        child: _showCamera && _isCameraInitialized && _cameraController != null
            ? CameraPreview(
          _cameraController!,
          key: cameraPreviewKey,
        )
            : _buildTranslationsView(), // Show translations or a welcome message
      ),
    );
  }

  // Widget to build the translations list or a fallback message
  Widget _buildTranslationsView() {
    if (_translations.isEmpty) {
      return const Text(
        'No translations yet. Add some!',
        key: ValueKey('noTranslationsText'), // Key for this state
      );
    } else {
      return ListView.builder(
        key: translationsListKey, // Assign a key to the ListView
        itemCount: _translations.length,
        itemBuilder: (context, index) {
          final TranslationModel translation = _translations[index];
          return ListTile(
            // It's good practice to give keys to items in a list if they can change
            key: ValueKey('translation_item_${translation.originalText}_${translation.dateAndTime.millisecondsSinceEpoch}'),
            title: Text(translation.originalText),
            subtitle: Text(
                '${translation.translatedText} (${translation.languageCode.toUpperCase()})'),
            trailing: Text(
              // Simple date formatting, you might want to use the 'intl' package for better formatting
              '${translation.dateAndTime.day}/${translation.dateAndTime.month}/${translation.dateAndTime.year}',
            ),
          );
        },
      );
    }
  }
}
