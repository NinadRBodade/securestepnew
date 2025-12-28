import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../../utils/constants.dart';

class AgentFaceRegistrationScreen extends StatefulWidget {
  final String agentEmail;
  
  const AgentFaceRegistrationScreen({super.key, required this.agentEmail});

  @override
  State<AgentFaceRegistrationScreen> createState() => _AgentFaceRegistrationScreenState();
}

class _AgentFaceRegistrationScreenState extends State<AgentFaceRegistrationScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Position your face in the frame';
  bool _faceDetected = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed';
      });
    }
  }

  Future<void> _captureAndAnalyzeFace() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing face...';
    });

    try {
      final image = await _cameraController!.takePicture();
      
      // Detect face
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _statusMessage = 'No face detected. Please try again.';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          _statusMessage = 'Multiple faces detected. Please ensure only one person.';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      final face = faces.first;
      
      // Quality checks
      if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 20) {
        setState(() {
          _statusMessage = 'Please look straight at the camera';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 15) {
        setState(() {
          _statusMessage = 'Please keep your head straight';
          _faceDetected = false;
          _isProcessing = false;
        });
        return;
      }

      // Face detected successfully
      print('✅ Face detected, saving locally...');
      await _saveFaceImage(image.path);
      print('✅ Local save complete, uploading to backend...');
      await _uploadFaceToBackend(image.path);
      print('✅ Face registration process complete');
      
      setState(() {
        _statusMessage = 'Face captured successfully! ✓';
        _faceDetected = true;
        _capturedImagePath = image.path;
      });

      // Show success dialog
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        _showSuccessDialog();
      }
      
    } catch (e) {
      print('❌ Face registration error: $e');
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _faceDetected = false;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveFaceImage(String imagePath) async {
    try {
      print('💾 Saving face image locally...');
      final directory = await getApplicationDocumentsDirectory();
      print('   App directory: ${directory.path}');
      final facesDir = Directory('${directory.path}/agent_faces');
      
      if (!await facesDir.exists()) {
        print('   Creating agent_faces directory...');
        await facesDir.create(recursive: true);
      }

      final fileName = '${widget.agentEmail.replaceAll('@', '_at_')}.jpg';
      final savedPath = path.join(facesDir.path, fileName);
      print('   Saving to: $savedPath');
      
      await File(imagePath).copy(savedPath);
      print('   ✅ Local save successful');
    } catch (e) {
      print('   ❌ Local save failed: $e');
      throw Exception('Failed to save face image: $e');
    }
  }

  Future<void> _uploadFaceToBackend(String imagePath) async {
    try {
      print('📤 Uploading face to backend...');
      print('   URL: ${AppConstants.baseUrl}/api/face/upload');
      print('   Email: ${widget.agentEmail}');
      print('   Image path: $imagePath');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/face/upload'),
      );

      request.fields['email'] = widget.agentEmail;
      request.fields['role'] = 'agent';

      request.files.add(await http.MultipartFile.fromPath(
        'faceImage',
        imagePath,
      ));

      print('   Sending request...');
      var response = await request.send().timeout(Duration(seconds: 30));
      print('   Response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        print('   ❌ Upload failed: $responseBody');
        throw Exception('Backend upload failed: ${response.statusCode}');
      } else {
        final responseBody = await response.stream.bytesToString();
        print('   ✅ Upload successful: $responseBody');
      }
    } catch (e) {
      print('   ❌ Upload error: $e');
      throw Exception('Failed to upload to backend: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Registration Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your face has been registered successfully!'),
            SizedBox(height: 16),
            Text(
              'Residents can now verify your identity using face recognition.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to agent home
            },
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Register Face'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                
                // Face frame overlay
                _buildFaceFrameOverlay(),
                
                // Status message
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _faceDetected ? Colors.green : Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Capture button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _captureAndAnalyzeFace,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Capture Face',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildInstruction('Look directly at the camera'),
                        _buildInstruction('Keep your face in the frame'),
                        _buildInstruction('Ensure good lighting'),
                        _buildInstruction('Remove glasses if possible'),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _buildFaceFrameOverlay() {
    return CustomPaint(
      painter: FaceFramePainter(faceDetected: _faceDetected),
      child: Container(),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  final bool faceDetected;
  
  FaceFramePainter({required this.faceDetected});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(20));
    canvas.drawRRect(rrect, paint);

    // Draw corners
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(Offset(rect.left, rect.top + cornerLength), Offset(rect.left, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(rect.right - cornerLength, rect.top), Offset(rect.right, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength), Offset(rect.left, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(rect.right - cornerLength, rect.bottom), Offset(rect.right, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
