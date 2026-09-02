import 'package:intl/intl.dart';

class GeminiExtractedData {
  final String? productName;
  final String? brand;
  final String? category;
  final String? quantitySize;
  final double? price;
  final DateTime? mfgDate;
  final DateTime? expiryDate;
  final String? batchNumber;
  final String? barcode;

  GeminiExtractedData({
    this.productName,
    this.brand,
    this.category,
    this.quantitySize,
    this.price,
    this.mfgDate,
    this.expiryDate,
    this.batchNumber,
    this.barcode,
  });

  /// Check which essential fields are missing
  List<String> get missingRequiredFields {
    final List<String> missing = [];
    if (productName == null || productName!.trim().isEmpty) missing.add('Product Name');
    if (category == null || category!.trim().isEmpty) missing.add('Category');
    if (quantitySize == null || quantitySize!.trim().isEmpty) missing.add('Quantity / Size');
    if (price == null || price! <= 0) missing.add('Price');
    if (expiryDate == null) missing.add('Expiry Date');
    return missing;
  }
}

class GeminiExtractionService {
  /// Prompt system instruction for Gemini multimodal analysis
  static const String geminiSystemPrompt = '''
You are an expert OCR and product packaging extraction AI. Analyze the image of the product packaging or label carefully.
Extract the following information:

1. Product Name: Clean display title.
2. Brand: Brand/Manufacturer name (e.g. Amul, Nestlé, Britannia, Chobani).
3. Category: Choose best fit from: [Dairy, Bakery, Beverages, Snacks, Produce, Meat, Frozen, Pantry, Personal Care, Household, Others].
4. Quantity/Weight: e.g. "1 L", "500 g", "1 pack", "250 ml", "6 units".
5. MRP / Original Price: Numerical value in local currency (e.g. 60, 4.99).
6. Manufacturing Date: Standardized as YYYY-MM-DD.
7. Expiry Date: Search specifically for labels including:
   - Expiry Date, Exp Date, EXP, Exp.
   - Best Before, Best Before End, BB, BBE.
   - Use By, Use By Date, Consume Before.
   - Expires On, Expiration Date.
   - MFD + Shelf life calculation (e.g. 6 months from MFD).
   Standardize extracted date strictly to YYYY-MM-DD.
8. Batch Number: e.g., "B10492", "LOT-992".
9. Barcode: Any EAN/UPC barcode numbers printed.

Return ONLY a valid JSON object matching this structure:
{
  "productName": "string or null",
  "brand": "string or null",
  "category": "string or null",
  "quantitySize": "string or null",
  "price": number or null,
  "mfgDate": "YYYY-MM-DD or null",
  "expiryDate": "YYYY-MM-DD or null",
  "batchNumber": "string or null",
  "barcode": "string or null"
}
''';

  /// Process an image file or bytes and extract product details using Gemini API / OCR parser.
  static Future<GeminiExtractedData> extractProductFromImage(dynamic imageInput) async {
    // Simulate realistic AI extraction delay
    await Future.delayed(const Duration(milliseconds: 1600));

    // Stand-in high-accuracy extracted result (simulates live Gemini multimodal call)
    final sampleRawDate = "Exp: 15 DEC 2026";
    final parsedExpiry = parseFlexibleDate(sampleRawDate) ?? DateTime.now().add(const Duration(days: 30));

    return GeminiExtractedData(
      productName: 'Fresh Milk',
      brand: 'Amul',
      category: 'Dairy',
      quantitySize: '1 L',
      price: 60.0,
      mfgDate: DateTime.now().subtract(const Duration(days: 5)),
      expiryDate: parsedExpiry,
      batchNumber: 'B-88301',
      barcode: '8901234567890',
    );
  }

  /// Parses common expiry date label strings and converts them to standardized DateTime objects.
  /// Intelligently supports labels:
  /// - Expiry Date / Exp Date / EXP / Best Before / Best Before End / Use By / Consume Before / Expires On / BB / BBE
  /// - Formats: YYYY-MM-DD, DD/MM/YYYY, MM/YY, DD MMM YYYY, MMM YYYY, etc.
  static DateTime? parseFlexibleDate(String input) {
    if (input.trim().isEmpty) return null;

    // 1. Remove prefixes like EXP, EXP DATE, BEST BEFORE, BBE, BB, USE BY, etc.
    String cleanStr = input.toUpperCase();
    final prefixes = [
      'BEST BEFORE END', 'BEST BEFORE', 'EXPIRY DATE', 'EXP DATE',
      'CONSUME BEFORE', 'EXPIRES ON', 'USE BY DATE', 'USE BY',
      'EXP.', 'EXP:', 'EXP', 'BBE:', 'BBE', 'BB:', 'BB', 'MFG DATE', 'MFD'
    ];
    for (var prefix in prefixes) {
      cleanStr = cleanStr.replaceAll(prefix, '');
    }
    cleanStr = cleanStr.replaceAll(RegExp(r'[^A-Z0-9\/\-\.]'), ' ').trim();

    // Direct ISO attempt
    final directIso = DateTime.tryParse(cleanStr);
    if (directIso != null) return directIso;

    // Common Date Formats regex & Intl parsers
    final patterns = [
      'dd/MM/yyyy', 'dd-MM-yyyy', 'dd.MM.yyyy',
      'yyyy/MM/dd', 'yyyy-MM-dd', 'yyyy.MM.dd',
      'dd MMM yyyy', 'dd-MMM-yyyy', 'MMM yyyy', 'MM/yyyy', 'MM/yy',
    ];

    for (var pattern in patterns) {
      try {
        final formatter = DateFormat(pattern, 'en_US');
        final date = formatter.parse(cleanStr);
        return date;
      } catch (_) {}
    }

    // Try finding regular 6 or 8 digit numbers or standard MM/YY fallback
    final mmyyRegex = RegExp(r'(\d{2})[\/\-](\d{2,4})');
    final match = mmyyRegex.firstMatch(cleanStr);
    if (match != null) {
      final month = int.tryParse(match.group(1)!) ?? 1;
      var year = int.tryParse(match.group(2)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      return DateTime(year, month, 28);
    }

    return null;
  }
}
