import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:mockito/mockito.dart';
import 'package:ocr_translation/views/home_page.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';


// Mock CameraPlatform to control camera behavior in tests
class MockCameraPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements CameraPlatform {

  @override
  Future<List<CameraDescription>> availableCameras() async {
    return [
      const CameraDescription(
        name: '0', // Mock camera name
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
      const CameraDescription(
        name: '1',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 270,
      ),
    ];
  }

  @override
  Future<int> createCamera(
      CameraDescription cameraDescription,
      ResolutionPreset? resolutionPreset, {
        bool enableAudio = false,
      }) async {
    return 1; // Mock camera ID
  }

  @override
  Future<void> initializeCamera(
      int cameraId, {
        ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
      }) async {
    return;
  }

  @override
  Future<void> dispose(int cameraId) async {
    return;
  }

  @override
  Widget buildPreview(int cameraId) {
    // Return a simple widget for the preview in tests
    return const SizedBox(key: ValueKey('MockCameraPreview'));
  }

  // Mock other methods as needed for more complex camera interactions
  @override
  Future<void> playSound(int cameraId, String sound) async {}

  @override
  Future<void> pausePreview(int cameraId) async {}

  @override
  Future<void> resumePreview(int cameraId) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return Stream.value(CameraInitializedEvent(
        cameraId,
        320, // previewWidth
        240, // previewHeight
        ExposureMode.auto,
        true, // isAutoExposureLocked
        FocusMode.auto,
        true, // isAutoFocusLocked
    ));
  }

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) {
    return const Stream.empty();
  }

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) {
    return const Stream.empty();
  }

  // --- Add other required method overrides with mock implementations ---
  // You'll need to look at the CameraPlatform interface and provide
  // mock implementations for all abstract methods.
  // For example:
  @override
  Future<XFile> takePicture(int cameraId) async {
    // This is a simplified mock. You might need to create a mock XFile.
    return XFile('mock_path');
  }

  @override
  Future<void> prepareForVideoRecording() async {}

  @override
  Future<void> startVideoRecording(int cameraId, {Duration? maxVideoDuration}) async {}


  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    return XFile('mock_video_path');
  }

  @override
  Future<void> pauseVideoRecording(int cameraId) async {}

  @override
  Future<void> resumeVideoRecording(int cameraId) async {}

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}

  @override
  Future<void> setExposureMode(int cameraId, ExposureMode mode) async {}

  @override
  Future<void> setExposurePoint(int cameraId, Point<double>? point) async {}

  @override
  Future<double> getMinExposureOffset(int cameraId) async {
    return 0.0;
  }

  @override
  Future<double> getMaxExposureOffset(int cameraId) async {
    return 1.0;
  }

  @override
  Future<double> getExposureOffsetStepSize(int cameraId) async {
    return 0.1;
  }

  @override
  Future<double> setExposureOffset(int cameraId, double offset) async {
    return offset;
  }

  @override
  Future<void> setFocusMode(int cameraId, FocusMode mode) async {}

  @override
  Future<void> setFocusPoint(int cameraId, Point<double>? point) async {}

  @override
  Future<void> setWhiteBalancePoint(int cameraId, Point<double>? point) async {}

  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {}

  @override
  Future<double> getMinZoomLevel(int cameraId) async {
    return 1.0;
  }

  @override
  Future<double> getMaxZoomLevel(int cameraId) async {
    return 2.0;
  }

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() {
    return const Stream.empty();
  }

  @override
  Future<void> lockCaptureOrientation(int cameraId, DeviceOrientation orientation) async {}

  @override
  Future<void> unlockCaptureOrientation(int cameraId) async {}

  @override
  Future<void> setSensorOrientation(int cameraId, int orientation) async {}

  @override
  Future<void> setDescription(CameraDescription description) async {}
}

void main() {
  // Store the original CameraPlatform implementation
  TestWidgetsFlutterBinding.ensureInitialized();
  final CameraPlatform initialPlatform = CameraPlatform.instance;
  late MockCameraPlatform mockCameraPlatform;


  setUpAll(() {
    // It's important to set up the mock before any tests run that might use the camera.
    mockCameraPlatform = MockCameraPlatform();
    CameraPlatform.instance = mockCameraPlatform;
  });

  // Restore the original platform after all tests are done
  tearDownAll(() {
    CameraPlatform.instance = initialPlatform;
  });


  testWidgets('HomePage has an AppBar and a plus button, and toggles camera view', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // Verify that the AppBar with the correct key is present.
    expect(find.byKey(ValueKey('homePageAppBar')), findsOneWidget);
    expect(find.text('Home Page'), findsOneWidget); // Verify title

    // Verify that the add photo button with the correct key is present.
    final Finder addButtonFinder = find.byKey(ValueKey('addPhotoButton'));
    expect(addButtonFinder, findsOneWidget);

    // Verify that the welcome text is initially visible.
    expect(find.byKey(const ValueKey('homePageWelcomeText')), findsOneWidget);
    // Verify that the camera preview is initially not visible.
    expect(find.byKey(ValueKey('cameraPreview')), findsNothing);

    // Tap the plus icon button.
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(); // pumpAndSettle to allow async operations (like camera init) and state changes to complete

    // Verify that the camera preview is now visible.
    // In a real test with a mocked camera, you'd expect 'MockCameraPreview'.
    // Since CameraPreview itself renders platform views, direct finding can be tricky.
    // We rely on the key of our SizedBox in the mock.
    expect(find.byKey(const ValueKey('MockCameraPreview')), findsOneWidget);
    // Verify that the welcome text is no longer visible.
    expect(find.byKey(const ValueKey('homePageWelcomeText')), findsNothing);

    // Tap the plus icon button again to hide the camera.
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // Verify that the camera preview is hidden again.
    expect(find.byKey(const ValueKey('MockCameraPreview')), findsNothing);
    // Verify that the welcome text is visible again.
    expect(find.byKey(const ValueKey('homePageWelcomeText')), findsOneWidget);
  });

  // testWidgets('HomePage shows snackbar if camera initialization fails or no cameras', (WidgetTester tester) async {
  //   // --- Test case for no cameras available ---
  //   // Override the mock to return no cameras
  //   final originalAvailableCameras = mockCameraPlatform.availableCameras; // Store original
  //   mockCameraPlatform.availableCameras =  () async => []; // Override
  //
  //   await tester.pumpWidget(const MaterialApp(home: HomePage()));
  //   await tester.pumpAndSettle(); // Allow initState to complete
  //
  //   // It might take a moment for the SnackBar to appear due to async nature
  //   // Expect a SnackBar
  //   // Note: Finding SnackBars can sometimes require specific finders or waiting.
  //   // This example assumes it appears relatively quickly.
  //   expect(find.text('No cameras available on this device.'), findsOneWidget, skip: false); // Re-enable or adjust based on actual behavior
  //
  //   // Restore the original mock behavior for other tests
  //   mockCameraPlatform.availableCameras = originalAvailableCameras;
  //
  //
  //   // --- Test case for camera initialization error ---
  //   // You might need to make initializeCamera throw an exception in the mock
  //   // For simplicity, we'll assume the "No cameras" case covers showing a SnackBar.
  //   // A more specific test would involve making _cameraController.initialize() throw.
  // });
}
