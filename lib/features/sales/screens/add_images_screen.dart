import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

import '../../../config/api/api_services.dart';
import '../../../config/constants/url_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../models/lead_model.dart';

class AddImagesScreen extends StatefulWidget {
  const AddImagesScreen({super.key, required this.lead});
  final LeadModel lead;

  @override
  State<AddImagesScreen> createState() => _AddImagesScreenState();
}

class _AddImagesScreenState extends State<AddImagesScreen> {
  late LeadModel _currentLead;
  final ImagePicker _imagePicker = ImagePicker();
  final ApiServices _apiServices = ApiServices();
  bool _isLoading = false;

  // ─────────────────────────────────────────
  // TODO: Jab backend developer link de,
  // sirf UrlConstants.uploadLocationPhotoUrl
  // wali line url_constants.dart mein update karo.
  // Yahan kuch nahi badalna padega!
  // ─────────────────────────────────────────

  /// Backend par Photo + Location upload karta hai
  Future<void> _uploadToBackend({
    required String imagePath,
    required double latitude,
    required double longitude,
    required String locationAddress,
  }) async {
    setState(() => _isLoading = true);
    try {
      final multipartFile = await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      );

      final response = await _apiServices.postMultipartFormData(
        UrlConstants.uploadLocationUrl, // ← sirf yeh path badlega jab backend link aaye
        fields: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'location': locationAddress,
          'employee_id': _currentLead.id ?? 'unknown',
        },
        files: [
          MapEntry('file', multipartFile),
        ],
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo aur Location backend par save ho gayi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentLead = widget.lead;
  }

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location permission in app settings')));
      }
      await Geolocator.openAppSettings();
      return false;
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        double? latitude;
        double? longitude;
        String locationStr = '';
        bool hasPermission = await _ensureLocationPermission();
        if (hasPermission) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            latitude = position.latitude;
            longitude = position.longitude;
          try {
             List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
             if (placemarks.isNotEmpty) {
               Placemark place = placemarks[0];
               locationStr = '${place.street ?? ""}, ${place.locality ?? ""}'.replaceAll(RegExp(r'^, |,$'), '').trim();
               if (locationStr == ',') locationStr = 'Unknown Location';
             }
          } catch (e) {
             locationStr = '${position.latitude}, ${position.longitude}';
          }
        } catch (e) {
          locationStr = 'Location unavailable';
        }
        } else {
          locationStr = 'Location permission denied';
        }

        final savedString = locationStr.isNotEmpty ? '${pickedFile.path}|$locationStr' : pickedFile.path;

        // Add the image path to the lead's document images
        final updatedDocumentPaths = List<String>.from(_currentLead.documentImagePaths)..add(savedString);
        final updatedLead = _currentLead.copyWith(documentImagePaths: updatedDocumentPaths);

        // Local database mein save karo
        await updatedLead.save();

        setState(() {
          _currentLead = updatedLead;
          _isLoading = false;
        });

        // Backend par bhi upload karo (agar location mili ho)
        if (latitude != null && longitude != null) {
          await _uploadToBackend(
            imagePath: pickedFile.path,
            latitude: latitude,
            longitude: longitude,
            locationAddress: locationStr,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image added successfully')));
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _viewImage(String imagePath, String? locationStr) async {
    // You can implement full-screen image viewer here
    // For now, showing a simple dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.contain),
                ),
              ),
              if (locationStr != null && locationStr.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationStr,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteImage(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Image'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedDocumentPaths = List<String>.from(_currentLead.documentImagePaths);
        final rawPath = updatedDocumentPaths[index];
        final parts = rawPath.split('|');
        final imagePath = parts[0];

        // Delete the file from device storage (optional)
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }

        updatedDocumentPaths.removeAt(index);

        final updatedLead = _currentLead.copyWith(documentImagePaths: updatedDocumentPaths);

        await updatedLead.save();

        setState(() {
          _currentLead = updatedLead;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image deleted successfully')));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting image: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImages = _currentLead.documentImagePaths.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: AppUtils.gradientFlexibleSpace(),
        title: const Text('Documents'),
        actions: [IconButton(onPressed: _showImageSourceDialog, icon: const Icon(Icons.add))],
      ),
      body: Stack(
        children: [
          if (hasImages)
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _currentLead.documentImagePaths.length,
              itemBuilder: (context, index) {
                final rawPath = _currentLead.documentImagePaths[index];
                final parts = rawPath.split('|');
                final imagePath = parts[0];
                final locationStr = parts.length > 1 ? parts[1] : null;

                return GestureDetector(
                  onTap: () => _viewImage(imagePath, locationStr),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  Text('Failed to load', style: TextStyle(color: Colors.black)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (locationStr != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    locationStr,
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: () => _deleteImage(index),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No documents added yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tap the + button to add images', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
