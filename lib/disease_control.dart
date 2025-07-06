import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';

class DiseaseControlPage extends StatefulWidget {
  const DiseaseControlPage({super.key});
  @override
  State<DiseaseControlPage> createState() => _DiseaseControlPageState();
}

class _DiseaseControlPageState extends State<DiseaseControlPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  XFile? _imageFile;
  String _prediction = '';
  String _confidence = '';
  String? _errorMessage;
  String? _guidanceMessage;
  bool _isCameraOn = false;
  bool _isProcessing = false;
  bool _modelLoaded = false;
  bool _isLoading = false;
  String? _tempImagePath;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  Interpreter? _interpreter;
  List<String>? _labels;
  int? _numClasses;
  List<int> _inputShape = [1, 224, 224, 3];
  Timer? _captureDebounceTimer;
  bool _canCapture = true;
  bool _initialLoadComplete = false;
  bool _isDisposing = false;
  DateTime? _lastCaptureTime;
  final int _minCaptureInterval = 2000;
  bool _isLowMemoryDevice = false;
  int _availableBuffers = 3;
  bool _isCameraBusy = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDeviceMemory().then((_) => _initializeApp());
  }

  Future<void> _logScreenView() async {
    try {
      await _analytics.logEvent(
        name: 'screen_view',
        parameters: {'screen_name': 'DiseaseControlPage'},
      );
    } catch (e) {
      debugPrint('Analytics log error: $e');
    }
  }

  Future<void> _checkDeviceMemory() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        const channel = MethodChannel('activity');
        final isLowMem = await channel.invokeMethod<bool>('isInLowMemoryState');
        setState(() => _isLowMemoryDevice = isLowMem ?? false);
      }
    } catch (e) {
      debugPrint('Memory check error: $e');
    }
  }

  Future<void> _initializeApp() async {
    if (kIsWeb) {
      setState(() {
        _errorMessage = 'Camera and model not supported on web';
        _initialLoadComplete = true;
      });
      return;
    }

    try {
      await _logScreenView();
      await _loadModel();
      await _checkPermissions();
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: $e';
      });
    } finally {
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposing) return;

    if (state == AppLifecycleState.paused) {
      _safeDisposeCamera();
    } else if (state == AppLifecycleState.resumed &&
        !_isCameraOn &&
        _modelLoaded) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposing && mounted) {
          _checkPermissions();
        }
      });
    }
  }

  Future<void> _safeDisposeCamera() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      }
      if (mounted) {
        setState(() {
          _controller = null;
          _isCameraOn = false;
          _availableBuffers = 3;
        });
      }
    } catch (e) {
      debugPrint('Camera dispose error: $e');
    }
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _modelLoaded = false;
    });

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/tomato.tflite',
        options: InterpreterOptions()..threads = _isLowMemoryDevice ? 1 : 2,
      );

      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _numClasses = _labels!.length;

      final inputTensor = _interpreter!.getInputTensors().first;
      _inputShape = inputTensor.shape;

      setState(() {
        _modelLoaded = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Model loading failed: $e';
        _modelLoaded = false;
      });
      debugPrint('Model loading error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb || !_modelLoaded || _isDisposing) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final status = await Permission.camera.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        final requestStatus = await Permission.camera.request();
        if (requestStatus.isDenied || requestStatus.isPermanentlyDenied) {
          setState(() {
            _errorMessage =
                'Camera permission denied. Please enable it in settings.';
          });
          return;
        }
      }
      await _initializeCamera();
    } catch (e) {
      setState(() {
        _errorMessage = 'Permission check failed: $e';
      });
      debugPrint('Permission error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing) return;

    await _safeDisposeCamera();
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = true;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isCameraOn = false;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final resolution = _isLowMemoryDevice
          ? ResolutionPreset.low
          : ResolutionPreset.medium;

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!_controller!.value.isInitialized) {
        throw Exception('Camera failed to initialize');
      }

      if (mounted) {
        setState(() {
          _isCameraOn = true;
          _errorMessage = null;
          _availableBuffers = 3;
        });
      }
    } catch (e) {
      await _safeDisposeCamera();
      setState(() {
        _errorMessage = 'Camera initialization failed: ${e.toString()}';
        _isCameraOn = false;
      });
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (_isDisposing || _isAnalyzing || _controller == null) return;

    final now = DateTime.now();
    if (_lastCaptureTime != null &&
        now.difference(_lastCaptureTime!).inMilliseconds <
            _minCaptureInterval) {
      setState(() {
        _errorMessage =
            'Please wait ${_minCaptureInterval ~/ 1000} seconds between captures';
      });
      return;
    }

    if (!_canCapture ||
        !_controller!.value.isInitialized ||
        !_modelLoaded ||
        _isProcessing ||
        _availableBuffers <= 0 ||
        _isCameraBusy ||
        _controller!.value.isTakingPicture) {
      setState(() {
        _errorMessage = !_canCapture
            ? 'Please wait before capturing again'
            : !_controller!.value.isInitialized
            ? 'Camera not ready'
            : !_modelLoaded
            ? 'Model not loaded'
            : _availableBuffers <= 0
            ? 'Camera buffers exhausted. Wait a moment.'
            : _isCameraBusy || _controller!.value.isTakingPicture
            ? 'Camera is busy processing previous request'
            : 'Processing in progress';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _canCapture = false;
      _isCameraBusy = true;
      _availableBuffers--;
      _errorMessage = null;
      _lastCaptureTime = now;
    });

    _captureDebounceTimer?.cancel();
    _captureDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _canCapture = true;
          _errorMessage = null;
        });
      }
    });

    try {
      await _cleanupTempImage();
      final image = await _controller!.takePicture();
      setState(() {
        _imageFile = image;
        _tempImagePath = image.path;
      });
      await _diagnoseImage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: ${e.toString()}';
        _availableBuffers++;
      });
      debugPrint('Capture image error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isCameraBusy = false;
        });
      }
    }
  }

  Future<void> _diagnoseImage() async {
    if (_imageFile == null || _isAnalyzing || !_modelLoaded || _isDisposing) {
      setState(() {
        _errorMessage = _imageFile == null
            ? 'No image selected'
            : _isAnalyzing
            ? 'Analysis in progress'
            : 'Model not loaded';
        if (!_isAnalyzing) {
          _availableBuffers = (_availableBuffers + 1).clamp(0, 3);
        }
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _isLoading = true;
      _prediction = 'Analyzing...';
      _confidence = '';
      _guidanceMessage = null;
    });

    try {
      await _runInference(_tempImagePath!);
      if (_isLowMemoryDevice) {
        await Future.delayed(const Duration(milliseconds: 100));
        SystemChannels.platform.invokeMethod('System.gc');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Diagnosis failed: $e';
        _prediction = '';
        _confidence = '';
        _guidanceMessage = null;
      });
      debugPrint('Diagnose image error: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
        _isLoading = false;
        _availableBuffers = (_availableBuffers + 1).clamp(0, 3);
      });
    }
  }

Future<void> _runInference(String imagePath) async {
  if (_interpreter == null || _labels == null || _isDisposing) {
    throw Exception('Model or labels not loaded properly');
  }

  final imageFile = File(imagePath);
  if (!await imageFile.exists()) {
    throw Exception('Image file does not exist: $imagePath');
  }

  final imageBytes = await imageFile.readAsBytes();
  final decodedImage = img.decodeImage(imageBytes);

  if (decodedImage == null) {
    throw Exception('Failed to decode image');
  }

  try {
    final resizedImage = img.copyResize(
      decodedImage,
      width: _inputShape[2],
      height: _inputShape[1],
    );

    // Calculate expected input size
    final inputSize = _inputShape.reduce((a, b) => a * b);
    final inputBuffer = Float32List(inputSize);

    // Fill buffer with normalized pixel values
    int bufferIndex = 0;
    for (int y = 0; y < _inputShape[1]; y++) {
      for (int x = 0; x < _inputShape[2]; x++) {
        final pixel = resizedImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        inputBuffer[bufferIndex++] = r / 255.0;
        inputBuffer[bufferIndex++] = g / 255.0;
        inputBuffer[bufferIndex++] = b / 255.0;
      }
    }

    // Prepare input as a reshaped tensor
    final input = inputBuffer.reshape(_inputShape);

    // Prepare correct output buffer shape [1, numClasses]
    final outputShape = _interpreter!.getOutputTensor(0).shape; // Should be [1, numClasses]
    final numClasses = outputShape[1];

    // Create output buffer of shape [1, numClasses]
    final output = [List.filled(numClasses, 0.0)];

    // Run inference
    _interpreter!.run(input, output);

    final scores = output[0];
    final maxIndex = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    final confidence = scores[maxIndex] * 100;

    if (confidence.isNaN || confidence < 0 || confidence > 100) {
      throw Exception('Invalid confidence score: $confidence');
    }

    if (confidence < 60.0) {
      setState(() {
        _prediction = 'Unrecognized Image';
        _confidence = '';
        _guidanceMessage = 'Please capture a clear image of a tomato leaf.';
      });
    } else {
      final prediction = _labels![maxIndex];
      setState(() {
        _prediction = prediction.replaceAll('_', ' ');
        _confidence = '${confidence.toStringAsFixed(1)}%';
        _guidanceMessage = _getGuidanceMessage(_prediction);
      });
    }
  } catch (e) {
    throw Exception('Inference error: $e');
  } finally {
    if (_isLowMemoryDevice) {
      SystemChannels.platform.invokeMethod('System.gc');
    }
  }
}


  String _getGuidanceMessage(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'tomato early blight':
        return 'Early Blight detected. Remove affected leaves and apply copper-based fungicides.';
      case 'tomato healthy':
        return 'Your tomato leaf is healthy! Continue regular care.';
      case 'tomato late blight':
        return 'Late Blight detected. Remove affected leaves and use mancozeb fungicide.';
      case 'tomato leaf mold':
        return 'Leaf Mold detected. Improve air circulation and apply fungicides.';
      case 'tomato septoria leaf spot':
        return 'Septoria Leaf Spot detected. Remove affected leaves and use chlorothalonil.';
      case 'tomato spider mites two spotted spider mite':
        return 'Spider Mites detected. Use miticides or neem oil.';
      case 'tomato target spot':
        return 'Target Spot detected. Apply fungicides and remove affected leaves.';
      case 'tomato yellowleaf curl virus':
        return 'Yellow Leaf Curl Virus detected. Remove affected plants and control whiteflies.';
      case 'tomato mosaic virus':
        return 'Mosaic Virus detected. Remove affected plants and disinfect tools.';
      case 'tomato bacterial spot':
        return 'Bacterial Spot detected. Apply copper-based bactericides.';
      case 'pepper bell bacterial spot':
        return 'Bell Pepper Bacterial Spot detected. Apply copper-based bactericides.';
      case 'pepper bell healthy':
        return 'Your bell pepper leaf is healthy! Continue regular care.';
      case 'potato early blight':
        return 'Potato Early Blight detected. Remove affected leaves and apply fungicides.';
      case 'potato late blight':
        return 'Potato Late Blight detected. Remove affected leaves and use mancozeb.';
      case 'potato healthy':
        return 'Your potato leaf is healthy! Continue regular care.';
      default:
        return 'Consult an agricultural expert for assistance.';
    }
  }

  Future<void> _cleanupTempImage() async {
    if (_tempImagePath != null && _imageFile?.path != _tempImagePath) {
      try {
        final file = File(_tempImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Cleanup error: $e');
      } finally {
        _tempImagePath = null;
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _captureDebounceTimer?.cancel();
    _safeDisposeCamera();
    _interpreter?.close();
    _cleanupTempImage();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoadComplete) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green.shade700),
              const SizedBox(height: 20),
              Text(
                'Loading Plant Disease Scanner...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(
          child: const Text(
            'Tomato Leaf Scanner',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInUp(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _modelLoaded
                                ? 'Scan a tomato leaf to diagnose diseases'
                                : 'Model loading failed. Please restart the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _modelLoaded ? Colors.grey : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInLeft(
                      child: Card(
                        elevation: 8,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.shade400,
                              width: 4,
                            ),
                          ),
                          child: _buildCameraPreview(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      child: _buildButton(
                        icon: _isCameraOn ? Icons.videocam_off : Icons.videocam,
                        label: _isCameraOn
                            ? 'Turn Camera Off'
                            : 'Turn Camera On',
                        color: _isCameraOn
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                        onPressed: _toggleCamera,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      child: _buildButton(
                        icon: Icons.photo_library,
                        label: 'Select from Gallery',
                        color: Colors.blue.shade600,
                        onPressed: _pickImageFromGallery,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInUp(
                      child: _buildButton(
                        icon: Icons.photo_camera,
                        label: 'Capture Image',
                        color: Colors.green.shade700,
                        onPressed: _isCameraOn ? _captureImage : null,
                      ),
                    ),
                    if (_imageFile != null)
                      FadeInUp(
                        child: _buildButton(
                          icon: Icons.healing,
                          label: 'Diagnose Again',
                          color: Colors.purple.shade600,
                          onPressed: _diagnoseImage,
                        ),
                      ),
                    if (_errorMessage != null)
                      FadeInUp(
                        child: Card(
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () {
                                          setState(() {
                                            _errorMessage = null;
                                            _prediction = '';
                                            _confidence = '';
                                            _guidanceMessage = null;
                                          });
                                          if (_errorMessage!.contains(
                                            'permission',
                                          )) {
                                            openAppSettings();
                                          } else if (_errorMessage!.contains(
                                            'model',
                                          )) {
                                            _loadModel();
                                          } else {
                                            _checkPermissions();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!.contains('permission')
                                        ? 'Open Settings'
                                        : _errorMessage!.contains('model')
                                        ? 'Reload Model'
                                        : 'Retry',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_imageFile != null) _buildResultSection(),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing Leaf...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleCamera() async {
    if (_isCameraOn) {
      await _safeDisposeCamera();
    } else {
      await _checkPermissions();
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isDisposing || _isProcessing) return;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = XFile(pickedFile.path);
          _tempImagePath = pickedFile.path;
        });
        await _diagnoseImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
      debugPrint('Pick image error: $e');
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.red.shade800,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!_isCameraOn ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 8),
            Text(
              _modelLoaded ? 'Tap to start camera' : 'Model not loaded',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 300,
        height: 300,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize?.width ?? 300,
            height: _controller!.value.previewSize?.height ?? 300,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade400, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.file(
                File(_imageFile!.path),
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  _cleanupTempImage();
                  return Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Diagnosis: $_prediction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _prediction.contains('Healthy')
                            ? Colors.green.shade800
                            : _prediction.contains('Unrecognized')
                            ? Colors.orange.shade800
                            : Colors.red.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_confidence.isNotEmpty)
                      Text(
                        'Confidence: $_confidence',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _guidanceMessage ?? 'No guidance available.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              setState(() {
                                _imageFile = null;
                                _prediction = '';
                                _confidence = '';
                                _guidanceMessage = null;
                              });
                              _cleanupTempImage();
                              if (_isCameraOn) {
                                _captureImage();
                              } else {
                                _pickImageFromGallery();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Scan Another Leaf',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
