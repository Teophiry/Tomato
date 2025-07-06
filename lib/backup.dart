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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:animate_do/animate_do.dart';

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
  int _numClasses = 0;
  List<int> _inputShape = [1, 224, 224, 3];
  Timer? _captureDebounceTimer;
  bool _canCapture = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _loadModel();
      _checkPermissions();
    } else {
      setState(() {
        _errorMessage = 'Camera and model not supported on web';
      });
    }
    _logScreenView();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!kIsWeb) {
      if (state == AppLifecycleState.resumed && !_isCameraOn) {
        _checkPermissions();
      } else if (state == AppLifecycleState.paused && _controller != null) {
        _controller?.dispose();
        if (mounted) {
          setState(() {
            _controller = null;
            _isCameraOn = false;
          });
        }
        print('Camera paused and disposed');
      }
    }
  }

  Future<void> _logScreenView() async {
    try {
      await _analytics.logScreenView(
        screenName: 'DiseaseControlPage',
        screenClass: 'DiseaseControlPage',
      );
    } catch (e) {
      print('Analytics log error: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      // Verify model asset
      final modelFile = await DefaultAssetBundle.of(
        context,
      ).load('assets/tomato_disease_model.tflite');
      final modelSize = modelFile.lengthInBytes;
      if (modelSize < 10240) {
        throw Exception(
          'Model file too small ($modelSize bytes, expected ~7-50MB)',
        );
      }
      print('Model file size: $modelSize bytes');

      // Load labels
      final labelsData = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (_labels == null || _labels!.isEmpty) {
        throw Exception('Labels file is empty or missing');
      }
      print('Loaded ${_labels!.length} labels: ${_labels!.join(', ')}');

      // Initialize interpreter
      _interpreter = await Interpreter.fromAsset(
        'tomato_disease_model.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      _interpreter!.allocateTensors();

      // Verify tensor shapes
      final inputTensor = _interpreter!.getInputTensors()[0];
      final outputTensor = _interpreter!.getOutputTensors()[0];
      _inputShape = inputTensor.shape;
      _numClasses = outputTensor.shape[1];

      if (_inputShape.length != 4 ||
          _inputShape[3] != 3 ||
          _inputShape[1] != 224 ||
          _inputShape[2] != 224) {
        throw Exception(
          'Unexpected input shape: $_inputShape, expected [1, 224, 224, 3]',
        );
      }
      if (_numClasses != _labels!.length) {
        throw Exception(
          'Output classes ($_numClasses) do not match labels (${_labels!.length})',
        );
      }
      print('Input shape: $_inputShape, Output classes: $_numClasses');

      if (mounted) {
        setState(() {
          _modelLoaded = true;
          _errorMessage = null;
        });
      }
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load model: $e';
          _modelLoaded = false;
        });
      }
      await _analytics.logEvent(
        name: 'model_load_error',
        parameters: {'screen': 'DiseaseControlPage', 'error': e.toString()},
      );
    }
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) return;
    try {
      final status = await Permission.camera.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        final requestStatus = await Permission.camera.request();
        if (requestStatus.isDenied || requestStatus.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Camera permission denied. Please enable it in settings.';
            });
          }
          return;
        }
      }
      await _initializeCamera();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Permission check failed: $e';
        });
      }
      print('Permission error: $e');
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras available';
            _isCameraOn = false;
          });
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.low, // Changed to low for faster buffer release
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraOn = true;
          _errorMessage = null;
        });
      }
      print('Camera initialized');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera initialization failed: $e';
          _isCameraOn = false;
        });
      }
      print('Camera initialization error: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (kIsWeb || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_isCameraOn) {
        await _controller?.dispose();
        if (mounted) {
          setState(() {
            _controller = null;
            _isCameraOn = false;
          });
        }
        print('Camera turned off');
      } else {
        await _checkPermissions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error toggling camera: $e';
        });
      }
      print('Toggle camera error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    if (!_canCapture ||
        _controller == null ||
        !_controller!.value.isInitialized ||
        !_modelLoaded ||
        _isProcessing) {
      if (mounted) {
        setState(() {
          _errorMessage = !_canCapture
              ? 'Please wait 2 seconds before capturing again'
              : _controller == null || !_controller!.value.isInitialized
              ? 'Camera not ready'
              : !_modelLoaded
              ? 'Model not loaded'
              : 'Processing in progress';
        });
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _canCapture = false;
      _errorMessage = null;
    });

    // Start debounce timer
    _captureDebounceTimer?.cancel();
    _captureDebounceTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _canCapture = true;
        });
      }
    });

    try {
      await _analytics.logEvent(
        name: 'capture_image_attempt',
        parameters: {
          'screen': 'DiseaseControlPage',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final image = await _controller!.takePicture();
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(
        tempDir.path,
        'tomato_leaf_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      // Use image.path directly to avoid copying
      if (mounted) {
        setState(() {
          _imageFile = image;
          _tempImagePath = image.path;
        });
      }

      await _analytics.logEvent(
        name: 'capture_image_success',
        parameters: {'screen': 'DiseaseControlPage', 'temp_path': tempPath},
      );

      await _diagnoseImage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture image: $e';
        });
      }
      print('Capture image error: $e');
      await _analytics.logEvent(
        name: 'capture_image_error',
        parameters: {'screen': 'DiseaseControlPage', 'error': e.toString()},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _diagnoseImage() async {
    if (_imageFile == null || _isProcessing || !_modelLoaded) {
      if (mounted) {
        setState(() {
          _errorMessage = _imageFile == null
              ? 'No image selected'
              : 'Processing in progress or model not loaded';
        });
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _isLoading = true;
      _prediction = 'Analyzing...';
      _confidence = '';
      _guidanceMessage = null;
    });

    try {
      await _runInference(_tempImagePath!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Diagnosis failed: $e';
          _prediction = '';
          _confidence = '';
          _guidanceMessage = null;
        });
      }
      print('Diagnose image error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (kIsWeb || _isProcessing) {
      if (mounted) {
        setState(() {
          _errorMessage = kIsWeb
              ? 'Not supported on web'
              : 'Processing in progress';
        });
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _isLoading = true;
      _prediction = 'Analyzing...';
      _confidence = '';
      _guidanceMessage = null;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _inputShape[2].toDouble(),
        maxHeight: _inputShape[1].toDouble(),
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = path.join(
          tempDir.path,
          'tomato_leaf_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await File(pickedFile.path).copy(tempPath);

        if (mounted) {
          setState(() {
            _imageFile = XFile(tempPath);
            _tempImagePath = tempPath;
          });
        }

        await _analytics.logEvent(
          name: 'select_from_gallery',
          parameters: {'screen': 'DiseaseControlPage', 'temp_path': tempPath},
        );

        await _diagnoseImage();
      } else {
        if (mounted) {
          setState(() {
            _prediction = '';
            _confidence = '';
            _guidanceMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Image selection failed: $e';
          _prediction = '';
          _confidence = '';
          _guidanceMessage = null;
        });
      }
      print('Pick image error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runInference(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Model or labels not loaded';
          _prediction = '';
          _confidence = '';
          _guidanceMessage = null;
        });
      }
      return;
    }

    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final resizedImage = img.copyResize(
        image,
        width: _inputShape[2],
        height: _inputShape[1],
      );
      final input = Float32List(
        _inputShape[1] * _inputShape[2] * _inputShape[3],
      );
      var i = 0;
      for (var y = 0; y < _inputShape[1]; y++) {
        for (var x = 0; x < _inputShape[2]; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[i++] = pixel.r / 255.0; // Normalize to [0, 1]
          input[i++] = pixel.g / 255.0;
          input[i++] = pixel.b / 255.0;
        }
      }

      final inputTensor = input.reshape(_inputShape);
      final output = List.filled(_numClasses, 0.0).reshape([1, _numClasses]);
      _interpreter!.run(inputTensor, output);

      final maxIndex = output[0].indexOf(
        output[0].reduce((a, b) => a > b ? a : b),
      );
      final confidence = output[0][maxIndex] * 100;

      if (confidence.isNaN || confidence < 0 || confidence > 100) {
        if (mounted) {
          setState(() {
            _prediction = 'Invalid result';
            _confidence = '';
            _guidanceMessage = 'Invalid confidence score. Please try again.';
          });
        }
        return;
      }

      if (confidence < 60.0) {
        if (mounted) {
          setState(() {
            _prediction = 'Unrecognized Image';
            _confidence = '';
            _guidanceMessage = 'Please capture a clear image of a tomato leaf.';
          });
        }
      } else {
        final prediction = _labels![maxIndex];
        if (mounted) {
          setState(() {
            _prediction = prediction.replaceAll('_', ' ');
            _confidence = '${confidence.toStringAsFixed(1)}%';
            _guidanceMessage = _getGuidanceMessage(prediction);
          });
        }
      }

      await _analytics.logEvent(
        name: 'inference_result',
        parameters: {
          'screen': 'DiseaseControlPage',
          'prediction': _prediction,
          'confidence': _confidence,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Analysis failed: $e';
          _prediction = '';
          _confidence = '';
          _guidanceMessage = null;
        });
      }
      print('Inference error: $e');
      await _analytics.logEvent(
        name: 'inference_error',
        parameters: {'screen': 'DiseaseControlPage', 'error': e.toString()},
      );
    }
  }

  String _getGuidanceMessage(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'tomato_early_blight':
        return 'Early Blight detected. Remove affected leaves and apply copper-based fungicides.';
      case 'tomato_healthy':
        return 'Your tomato leaf is healthy! Continue regular care.';
      case 'tomato_late_blight':
        return 'Late Blight detected. Remove affected leaves and use mancozeb fungicide.';
      case 'tomato_leaf_mold':
        return 'Leaf Mold detected. Improve air circulation and apply fungicides.';
      case 'tomato_septoria_leaf_spot':
        return 'Septoria Leaf Spot detected. Remove affected leaves and use chlorothalonil.';
      case 'tomato_spider_mites_two_spotted_spider_mite':
        return 'Spider Mites detected. Use miticides or neem oil.';
      case 'tomato_target_spot':
        return 'Target Spot detected. Apply fungicides and remove affected leaves.';
      case 'tomato_tomato_yellowleaf_curl_virus':
        return 'Yellow Leaf Curl Virus detected. Remove affected plants and control whiteflies.';
      case 'tomato_tomato_mosaic_virus':
        return 'Mosaic Virus detected. Remove affected plants and disinfect tools.';
      case 'tomato_bacterial_spot':
        return 'Bacterial Spot detected. Apply copper-based bactericides.';
      case 'pepper_bell_bacterial_spot':
        return 'Bell Pepper Bacterial Spot detected. Apply copper-based bactericides.';
      case 'pepper_bell_healthy':
        return 'Your bell pepper leaf is healthy! Continue regular care.';
      case 'potato_early_blight':
        return 'Potato Early Blight detected. Remove affected leaves and apply fungicides.';
      case 'potato_late_blight':
        return 'Potato Late Blight detected. Remove affected leaves and use mancozeb.';
      case 'potato_healthy':
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
        print('Cleanup error: $e');
      } finally {
        _tempImagePath = null;
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller?.dispose();
      _interpreter?.close();
      _captureDebounceTimer?.cancel();
    }
    _cleanupTempImage();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    print('Widget disposed');
  }

  @override
  Widget build(BuildContext context) {
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
                        child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Scan a tomato leaf to diagnose diseases',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
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
        elevation: 6,
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
            const Text(
              'Tap to start camera',
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
      child: AspectRatio(aspectRatio: 1, child: CameraPreview(_controller!)),
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
