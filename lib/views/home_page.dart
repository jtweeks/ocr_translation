import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Key for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Key for the AppBar
  static const Key appBarKey = ValueKey('homePageAppBar');
  // Key for the add button
  static const Key addPhotoButtonKey = ValueKey('addPhotoButton');
  // Key for the camera preview (conditionally shown)
  static const Key cameraPreviewKey = ValueKey('cameraPreview');

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Default to the first available camera (usually rear)
        _cameraController = CameraController(
          _cameras![0], // Selects the first camera (often the rear one)
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        print("No cameras available");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras available on this device.')),
          );
        }
      }
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
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
        foregroundColor: Colors.black, // For title and icon color
        actions: [
          IconButton(
            key: addPhotoButtonKey,
            icon: const Icon(Icons.add_a_photo_outlined), // Changed to a camera-related plus icon
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
      body: ListView(
        children: [
          Container(
            height: 400,
            child: Center(
              child: _showCamera && _isCameraInitialized && _cameraController != null
                  ? CameraPreview(
                _cameraController!,
                key: cameraPreviewKey,
              )
                  : const Text(
                'Welcome to the Home Page!',
                key: ValueKey('homePageWelcomeText'),
              ),
            ),
          ),
        ]
      ),
    );
  }
}
