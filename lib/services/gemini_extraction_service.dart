// import 'package:intl/intl.dart';

// class GeminiExtractedData {
//   final String? productName;
//   final String? brand;
//   final String? category;
//   final String? quantitySize;
//   final double? price;
//   final DateTime? mfgDate;
//   final DateTime? expiryDate;
//   final String? batchNumber;
//   final String? barcode;

//   GeminiExtractedData({
//     this.productName,
//     this.brand,
//     this.category,
//     this.quantitySize,
//     this.price,
//     this.mfgDate,
//     this.expiryDate,
//     this.batchNumber,
//     this.barcode,
//   });

//   /// Check which essential fields are missing
//   List<String> get missingRequiredFields {
//     final List<String> missing = [];
//     if (productName == null || productName!.trim().isEmpty) missing.add('Product Name');
//     if (category == null || category!.trim().isEmpty) missing.add('Category');
//     if (quantitySize == null || quantitySize!.trim().isEmpty) missing.add('Quantity / Size');
//     if (price == null || price! <= 0) missing.add('Price');
//     if (expiryDate == null) missing.add('Expiry Date');
//     return missing;
//   }
// }

// class GeminiExtractionService {
//   /// Prompt system instruction for Gemini multimodal analysis
//   static const String geminiSystemPrompt = '''
// You are an expert OCR and product packaging extraction AI. Analyze the image of the product packaging or label carefully.
// Extract the following information:

// 1. Product Name: Clean display title.
// 2. Brand: Brand/Manufacturer name (e.g. Amul, Nestlé, Britannia, Chobani).
// 3. Category: Choose best fit from: [Dairy, Bakery, Beverages, Snacks, Produce, Meat, Frozen, Pantry, Personal Care, Household, Others].
// 4. Quantity/Weight: e.g. "1 L", "500 g", "1 pack", "250 ml", "6 units".
// 5. MRP / Original Price: Numerical value in local currency (e.g. 60, 4.99).
// 6. Manufacturing Date: Standardized as YYYY-MM-DD.
// 7. Expiry Date: Search specifically for labels including:
//    - Expiry Date, Exp Date, EXP, Exp.
//    - Best Before, Best Before End, BB, BBE.
//    - Use By, Use By Date, Consume Before.
//    - Expires On, Expiration Date.
//    - MFD + Shelf life calculation (e.g. 6 months from MFD).
//    Standardize extracted date strictly to YYYY-MM-DD.
// 8. Batch Number: e.g., "B10492", "LOT-992".
// 9. Barcode: Any EAN/UPC barcode numbers printed.

// Return ONLY a valid JSON object matching this structure:
// {
//   "productName": "string or null",
//   "brand": "string or null",
//   "category": "string or null",
//   "quantitySize": "string or null",
//   "price": number or null,
//   "mfgDate": "YYYY-MM-DD or null",
//   "expiryDate": "YYYY-MM-DD or null",
//   "batchNumber": "string or null",
//   "barcode": "string or null"
// }
// ''';

//   /// Process an image file or bytes and extract product details using Gemini API / OCR parser.
//   static Future<GeminiExtractedData> extractProductFromImage(dynamic imageInput) async {
//     // Simulate realistic AI extraction delay
//     await Future.delayed(const Duration(milliseconds: 1600));

//     // Stand-in high-accuracy extracted result (simulates live Gemini multimodal call)
//     final sampleRawDate = "Exp: 15 DEC 2026";
//     final parsedExpiry = parseFlexibleDate(sampleRawDate) ?? DateTime.now().add(const Duration(days: 30));

//     return GeminiExtractedData(
//       productName: 'Fresh Milk',
//       brand: 'Amul',
//       category: 'Dairy',
//       quantitySize: '1 L',
//       price: 60.0,
//       mfgDate: DateTime.now().subtract(const Duration(days: 5)),
//       expiryDate: parsedExpiry,
//       batchNumber: 'B-88301',
//       barcode: '8901234567890',
//     );
//   }

//   /// Parses common expiry date label strings and converts them to standardized DateTime objects.
//   /// Intelligently supports labels:
//   /// - Expiry Date / Exp Date / EXP / Best Before / Best Before End / Use By / Consume Before / Expires On / BB / BBE
//   /// - Formats: YYYY-MM-DD, DD/MM/YYYY, MM/YY, DD MMM YYYY, MMM YYYY, etc.
//   static DateTime? parseFlexibleDate(String input) {
//     if (input.trim().isEmpty) return null;

//     // 1. Remove prefixes like EXP, EXP DATE, BEST BEFORE, BBE, BB, USE BY, etc.
//     String cleanStr = input.toUpperCase();
//     final prefixes = [
//       'BEST BEFORE END', 'BEST BEFORE', 'EXPIRY DATE', 'EXP DATE',
//       'CONSUME BEFORE', 'EXPIRES ON', 'USE BY DATE', 'USE BY',
//       'EXP.', 'EXP:', 'EXP', 'BBE:', 'BBE', 'BB:', 'BB', 'MFG DATE', 'MFD'
//     ];
//     for (var prefix in prefixes) {
//       cleanStr = cleanStr.replaceAll(prefix, '');
//     }
//     cleanStr = cleanStr.replaceAll(RegExp(r'[^A-Z0-9\/\-\.]'), ' ').trim();

//     // Direct ISO attempt
//     final directIso = DateTime.tryParse(cleanStr);
//     if (directIso != null) return directIso;

//     // Common Date Formats regex & Intl parsers
//     final patterns = [
//       'dd/MM/yyyy', 'dd-MM-yyyy', 'dd.MM.yyyy',
//       'yyyy/MM/dd', 'yyyy-MM-dd', 'yyyy.MM.dd',
//       'dd MMM yyyy', 'dd-MMM-yyyy', 'MMM yyyy', 'MM/yyyy', 'MM/yy',
//     ];

//     for (var pattern in patterns) {
//       try {
//         final formatter = DateFormat(pattern, 'en_US');
//         final date = formatter.parse(cleanStr);
//         return date;
//       } catch (_) {}
//     }

//     // Try finding regular 6 or 8 digit numbers or standard MM/YY fallback
//     final mmyyRegex = RegExp(r'(\d{2})[\/\-](\d{2,4})');
//     final match = mmyyRegex.firstMatch(cleanStr);
//     if (match != null) {
//       final month = int.tryParse(match.group(1)!) ?? 1;
//       var year = int.tryParse(match.group(2)!) ?? DateTime.now().year;
//       if (year < 100) year += 2000;
//       return DateTime(year, month, 28);
//     }

//     return null;
//   }
// }

// version 2- firebase ai

// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:firebase_ai/firebase_ai.dart';

// class ExtractedProduct {
//   final String productName;
//   final String brand;
//   final String category;
//   final String quantitySize;
//   final double originalPrice;
//   final String batchNumber;
//   final String expiryDate;

//   ExtractedProduct({
//     required this.productName,
//     required this.brand,
//     required this.category,
//     required this.quantitySize,
//     required this.originalPrice,
//     required this.batchNumber,
//     required this.expiryDate,
//   });

//   factory ExtractedProduct.fromJson(Map<String, dynamic> json) {
//     return ExtractedProduct(
//       productName: json['productName'] ?? '',
//       brand: json['brand'] ?? '',
//       category: json['category'] ?? 'Other',
//       quantitySize: json['quantitySize'] ?? '',
//       originalPrice:
//           (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
//       batchNumber: json['batchNumber'] ?? '',
//       expiryDate: json['expiryDate'] ?? '',
//     );
//   }
// }

// class GeminiExtractionService {

//   static final GenerativeModel _model =
//       FirebaseAI.googleAI().generativeModel(
//     model: 'gemini-3.5-flash',
//   );

//   static Future<ExtractedProduct?> extractProductFromImage(
//     Uint8List imageBytes, {
//     String mimeType = 'image/jpeg',
//   }) async {

//     const prompt = '''
// Analyze the provided product image and extract packaging information.

// Respond ONLY with a raw JSON object matching this schema:

// {
//   "productName": "Full item name",
//   "brand": "Brand or manufacturer name",
//   "category": "Best fit from: Dairy & Eggs, Bakery & Bread, Fruits & Vegetables, Meat & Seafood, Beverages, Pantry & Staples, Snacks & Confectionery, Frozen Foods, Personal Care, Household Items, Other",
//   "quantitySize": "Net weight/volume e.g. 1 L, 500 g",
//   "originalPrice": 0.0,
//   "batchNumber": "Batch code or Lot identifier if visible",
//   "expiryDate": "YYYY-MM-DD"
// }

// If a field cannot be determined from the image, use an empty string.
// For originalPrice, use 0.0 if it cannot be determined.
// ''';

//     try {
//       final response = await _model.generateContent([
//         Content.multi([
//           TextPart(prompt),
//           InlineDataPart(mimeType, imageBytes),
//         ]),
//       ]);

//       final text = response.text ?? '';

//       final cleaned = text
//           .replaceAll('```json', '')
//           .replaceAll('```', '')
//           .trim();

//       if (cleaned.isEmpty) {
//         return null;
//       }

//       final Map<String, dynamic> jsonMap = jsonDecode(cleaned);

//       return ExtractedProduct.fromJson(jsonMap);

//     } catch (e) {
//       print('Gemini Extraction Error: $e');
//       return null;
//     }
//   }
// }

//  version 3 - gemini api

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