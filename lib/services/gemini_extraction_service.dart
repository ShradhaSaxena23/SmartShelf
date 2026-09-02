

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ExtractedProduct {
  final String productName;
  final String brand;
  final String category;
  final String quantitySize;
  final double originalPrice;
  final String batchNumber;
  final String expiryDate;

  ExtractedProduct({
    required this.productName,
    required this.brand,
    required this.category,
    required this.quantitySize,
    required this.originalPrice,
    required this.batchNumber,
    required this.expiryDate,
  });

  factory ExtractedProduct.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExtractedProduct(
      productName:
          json['productName'] ?? '',

      brand:
          json['brand'] ?? '',

      category:
          json['category'] ?? 'Other',

      quantitySize:
          json['quantitySize'] ?? '',

      originalPrice:
          (json['originalPrice'] as num?)
                  ?.toDouble() ??
              0.0,

      batchNumber:
          json['batchNumber'] ?? '',

      expiryDate:
          json['expiryDate'] ?? '',
    );
  }
}

class GeminiExtractionService {
  static const String _functionUrl =
      'https://asia-south2-smartshelf-4b145.cloudfunctions.net/extractGemini';

  static Future<ExtractedProduct?> extractProductFromImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        print(
          'Gemini Extraction Error: User is not logged in.',
        );

        return null;
      }

      /*
       * Get a fresh Firebase ID token.
       *
       * The Cloud Function uses this token to verify
       * that the request is coming from an authenticated
       * SmartShelf user.
       */
      final idToken =
          await user.getIdToken(true);

      if (idToken == null ||
          idToken.isEmpty) {
        print(
          'Gemini Extraction Error: Could not obtain Firebase ID token.',
        );

        return null;
      }

      /*
       * Convert image bytes to Base64.
       */
      final imageBase64 =
          base64Encode(imageBytes);

      /*
       * Send image to our Cloud Function.
       */
      final response = await http.post(
        Uri.parse(_functionUrl),

        headers: {
          'Content-Type':
              'application/json',

          'Authorization':
              'Bearer $idToken',
        },

        body: jsonEncode({
          'imageBase64': imageBase64,
          'mimeType': mimeType,
        }),
      );

      print(
        'Gemini Cloud Function status: ${response.statusCode}',
      );

      /*
       * Handle successful response.
       */
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body);

        if (responseData['success'] != true) {
          print(
            'Gemini Extraction Error: '
            '${responseData['error']}',
          );

          return null;
        }

        final productData =
            responseData['product'];

        if (productData is! Map) {
          print(
            'Gemini Extraction Error: Invalid product response.',
          );

          return null;
        }

        return ExtractedProduct.fromJson(
          Map<String, dynamic>.from(
            productData,
          ),
        );
      }

      /*
       * Handle Gemini quota/rate-limit errors.
       */
      if (response.statusCode == 429) {
        try {
          final errorData =
              jsonDecode(response.body);

          print(
            'Gemini Extraction Error: '
            '${errorData['error'] ?? 'Gemini quota exceeded.'}',
          );
        } catch (_) {
          print(
            'Gemini Extraction Error: Gemini quota exceeded.',
          );
        }

        return null;
      }

      /*
       * Handle authentication errors.
       */
      if (response.statusCode == 401) {
        print(
          'Gemini Extraction Error: '
          'Authentication failed.',
        );

        return null;
      }

      /*
       * Handle all other errors.
       */
      try {
        final errorData =
            jsonDecode(response.body);

        print(
          'Gemini Extraction Error: '
          '${errorData['error'] ?? response.body}',
        );
      } catch (_) {
        print(
          'Gemini Extraction Error: '
          '${response.body}',
        );
      }

      return null;

    } catch (e) {
      print(
        'Gemini Extraction Error: $e',
      );

      return null;
    }
  }
}