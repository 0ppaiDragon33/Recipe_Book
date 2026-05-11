// lib/services/cloudinary_service.dart
//
// SECURITY NOTE (Week 7 — hardcoded secrets):
//   Cloudinary *unsigned* upload presets are intentionally public-facing.
//   They are designed to be used client-side with no secret key.
//   _kCloudName and _kUploadPreset are NOT secrets — they only allow
//   uploads to the specific folder/preset configured in your Cloudinary
//   dashboard. The Cloudinary API Secret (which WOULD be sensitive) is
//   never used here and never stored in the app.
//   See: https://cloudinary.com/documentation/upload_presets
//
// HOW TO CONFIGURE FOR YOUR OWN ACCOUNT:
//   1. cloudinary.com → Settings → Upload Presets → Add preset
//   2. Set Signing Mode = "Unsigned"
//   3. Replace the two constants below with your own values.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// ── Cloudinary unsigned-upload configuration ──────────────────────────────
// Public identifiers only — not secrets. See security note above.
const String _kCloudName = 'dqxa650zw';
const String _kUploadPreset = 'c7dxetlx';

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_kCloudName/image/upload');

  Future<String> uploadImage(Uint8List imageBytes) async {
    // 🔒 Add size check HERE (before creating request)
    if (imageBytes.length > 5 * 1024 * 1024) {
      throw Exception('Image too large (max 5MB)');
    }

    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _kUploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'recipe.jpg',
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Image upload failed. Please try again.');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['secure_url'] as String? ?? '';
  }
}
