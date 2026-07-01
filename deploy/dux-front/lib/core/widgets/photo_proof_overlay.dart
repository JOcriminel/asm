import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoProofOverlay {
  static Future<String?> show(BuildContext context) async {
    // Request/Check camera permission first
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final reqStatus = await Permission.camera.request();
      if (!reqStatus.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez accorder la permission d\'utiliser l\'appareil photo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    }

    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) return null;
      
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur appareil photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
