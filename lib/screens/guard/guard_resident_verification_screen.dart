import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../services/face_recognition_service.dart';
import '../../services/mock_data_service.dart';

class GuardResidentVerificationScreen extends StatefulWidget {
  const GuardResidentVerificationScreen({super.key});

  @override
  State<GuardResidentVerificationScreen> createState() => _GuardResidentVerificationScreenState();
}

class _GuardResidentVerificationScreenState extends State<GuardResidentVerificationScreen> {
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
  
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();
  
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Ask resident to position their face in the frame';
  bool _faceDetected = false;
  int? _matchScore;
  String? _matchedEmail;
  Map<String, dynamic>? _matchedUserData;

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

  Future<void> _captureAndVerifyResident() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Scanning for resident...';
    });

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      
      // Detect face in captured image
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

      // Get all registered residents
      final residents = MockDataService.getResidents();
      
      if (residents.isEmpty) {
        setState(() {
          _statusMessage = 'No registered residents found';
          _isProcessing = false;
        });
        _showErrorDialog('No Residents', 'No residents have registered in the system yet.');
        return;
      }

      // Try to match with each registered resident
      int bestScore = 0;
      String? bestMatch;
      
      for (var resident in residents) {
        final score = await _faceRecognitionService.verifyFace(
          capturedImagePath: image.path,
          userType: 'resident',
          userEmail: resident.email,
        );
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = resident.email;
        }
      }

      setState(() {
        _matchScore = bestScore;
        _matchedEmail = bestMatch;
        _faceDetected = true;
        _isProcessing = false;
      });

      // Get matched user data if verification successful
      if (bestScore >= 70 && bestMatch != null) {
        _matchedUserData = residents.firstWhere((r) => r.email == bestMatch).toMap();
      }

      // Clean up captured image
      final capturedFile = File(image.path);
      if (await capturedFile.exists()) {
        await capturedFile.delete();
      }

      // Show result
      _showVerificationResult(bestScore, _matchedUserData);
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Error verifying face. Please try again.';
        _faceDetected = false;
        _isProcessing = false;
      });
    }
  }

  void _showVerificationResult(int matchScore, Map<String, dynamic>? userData) {
    final isVerified = matchScore >= 70;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.cancel,
              color: isVerified ? Colors.green : Colors.red,
              size: 32,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                isVerified ? 'Resident Verified' : 'Not Recognized',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Match Score: $matchScore%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.green : Colors.red,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                isVerified
                    ? 'The person is a registered resident. You may allow entry.'
                    : 'Face not recognized. This person may not be a registered resident.',
                style: TextStyle(fontSize: 14),
              ),
              if (!isVerified) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verify identity manually',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isVerified && userData != null) ...[
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Text('Resident Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _buildDetailRow('Name', userData['name'] ?? 'N/A'),
                _buildDetailRow('Email', userData['email'] ?? 'N/A'),
                _buildDetailRow('Flat/Unit', userData['flat'] ?? 'N/A'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Entry Approved',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!isVerified)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualVerificationDialog();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text('Manual Verify'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset state for next verification
              setState(() {
                _matchScore = null;
                _matchedEmail = null;
                _matchedUserData = null;
                _faceDetected = false;
                _statusMessage = 'Ask resident to position their face in the frame';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isVerified ? Colors.green : Colors.grey,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showManualVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please verify the resident\'s identity manually:'),
            SizedBox(height: 16),
            Text('• Check physical ID card'),
            Text('• Verify flat/unit number'),
            Text('• Contact resident if needed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
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
        title: const Text('Verify Resident'),
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
                      color: _faceDetected && _matchScore != null
                          ? (_matchScore! >= 70 ? Colors.green : Colors.red)
                          : Colors.black87,
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
                
                // Scan button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _captureAndVerifyResident,
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
                                Icon(Icons.face_unlock_outlined, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Scan Face',
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
                        _buildInstruction('Ask resident to look at camera'),
                        _buildInstruction('Ensure face is well lit'),
                        _buildInstruction('Keep face centered in frame'),
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

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceFrameOverlay() {
    return CustomPaint(
      painter: FaceFramePainter(faceDetected: _faceDetected, matchScore: _matchScore),
      child: Container(),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  final bool faceDetected;
  final int? matchScore;
  
  FaceFramePainter({required this.faceDetected, this.matchScore});
  
  @override
  void paint(Canvas canvas, Size size) {
    Color frameColor;
    if (matchScore != null) {
      frameColor = matchScore! >= 70 ? Colors.green : Colors.red;
    } else {
      frameColor = faceDetected ? Colors.yellow : Colors.white;
    }
    
    final paint = Paint()
      ..color = frameColor
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
      ..color = frameColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLength), Offset(rect.left, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cornerLength, rect.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.top), Offset(rect.right, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength), Offset(rect.left, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cornerLength, rect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.bottom), Offset(rect.right, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
