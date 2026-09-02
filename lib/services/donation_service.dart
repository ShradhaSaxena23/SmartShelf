import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// API Key Placeholders — replace with your actual keys
// ─────────────────────────────────────────────────────────────────────────────
const String _kGeminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
const String _kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class DonationCenter {
  final String name;
  final String type; // e.g. "Gaushala", "Animal Shelter", "Dairy Farm"
  final String address;
  final double distanceKm;
  final double? rating;
  final int? reviewCount;
  final String? phone;
  final double lat;
  final double lng;
  final String? placeId;

  const DonationCenter({
    required this.name,
    required this.type,
    required this.address,
    required this.distanceKm,
    this.rating,
    this.reviewCount,
    this.phone,
    required this.lat,
    required this.lng,
    this.placeId,
  });

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&query_place_id=${placeId ?? ''}&center=$lat,$lng';
}

class GeminiDonationResult {
  final bool isSuitable;
  final String reason;
  final List<String> suggestedOrgTypes;
  final bool usedAi; // false when fallback mock is used

  const GeminiDonationResult({
    required this.isSuitable,
    required this.reason,
    required this.suggestedOrgTypes,
    required this.usedAi,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class DonationService {
  static const Duration _timeout = Duration(seconds: 12);

  // ── 1. Gemini: Assess donation suitability ─────────────────────────────────

  static Future<GeminiDonationResult> assessDonationSuitability(
    ProductModel product,
  ) async {
    if (_kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      // No key → return smart mock based on category
      return _mockGeminiResult(product);
    }

    try {
      final daysExpired = product.daysRemaining.abs();
      final prompt = '''
You are a food donation advisor AI. A product has expired and the store wants to know if it can still be donated.

Product Details:
- Name: ${product.name}
- Category: ${product.category}
- Brand: ${product.brand ?? 'Unknown'}
- Quantity: ${product.quantity} units
- Days since expiry: $daysExpired days

Analyze this product and determine:
1. Is it still suitable for donation to animals or community kitchens?
2. What type of organizations should receive it?

Return ONLY a valid JSON object:
{
  "isSuitable": true or false,
  "reason": "Brief, clear reason in 1-2 sentences.",
  "suggestedOrgTypes": ["Gaushala", "Animal Shelter", "Dairy Farm", "Food Bank", "Community Kitchen"]
}

Only include organization types most relevant to this specific product.
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_kGeminiApiKey',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.2,
                'maxOutputTokens': 512,
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        // Strip markdown code fences if present
        final cleaned = text.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

        return GeminiDonationResult(
          isSuitable: parsed['isSuitable'] as bool,
          reason: parsed['reason'] as String,
          suggestedOrgTypes: List<String>.from(parsed['suggestedOrgTypes'] as List),
          usedAi: true,
        );
      }
    } catch (_) {
      // Fall through to mock
    }

    return _mockGeminiResult(product);
  }

  static GeminiDonationResult _mockGeminiResult(ProductModel product) {
    final daysExpired = product.daysRemaining.abs();
    final cat = product.category.toLowerCase();

    if (daysExpired > 14) {
      return const GeminiDonationResult(
        isSuitable: false,
        reason:
            'This product has been expired for more than 2 weeks. It is not recommended for donation to avoid health risks.',
        suggestedOrgTypes: [],
        usedAi: false,
      );
    }

    if (cat == 'dairy' || cat == 'produce' || cat == 'bakery' || cat == 'meat') {
      return GeminiDonationResult(
        isSuitable: true,
        reason:
            'Based on the product type and expiry duration, this item can still be safely used as animal feed or donated to nearby livestock shelters.',
        suggestedOrgTypes: const ['Gaushala', 'Animal Shelter', 'Dairy Farm', 'Cattle Shelter'],
        usedAi: false,
      );
    }

    if (cat == 'beverages' || cat == 'snacks' || cat == 'pantry') {
      return GeminiDonationResult(
        isSuitable: true,
        reason:
            'Packaged goods are often safe beyond their printed date. This item can be donated to food banks or community kitchens for human consumption assessment.',
        suggestedOrgTypes: const ['Food Bank', 'Community Kitchen', 'NGO'],
        usedAi: false,
      );
    }

    return GeminiDonationResult(
      isSuitable: true,
      reason:
          'This recently expired product may still be suitable for donation to local animal shelters or food recovery programs.',
      suggestedOrgTypes: const ['Animal Shelter', 'Gaushala', 'Food Bank'],
      usedAi: false,
    );
  }

  // ── 2. Google Places: Find nearby donation centers ────────────────────────

  static Future<List<DonationCenter>> findNearbyDonationCenters({
    required double latitude,
    required double longitude,
    required List<String> orgTypes,
    int radiusMeters = 10000,
  }) async {
    if (_kGooglePlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
      return _mockDonationCenters(latitude, longitude, orgTypes);
    }

    try {
      final keywords = orgTypes.join('|');
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$latitude,$longitude'
        '&radius=$radiusMeters'
        '&keyword=${Uri.encodeComponent(keywords)}'
        '&key=$_kGooglePlacesApiKey',
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;

        return results.take(6).map((place) {
          final placeMap = place as Map<String, dynamic>;
          final geo = placeMap['geometry']['location'] as Map<String, dynamic>;
          final lat = (geo['lat'] as num).toDouble();
          final lng = (geo['lng'] as num).toDouble();

          return DonationCenter(
            name: placeMap['name'] as String,
            type: _inferType(placeMap['types'] as List<dynamic>, orgTypes),
            address: (placeMap['vicinity'] ?? placeMap['formatted_address'] ?? 'Address not available') as String,
            distanceKm: _haversineDistance(latitude, longitude, lat, lng),
            rating: placeMap['rating'] != null ? (placeMap['rating'] as num).toDouble() : null,
            reviewCount: placeMap['user_ratings_total'] as int?,
            lat: lat,
            lng: lng,
            placeId: placeMap['place_id'] as String?,
          );
        }).toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      }
    } catch (_) {
      // Fall through to mock
    }

    return _mockDonationCenters(latitude, longitude, orgTypes);
  }

  static String _inferType(List<dynamic> types, List<String> preferred) {
    for (final t in preferred) {
      if (types.any((e) => e.toString().toLowerCase().contains(t.toLowerCase()))) {
        return t;
      }
    }
    if (types.contains('veterinary_care')) return 'Animal Shelter';
    if (types.contains('food')) return 'Food Bank';
    return preferred.isNotEmpty ? preferred.first : 'Donation Center';
  }

  static List<DonationCenter> _mockDonationCenters(
    double lat,
    double lng,
    List<String> orgTypes,
  ) {
    final type1 = orgTypes.isNotEmpty ? orgTypes[0] : 'Animal Shelter';
    final type2 = orgTypes.length > 1 ? orgTypes[1] : 'Gaushala';
    final type3 = orgTypes.length > 2 ? orgTypes[2] : 'Dairy Farm';

    return [
      DonationCenter(
        name: 'Shri Gopal Gaushala',
        type: type1,
        address: 'Near Railway Station, Sector 12, City',
        distanceKm: 1.2,
        rating: 4.6,
        reviewCount: 132,
        phone: '+91 98765 43210',
        lat: lat + 0.008,
        lng: lng + 0.005,
        placeId: 'mock_place_1',
      ),
      DonationCenter(
        name: 'Happy Paws Animal Shelter',
        type: type2,
        address: 'Plot 45, Green Park Colony',
        distanceKm: 2.4,
        rating: 4.2,
        reviewCount: 98,
        phone: '+91 91234 56789',
        lat: lat - 0.012,
        lng: lng + 0.010,
        placeId: 'mock_place_2',
      ),
      DonationCenter(
        name: 'Sunrise Dairy & Cattle Farm',
        type: type3,
        address: 'Village Road, Agricultural Zone',
        distanceKm: 3.1,
        rating: 4.4,
        reviewCount: 67,
        phone: '+91 88001 22334',
        lat: lat + 0.018,
        lng: lng - 0.008,
        placeId: 'mock_place_3',
      ),
      DonationCenter(
        name: 'City Food Bank & NGO',
        type: 'Food Bank',
        address: '12-B, Main Market Road, Civil Lines',
        distanceKm: 4.3,
        rating: 4.8,
        reviewCount: 211,
        phone: '+91 80000 55566',
        lat: lat - 0.020,
        lng: lng - 0.015,
        placeId: 'mock_place_4',
      ),
      DonationCenter(
        name: 'Prani Mitra Animal Care',
        type: 'Animal Shelter',
        address: 'Opp. City Park, Old Town',
        distanceKm: 5.0,
        rating: 4.1,
        reviewCount: 54,
        phone: null,
        lat: lat + 0.025,
        lng: lng + 0.020,
        placeId: 'mock_place_5',
      ),
    ]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  // ── Haversine formula for distance calculation ─────────────────────────────

  static double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const r = 6371.0; // Earth radius km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin2(dLon / 2);
    final c = 2 * _asin(_sqrt(a));
    return r * c;
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  static double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  static double _asin(double x) => x + x * x * x / 6;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double est = x / 2;
    for (int i = 0; i < 20; i++) {
      est = (est + x / est) / 2;
    }
    return est;
  }
}
