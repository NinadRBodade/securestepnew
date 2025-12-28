import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AgentDocumentUploadScreen extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String agentEmail;
  final String agentPhone;

  const AgentDocumentUploadScreen({
    Key? key,
    required this.agentId,
    required this.agentName,
    required this.agentEmail,
    required this.agentPhone,
  }) : super(key: key);

  @override
  State<AgentDocumentUploadScreen> createState() => _AgentDocumentUploadScreenState();
}

class _AgentDocumentUploadScreenState extends State<AgentDocumentUploadScreen> {
  // For mobile platforms
  File? _idProof;
  File? _photo;
  File? _certificate;
  
  // For web platform
  Uint8List? _idProofBytes;
  Uint8List? _photoBytes;
  Uint8List? _certificateBytes;
  String? _idProofName;
  String? _photoName;
  String? _certificateName;
  
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickIdProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb, // Get bytes on web
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _idProofBytes = result.files.single.bytes;
          _idProofName = result.files.single.name;
        } else {
          _idProof = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    if (kIsWeb) {
      // On web, use file picker instead of camera
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      
      if (result != null) {
        setState(() {
          _photoBytes = result.files.single.bytes;
          _photoName = result.files.single.name;
        });
      }
    } else {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _photo = File(image.path);
        });
      }
    }
  }

  Future<void> _pickCertificate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb, // Get bytes on web
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _certificateBytes = result.files.single.bytes;
          _certificateName = result.files.single.name;
        } else {
          _certificate = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _uploadDocuments() async {
    // Check if all documents are selected (for both web and mobile)
    bool hasAllDocuments = kIsWeb
        ? (_idProofBytes != null && _photoBytes != null && _certificateBytes != null)
        : (_idProof != null && _photo != null && _certificate != null);
        
    if (!hasAllDocuments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/agent/register'),
      );

      request.fields['agentId'] = widget.agentId;
      request.fields['name'] = widget.agentName;
      request.fields['email'] = widget.agentEmail;
      request.fields['phone'] = widget.agentPhone;

      // Add files - handle both web and mobile
      if (kIsWeb) {
        // Web platform - use bytes
        String? idProofMimeType = lookupMimeType(_idProofName!);
        request.files.add(http.MultipartFile.fromBytes(
          'idProof',
          _idProofBytes!,
          filename: _idProofName,
          contentType: idProofMimeType != null ? MediaType.parse(idProofMimeType) : null,
        ));

        String? photoMimeType = lookupMimeType(_photoName!);
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          _photoBytes!,
          filename: _photoName,
          contentType: photoMimeType != null ? MediaType.parse(photoMimeType) : null,
        ));

        String? certMimeType = lookupMimeType(_certificateName!);
        request.files.add(http.MultipartFile.fromBytes(
          'certificate',
          _certificateBytes!,
          filename: _certificateName,
          contentType: certMimeType != null ? MediaType.parse(certMimeType) : null,
        ));
      } else {
        // Mobile platform - use file paths
        String? idProofMimeType = lookupMimeType(_idProof!.path);
        request.files.add(await http.MultipartFile.fromPath(
          'idProof',
          _idProof!.path,
          contentType: idProofMimeType != null ? MediaType.parse(idProofMimeType) : null,
        ));

        String? photoMimeType = lookupMimeType(_photo!.path);
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          _photo!.path,
          contentType: photoMimeType != null ? MediaType.parse(photoMimeType) : null,
        ));

        String? certMimeType = lookupMimeType(_certificate!.path);
        request.files.add(await http.MultipartFile.fromPath(
          'certificate',
          _certificate!.path,
          contentType: certMimeType != null ? MediaType.parse(certMimeType) : null,
        ));
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        // Show popup dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Documents Submitted'),
                ],
              ),
              content: const Text(
                'Documents submitted to admin for verification. Please wait.\n\nYour QR code will be available after admin approval.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(true); // Go back to dashboard
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonData['error'] ?? 'Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onPick,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.green : Colors.grey,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isSelected ? 'Selected' : subtitle),
        trailing: ElevatedButton(
          onPressed: onPick,
          child: Text(isSelected ? 'Change' : 'Select'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 10),
                      const Text(
                        'Required Documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Valid Government ID Proof (PDF/Image)'),
                  const Text('2. Recent Photograph'),
                  const Text('3. Qualification/Training Certificate'),
                  const SizedBox(height: 10),
                  const Text(
                    'After submission, your documents will be reviewed by an admin.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Document Upload Cards
            _buildDocumentCard(
              title: 'ID Proof',
              subtitle: 'Upload government ID',
              isSelected: kIsWeb ? _idProofBytes != null : _idProof != null,
              onPick: _pickIdProof,
              icon: Icons.credit_card,
            ),

            const SizedBox(height: 15),

            _buildDocumentCard(
              title: 'Photograph',
              subtitle: kIsWeb ? 'Select a photo' : 'Take a photo',
              isSelected: kIsWeb ? _photoBytes != null : _photo != null,
              onPick: _pickPhoto,
              icon: Icons.photo_camera,
            ),

            const SizedBox(height: 15),

            _buildDocumentCard(
              title: 'Certificate',
              subtitle: 'Upload certificate',
              isSelected: kIsWeb ? _certificateBytes != null : _certificate != null,
              onPick: _pickCertificate,
              icon: Icons.description,
            ),

            const SizedBox(height: 40),

            // Upload Button
            CustomButton(
              text: _isUploading ? 'Uploading...' : 'Submit Documents',
              onPressed: _isUploading ? () {} : _uploadDocuments,              color: Theme.of(context).primaryColor,            ),

            const SizedBox(height: 20),

            // Status indicator
            if (_isUploading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Uploading documents...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
