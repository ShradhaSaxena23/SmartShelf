// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/product_model.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // API Key Placeholders — replace with your actual keys
// // ─────────────────────────────────────────────────────────────────────────────
// const String _kGeminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
// const String _kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

// // ─────────────────────────────────────────────────────────────────────────────
// // Models
// // ─────────────────────────────────────────────────────────────────────────────

// class DonationCenter {
//   final String name;
//   final String type; // e.g. "Gaushala", "Animal Shelter", "Dairy Farm"
//   final String address;
//   final double distanceKm;
//   final double? rating;
//   final int? reviewCount;
//   final String? phone;
//   final double lat;
//   final double lng;
//   final String? placeId;

//   const DonationCenter({
//     required this.name,
//     required this.type,
//     required this.address,
//     required this.distanceKm,
//     this.rating,
//     this.reviewCount,
//     this.phone,
//     required this.lat,
//     required this.lng,
//     this.placeId,
//   });

//   String get googleMapsUrl =>
//       'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&query_place_id=${placeId ?? ''}&center=$lat,$lng';
// }

// class GeminiDonationResult {
//   final bool isSuitable;
//   final String reason;
//   final List<String> suggestedOrgTypes;
//   final bool usedAi; // false when fallback mock is used

//   const GeminiDonationResult({
//     required this.isSuitable,
//     required this.reason,
//     required this.suggestedOrgTypes,
//     required this.usedAi,
//   });
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Service
// // ─────────────────────────────────────────────────────────────────────────────

// class DonationService {
//   static const Duration _timeout = Duration(seconds: 12);

//   // ── 1. Gemini: Assess donation suitability ─────────────────────────────────

//   static Future<GeminiDonationResult> assessDonationSuitability(
//     ProductModel product,
//   ) async {
//     if (_kGeminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
//       // No key → return smart mock based on category
//       return _mockGeminiResult(product);
//     }

//     try {
//       final daysExpired = product.daysRemaining.abs();
//       final prompt = '''
// You are a food donation advisor AI. A product has expired and the store wants to know if it can still be donated.

// Product Details:
// - Name: ${product.name}
// - Category: ${product.category}
// - Brand: ${product.brand ?? 'Unknown'}
// - Quantity: ${product.quantity} units
// - Days since expiry: $daysExpired days

// Analyze this product and determine:
// 1. Is it still suitable for donation to animals or community kitchens?
// 2. What type of organizations should receive it?

// Return ONLY a valid JSON object:
// {
//   "isSuitable": true or false,
//   "reason": "Brief, clear reason in 1-2 sentences.",
//   "suggestedOrgTypes": ["Gaushala", "Animal Shelter", "Dairy Farm", "Food Bank", "Community Kitchen"]
// }

// Only include organization types most relevant to this specific product.
// ''';

//       final url = Uri.parse(
//         'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_kGeminiApiKey',
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               'contents': [
//                 {
//                   'parts': [
//                     {'text': prompt}
//                   ]
//                 }
//               ],
//               'generationConfig': {
//                 'temperature': 0.2,
//                 'maxOutputTokens': 512,
//               },
//             }),
//           )
//           .timeout(_timeout);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as Map<String, dynamic>;
//         final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
//         // Strip markdown code fences if present
//         final cleaned = text.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();
//         final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

//         return GeminiDonationResult(
//           isSuitable: parsed['isSuitable'] as bool,
//           reason: parsed['reason'] as String,
//           suggestedOrgTypes: List<String>.from(parsed['suggestedOrgTypes'] as List),
//           usedAi: true,
//         );
//       }
//     } catch (_) {
//       // Fall through to mock
//     }

//     return _mockGeminiResult(product);
//   }

//   static GeminiDonationResult _mockGeminiResult(ProductModel product) {
//     final daysExpired = product.daysRemaining.abs();
//     final cat = product.category.toLowerCase();

//     if (daysExpired > 14) {
//       return const GeminiDonationResult(
//         isSuitable: false,
//         reason:
//             'This product has been expired for more than 2 weeks. It is not recommended for donation to avoid health risks.',
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     if (cat == 'dairy' || cat == 'produce' || cat == 'bakery' || cat == 'meat') {
//       return GeminiDonationResult(
//         isSuitable: true,
//         reason:
//             'Based on the product type and expiry duration, this item can still be safely used as animal feed or donated to nearby livestock shelters.',
//         suggestedOrgTypes: const ['Gaushala', 'Animal Shelter', 'Dairy Farm', 'Cattle Shelter'],
//         usedAi: false,
//       );
//     }

//     if (cat == 'beverages' || cat == 'snacks' || cat == 'pantry') {
//       return GeminiDonationResult(
//         isSuitable: true,
//         reason:
//             'Packaged goods are often safe beyond their printed date. This item can be donated to food banks or community kitchens for human consumption assessment.',
//         suggestedOrgTypes: const ['Food Bank', 'Community Kitchen', 'NGO'],
//         usedAi: false,
//       );
//     }

//     return GeminiDonationResult(
//       isSuitable: true,
//       reason:
//           'This recently expired product may still be suitable for donation to local animal shelters or food recovery programs.',
//       suggestedOrgTypes: const ['Animal Shelter', 'Gaushala', 'Food Bank'],
//       usedAi: false,
//     );
//   }

//   // ── 2. Google Places: Find nearby donation centers ────────────────────────

//   static Future<List<DonationCenter>> findNearbyDonationCenters({
//     required double latitude,
//     required double longitude,
//     required List<String> orgTypes,
//     int radiusMeters = 10000,
//   }) async {
//     if (_kGooglePlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
//       return _mockDonationCenters(latitude, longitude, orgTypes);
//     }

//     try {
//       final keywords = orgTypes.join('|');
//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
//         '?location=$latitude,$longitude'
//         '&radius=$radiusMeters'
//         '&keyword=${Uri.encodeComponent(keywords)}'
//         '&key=$_kGooglePlacesApiKey',
//       );

//       final response = await http.get(url).timeout(_timeout);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as Map<String, dynamic>;
//         final results = data['results'] as List<dynamic>;

//         return results.take(6).map((place) {
//           final placeMap = place as Map<String, dynamic>;
//           final geo = placeMap['geometry']['location'] as Map<String, dynamic>;
//           final lat = (geo['lat'] as num).toDouble();
//           final lng = (geo['lng'] as num).toDouble();

//           return DonationCenter(
//             name: placeMap['name'] as String,
//             type: _inferType(placeMap['types'] as List<dynamic>, orgTypes),
//             address: (placeMap['vicinity'] ?? placeMap['formatted_address'] ?? 'Address not available') as String,
//             distanceKm: _haversineDistance(latitude, longitude, lat, lng),
//             rating: placeMap['rating'] != null ? (placeMap['rating'] as num).toDouble() : null,
//             reviewCount: placeMap['user_ratings_total'] as int?,
//             lat: lat,
//             lng: lng,
//             placeId: placeMap['place_id'] as String?,
//           );
//         }).toList()
//           ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
//       }
//     } catch (_) {
//       // Fall through to mock
//     }

//     return _mockDonationCenters(latitude, longitude, orgTypes);
//   }

//   static String _inferType(List<dynamic> types, List<String> preferred) {
//     for (final t in preferred) {
//       if (types.any((e) => e.toString().toLowerCase().contains(t.toLowerCase()))) {
//         return t;
//       }
//     }
//     if (types.contains('veterinary_care')) return 'Animal Shelter';
//     if (types.contains('food')) return 'Food Bank';
//     return preferred.isNotEmpty ? preferred.first : 'Donation Center';
//   }

//   static List<DonationCenter> _mockDonationCenters(
//     double lat,
//     double lng,
//     List<String> orgTypes,
//   ) {
//     final type1 = orgTypes.isNotEmpty ? orgTypes[0] : 'Animal Shelter';
//     final type2 = orgTypes.length > 1 ? orgTypes[1] : 'Gaushala';
//     final type3 = orgTypes.length > 2 ? orgTypes[2] : 'Dairy Farm';

//     return [
//       DonationCenter(
//         name: 'Shri Gopal Gaushala',
//         type: type1,
//         address: 'Near Railway Station, Sector 12, City',
//         distanceKm: 1.2,
//         rating: 4.6,
//         reviewCount: 132,
//         phone: '+91 98765 43210',
//         lat: lat + 0.008,
//         lng: lng + 0.005,
//         placeId: 'mock_place_1',
//       ),
//       DonationCenter(
//         name: 'Happy Paws Animal Shelter',
//         type: type2,
//         address: 'Plot 45, Green Park Colony',
//         distanceKm: 2.4,
//         rating: 4.2,
//         reviewCount: 98,
//         phone: '+91 91234 56789',
//         lat: lat - 0.012,
//         lng: lng + 0.010,
//         placeId: 'mock_place_2',
//       ),
//       DonationCenter(
//         name: 'Sunrise Dairy & Cattle Farm',
//         type: type3,
//         address: 'Village Road, Agricultural Zone',
//         distanceKm: 3.1,
//         rating: 4.4,
//         reviewCount: 67,
//         phone: '+91 88001 22334',
//         lat: lat + 0.018,
//         lng: lng - 0.008,
//         placeId: 'mock_place_3',
//       ),
//       DonationCenter(
//         name: 'City Food Bank & NGO',
//         type: 'Food Bank',
//         address: '12-B, Main Market Road, Civil Lines',
//         distanceKm: 4.3,
//         rating: 4.8,
//         reviewCount: 211,
//         phone: '+91 80000 55566',
//         lat: lat - 0.020,
//         lng: lng - 0.015,
//         placeId: 'mock_place_4',
//       ),
//       DonationCenter(
//         name: 'Prani Mitra Animal Care',
//         type: 'Animal Shelter',
//         address: 'Opp. City Park, Old Town',
//         distanceKm: 5.0,
//         rating: 4.1,
//         reviewCount: 54,
//         phone: null,
//         lat: lat + 0.025,
//         lng: lng + 0.020,
//         placeId: 'mock_place_5',
//       ),
//     ]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
//   }

//   // ── Haversine formula for distance calculation ─────────────────────────────

//   static double _haversineDistance(
//     double lat1, double lon1, double lat2, double lon2,
//   ) {
//     const r = 6371.0; // Earth radius km
//     final dLat = _toRad(lat2 - lat1);
//     final dLon = _toRad(lon2 - lon1);
//     final a = _sin2(dLat / 2) +
//         _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin2(dLon / 2);
//     final c = 2 * _asin(_sqrt(a));
//     return r * c;
//   }

//   static double _toRad(double deg) => deg * 3.141592653589793 / 180;
//   static double _sin2(double x) => _sin(x) * _sin(x);
//   static double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
//   static double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
//   static double _asin(double x) => x + x * x * x / 6;
//   static double _sqrt(double x) {
//     if (x <= 0) return 0;
//     double est = x / 2;
//     for (int i = 0; i < 20; i++) {
//       est = (est + x / est) / 2;
//     }
//     return est;
//   }
// }



// version 2


// import 'dart:convert';

// import 'package:firebase_ai/firebase_ai.dart';
// import 'package:http/http.dart' as http;

// import '../models/product_model.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // API Key Placeholders
// // ─────────────────────────────────────────────────────────────────────────────
// //
// // Gemini:
// // NO GEMINI API KEY IS REQUIRED HERE.
// // Gemini is accessed through Firebase AI Logic.
// //
// // Google Places:
// // This is intentionally kept as it was for this iteration.
// // We will secure/move this later.
// // ─────────────────────────────────────────────────────────────────────────────

// const String _kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

// // ─────────────────────────────────────────────────────────────────────────────
// // Models
// // ─────────────────────────────────────────────────────────────────────────────

// class DonationCenter {
//   final String name;
//   final String type; // e.g. "Gaushala", "Animal Shelter", "Dairy Farm"
//   final String address;
//   final double distanceKm;
//   final double? rating;
//   final int? reviewCount;
//   final String? phone;
//   final double lat;
//   final double lng;
//   final String? placeId;

//   const DonationCenter({
//     required this.name,
//     required this.type,
//     required this.address,
//     required this.distanceKm,
//     this.rating,
//     this.reviewCount,
//     this.phone,
//     required this.lat,
//     required this.lng,
//     this.placeId,
//   });

//   String get googleMapsUrl =>
//       'https://www.google.com/maps/search/?api=1'
//       '&query=${Uri.encodeComponent(name)}'
//       '&query_place_id=${placeId ?? ''}'
//       '&center=$lat,$lng';
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Gemini Donation Result
// // ─────────────────────────────────────────────────────────────────────────────

// class GeminiDonationResult {
//   final bool isSuitable;

//   /// Possible values:
//   /// - human_consumption
//   /// - animal_feed
//   /// - non_food_use
//   /// - unsafe
//   /// - unknown
//   final String donationCategory;

//   final String reason;

//   /// Examples:
//   /// - Gaushala
//   /// - Animal Shelter
//   /// - Poultry Farm
//   /// - Dairy Farm
//   /// - Food Bank
//   /// - Community Kitchen
//   final List<String> suggestedOrgTypes;

//   /// true  = result came from Gemini
//   /// false = local fallback was used
//   final bool usedAi;

//   const GeminiDonationResult({
//     required this.isSuitable,
//     required this.donationCategory,
//     required this.reason,
//     required this.suggestedOrgTypes,
//     required this.usedAi,
//   });
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Service
// // ─────────────────────────────────────────────────────────────────────────────

// class DonationService {
//   static const Duration _timeout = Duration(seconds: 12);

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 1. GEMINI - ASSESS DONATION SUITABILITY
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Future<GeminiDonationResult> assessDonationSuitability(
//     ProductModel product,
//   ) async {
//     try {
//       final daysExpired = product.daysRemaining.abs();

//       // ─────────────────────────────────────────────────────────────────────
//       // Structured JSON schema for Gemini
//       // ─────────────────────────────────────────────────────────────────────

//       final donationSchema = Schema.object(
//         properties: {
//           'isSuitable': Schema.boolean(),

//           'donationCategory': Schema.enumString(
//             enumValues: [
//               'human_consumption',
//               'animal_feed',
//               'non_food_use',
//               'unsafe',
//               'unknown',
//             ],
//           ),

//           'reason': Schema.string(),

//           'suggestedOrgTypes': Schema.array(
//             items: Schema.enumString(
//               enumValues: [
//                 'Gaushala',
//                 'Animal Shelter',
//                 'Poultry Farm',
//                 'Dairy Farm',
//                 'Cattle Shelter',
//                 'Food Bank',
//                 'Community Kitchen',
//                 'NGO',
//               ],
//             ),
//           ),
//         },
//       );

//       // ─────────────────────────────────────────────────────────────────────
//       // Firebase AI Logic → Gemini Developer API
//       //
//       // No Gemini API key is placed in this file.
//       // ─────────────────────────────────────────────────────────────────────

//       final model = FirebaseAI.googleAI().generativeModel(
//         model: 'gemini-3.6-flash',

//         generationConfig: GenerationConfig(
//           temperature: 0.2,
//           maxOutputTokens: 512,

//           // Tell Gemini to return JSON.
//           responseMimeType: 'application/json',

//           // Force the response to follow our schema.
//           responseSchema: donationSchema,
//         ),
//       );

//       // ─────────────────────────────────────────────────────────────────────
//       // Prompt
//       // ─────────────────────────────────────────────────────────────────────

//       final prompt = '''
// You are the donation-safety advisor for SmartShelf.

// SmartShelf helps grocery stores decide what they should do with products
// that have expired.

// The store wants to know whether an expired product can potentially be
// donated and, if appropriate, what type of organization could receive it.

// Your primary priority is SAFETY.

// IMPORTANT RULES:

// 1. Never assume that an expired product is safe simply because it is
//    packaged or non-perishable.

// 2. Highly perishable products such as milk, fresh dairy, meat, fish,
//    seafood, cooked food and similar products should generally be classified
//    as unsafe after their expiry/use-by date.

// 3. Do NOT recommend expired food for human consumption when there is a
//    meaningful safety concern.

// 4. Dry products such as flour, rice, grains or some packaged pantry products
//    MAY potentially be considered for animal feed if they are dry,
//    uncontaminated and show no signs of mold, pests, moisture, unusual smell
//    or spoilage.

// 5. Never recommend a product as animal feed if it could reasonably be toxic,
//    spoiled, contaminated or dangerous to animals.

// 6. Consider all available information:
//    - product name
//    - category
//    - brand
//    - quantity
//    - number of days since expiry
//    - whether the product is perishable
//    - whether it can spoil quickly
//    - whether it could potentially be used as animal feed

// 7. If there is insufficient information to make a safe recommendation,
//    prefer "unknown" or "unsafe" instead of making an optimistic assumption.

// 8. suggestedOrgTypes must contain ONLY organization types that are
//    appropriate for this specific product.

// 9. If donation is unsafe, return an empty suggestedOrgTypes list.

// 10. Keep the reason short, clear and understandable for a grocery-store user.

// DONATION CATEGORIES:

// human_consumption
//     The product may potentially be suitable for human consumption.
//     Use this category conservatively.

// animal_feed
//     The product is not recommended for human consumption but may
//     potentially be considered as animal feed if safe and uncontaminated.

// non_food_use
//     The product cannot reasonably be consumed but may have another
//     useful non-food purpose.

// unsafe
//     The product should not be donated for consumption or animal feed.

// unknown
//     There is not enough information to make a safe determination.

// EXAMPLES:

// Example 1:
// Product: Wheat flour
// Category: Pantry
// Expired: 2 days

// If it is dry, sealed, uncontaminated and free from mold or pests:
// → potentially suitable for animal feed
// → possible organizations:
//    Gaushala
//    Poultry Farm
//    Animal Shelter

// Example 2:
// Product: Milk
// Category: Dairy
// Expired: 2 days

// → unsafe
// → do not recommend it for human consumption
// → do not recommend it as animal feed
// → suggestedOrgTypes should be empty

// Example 3:
// Product: Rice
// Category: Pantry
// Expired: 3 days

// If dry, sealed and free from contamination:
// → potentially suitable for animal feed
// → possible organizations:
//    Gaushala
//    Poultry Farm
//    Animal Shelter

// Example 4:
// Product: Fresh meat
// Category: Meat
// Expired: 1 day

// → unsafe
// → suggestedOrgTypes should be empty

// Example 5:
// Product: Biscuits
// Category: Snacks
// Expired: 1 day

// Assess conservatively based on the available information.
// Do not automatically assume that it is safe for human consumption.

// PRODUCT DETAILS:

// Name: ${product.name}
// Category: ${product.category}
// Brand: ${product.brand ?? 'Unknown'}
// Quantity: ${product.quantity} units
// Days since expiry: $daysExpired days

// Return ONLY the structured JSON response according to the provided schema.
// ''';

//       // ─────────────────────────────────────────────────────────────────────
//       // Generate Gemini response
//       // ─────────────────────────────────────────────────────────────────────

//       final response = await model
//           .generateContent([
//             Content.text(prompt),
//           ])
//           .timeout(_timeout);

//       final text = response.text;

//       if (text == null || text.trim().isEmpty) {
//         return _fallbackGeminiResult(product);
//       }

//       // Because responseMimeType is application/json and responseSchema
//       // is provided, Gemini should return valid JSON.
//       final parsed = jsonDecode(text) as Map<String, dynamic>;

//       final isSuitable = parsed['isSuitable'];

//       final donationCategory = parsed['donationCategory'];

//       final reason = parsed['reason'];

//       final suggestedOrgTypes = parsed['suggestedOrgTypes'];

//       // Basic validation before using the AI response.
//       if (isSuitable is! bool ||
//           donationCategory is! String ||
//           reason is! String ||
//           suggestedOrgTypes is! List) {
//         return _fallbackGeminiResult(product);
//       }

//       return GeminiDonationResult(
//         isSuitable: isSuitable,
//         donationCategory: donationCategory,
//         reason: reason,
//         suggestedOrgTypes: List<String>.from(suggestedOrgTypes),
//         usedAi: true,
//       );
//     } catch (e) {
//       // Gemini failure should NOT break the Donate flow.
//       //
//       // Instead, use a conservative local fallback.
//       return _fallbackGeminiResult(product);
//     }
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // GEMINI FALLBACK
//   // ═══════════════════════════════════════════════════════════════════════════

//   static GeminiDonationResult _fallbackGeminiResult(
//     ProductModel product,
//   ) {
//     final daysExpired = product.daysRemaining.abs();
//     final category = product.category.toLowerCase();

//     // ───────────────────────────────────────────────────────────────────────
//     // Very old expired products
//     // ───────────────────────────────────────────────────────────────────────

//     if (daysExpired > 14) {
//       return const GeminiDonationResult(
//         isSuitable: false,
//         donationCategory: 'unsafe',
//         reason:
//             'This product has been expired for more than two weeks, so donation for consumption or animal feed is not recommended.',
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // ───────────────────────────────────────────────────────────────────────
//     // Highly perishable products
//     // ───────────────────────────────────────────────────────────────────────

//     if (category == 'dairy' ||
//         category == 'milk' ||
//         category == 'meat' ||
//         category == 'fish' ||
//         category == 'seafood') {
//       return const GeminiDonationResult(
//         isSuitable: false,
//         donationCategory: 'unsafe',
//         reason:
//             'This is a highly perishable product and should not be donated after its expiry date because of potential health risks.',
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // ───────────────────────────────────────────────────────────────────────
//     // Dry pantry products
//     // ───────────────────────────────────────────────────────────────────────

//     if (category == 'pantry' ||
//         category == 'grains' ||
//         category == 'flour' ||
//         category == 'cereals') {
//       return const GeminiDonationResult(
//         isSuitable: true,
//         donationCategory: 'animal_feed',
//         reason:
//             'If the product is dry, uncontaminated and free from mold or pests, it may potentially be suitable as animal feed.',
//         suggestedOrgTypes: [
//           'Gaushala',
//           'Poultry Farm',
//           'Animal Shelter',
//         ],
//         usedAi: false,
//       );
//     }

//     // ───────────────────────────────────────────────────────────────────────
//     // Conservative default
//     // ───────────────────────────────────────────────────────────────────────

//     return const GeminiDonationResult(
//       isSuitable: false,
//       donationCategory: 'unknown',
//       reason:
//           'There is not enough information to safely determine whether this expired product can be donated.',
//       suggestedOrgTypes: [],
//       usedAi: false,
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // 2. GOOGLE PLACES - FIND NEARBY DONATION CENTERS
//   //
//   // This section is intentionally kept from your existing implementation.
//   // We will secure/fix the Places API key in the next iteration.
//   // ═══════════════════════════════════════════════════════════════════════════

//   static Future<List<DonationCenter>> findNearbyDonationCenters({
//     required double latitude,
//     required double longitude,
//     required List<String> orgTypes,
//     int radiusMeters = 10000,
//   }) async {
//     if (_kGooglePlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
//       return _mockDonationCenters(
//         latitude,
//         longitude,
//         orgTypes,
//       );
//     }

//     try {
//       final keywords = orgTypes.join('|');

//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
//         '?location=$latitude,$longitude'
//         '&radius=$radiusMeters'
//         '&keyword=${Uri.encodeComponent(keywords)}'
//         '&key=$_kGooglePlacesApiKey',
//       );

//       final response = await http.get(url).timeout(_timeout);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as Map<String, dynamic>;

//         final results = data['results'] as List<dynamic>;

//         return results.take(6).map((place) {
//           final placeMap = place as Map<String, dynamic>;

//           final geo =
//               placeMap['geometry']['location'] as Map<String, dynamic>;

//           final lat = (geo['lat'] as num).toDouble();
//           final lng = (geo['lng'] as num).toDouble();

//           return DonationCenter(
//             name: placeMap['name'] as String,
//             type: _inferType(
//               placeMap['types'] as List<dynamic>,
//               orgTypes,
//             ),
//             address: (placeMap['vicinity'] ??
//                     placeMap['formatted_address'] ??
//                     'Address not available')
//                 as String,
//             distanceKm: _haversineDistance(
//               latitude,
//               longitude,
//               lat,
//               lng,
//             ),
//             rating: placeMap['rating'] != null
//                 ? (placeMap['rating'] as num).toDouble()
//                 : null,
//             reviewCount: placeMap['user_ratings_total'] as int?,
//             lat: lat,
//             lng: lng,
//             placeId: placeMap['place_id'] as String?,
//           );
//         }).toList()
//           ..sort(
//             (a, b) => a.distanceKm.compareTo(b.distanceKm),
//           );
//       }
//     } catch (_) {
//       // Fall through to mock results.
//     }

//     return _mockDonationCenters(
//       latitude,
//       longitude,
//       orgTypes,
//     );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // INFER DONATION CENTER TYPE
//   // ═══════════════════════════════════════════════════════════════════════════

//   static String _inferType(
//     List<dynamic> types,
//     List<String> preferred,
//   ) {
//     for (final t in preferred) {
//       if (types.any(
//         (e) => e
//             .toString()
//             .toLowerCase()
//             .contains(t.toLowerCase()),
//       )) {
//         return t;
//       }
//     }

//     if (types.contains('veterinary_care')) {
//       return 'Animal Shelter';
//     }

//     if (types.contains('food')) {
//       return 'Food Bank';
//     }

//     return preferred.isNotEmpty
//         ? preferred.first
//         : 'Donation Center';
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // MOCK DONATION CENTERS
//   // ═══════════════════════════════════════════════════════════════════════════

//   static List<DonationCenter> _mockDonationCenters(
//     double lat,
//     double lng,
//     List<String> orgTypes,
//   ) {
//     final type1 =
//         orgTypes.isNotEmpty ? orgTypes[0] : 'Animal Shelter';

//     final type2 =
//         orgTypes.length > 1 ? orgTypes[1] : 'Gaushala';

//     final type3 =
//         orgTypes.length > 2 ? orgTypes[2] : 'Dairy Farm';

//     return [
//       DonationCenter(
//         name: 'Shri Gopal Gaushala',
//         type: type1,
//         address: 'Near Railway Station, Sector 12, City',
//         distanceKm: 1.2,
//         rating: 4.6,
//         reviewCount: 132,
//         phone: '+91 98765 43210',
//         lat: lat + 0.008,
//         lng: lng + 0.005,
//         placeId: 'mock_place_1',
//       ),

//       DonationCenter(
//         name: 'Happy Paws Animal Shelter',
//         type: type2,
//         address: 'Plot 45, Green Park Colony',
//         distanceKm: 2.4,
//         rating: 4.2,
//         reviewCount: 98,
//         phone: '+91 91234 56789',
//         lat: lat - 0.012,
//         lng: lng + 0.010,
//         placeId: 'mock_place_2',
//       ),

//       DonationCenter(
//         name: 'Sunrise Dairy & Cattle Farm',
//         type: type3,
//         address: 'Village Road, Agricultural Zone',
//         distanceKm: 3.1,
//         rating: 4.4,
//         reviewCount: 67,
//         phone: '+91 88001 22334',
//         lat: lat + 0.018,
//         lng: lng - 0.008,
//         placeId: 'mock_place_3',
//       ),

//       DonationCenter(
//         name: 'City Food Bank & NGO',
//         type: 'Food Bank',
//         address: '12-B, Main Market Road, Civil Lines',
//         distanceKm: 4.3,
//         rating: 4.8,
//         reviewCount: 211,
//         phone: '+91 80000 55566',
//         lat: lat - 0.020,
//         lng: lng - 0.015,
//         placeId: 'mock_place_4',
//       ),

//       DonationCenter(
//         name: 'Prani Mitra Animal Care',
//         type: 'Animal Shelter',
//         address: 'Opp. City Park, Old Town',
//         distanceKm: 5.0,
//         rating: 4.1,
//         reviewCount: 54,
//         phone: null,
//         lat: lat + 0.025,
//         lng: lng + 0.020,
//         placeId: 'mock_place_5',
//       ),
//     ]..sort(
//         (a, b) => a.distanceKm.compareTo(b.distanceKm),
//       );
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // HAVERSINE DISTANCE
//   // ═══════════════════════════════════════════════════════════════════════════

//   static double _haversineDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const r = 6371.0; // Earth radius in km

//     final dLat = _toRad(lat2 - lat1);
//     final dLon = _toRad(lon2 - lon1);

//     final a = _sin2(dLat / 2) +
//         _cos(_toRad(lat1)) *
//             _cos(_toRad(lat2)) *
//             _sin2(dLon / 2);

//     final c = 2 * _asin(_sqrt(a));

//     return r * c;
//   }

//   static double _toRad(double deg) =>
//       deg * 3.141592653589793 / 180;

//   static double _sin2(double x) =>
//       _sin(x) -
//       0 +
//       (_sin(x) * _sin(x) - _sin(x) * _sin(x));

//   static double _sin(double x) =>
//       x -
//       x * x * x / 6 +
//       x * x * x * x * x / 120;

//   static double _cos(double x) =>
//       1 -
//       x * x / 2 +
//       x * x * x * x / 24;

//   static double _asin(double x) =>
//       x +
//       x * x * x / 6;

//   static double _sqrt(double x) {
//     if (x <= 0) return 0;

//     double est = x / 2;

//     for (int i = 0; i < 20; i++) {
//       est = (est + x / est) / 2;
//     }

//     return est;
//   }
// }

// version 3-ai studio

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:firebase_ai/firebase_ai.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// import '../models/product_model.dart';

// class DonationService {
//   // ===========================================================================
//   // GOOGLE PLACES API KEY
//   // ===========================================================================
//   //
//   // Keep your existing Google Places API key here.
//   //
//   // If you keep the placeholder, demo donation centers will be returned.
//   //
//   static const String _kGooglePlacesApiKey =
//       'YOUR_GOOGLE_PLACES_API_KEY_HERE';

//   static const Duration _timeout =
//       Duration(seconds: 45);

//   // ===========================================================================
//   // GEMINI DONATION ASSESSMENT
//   // ===========================================================================

//   static Future<GeminiDonationResult>
//       assessDonationSuitability(
//     ProductModel product,
//   ) async {
//     final daysRemaining =
//         product.daysRemaining;

//     // -------------------------------------------------------------------------
//     // GEMINI RESPONSE SCHEMA
//     // -------------------------------------------------------------------------

//     final donationSchema = Schema.object(
//       properties: {
//         'isSuitable': Schema.boolean(),

//         'donationCategory': Schema.enumString(
//           enumValues: [
//             'human_consumption',
//             'animal_feed',
//             'non_food_use',
//             'unsafe',
//             'unknown',
//           ],
//         ),

//         'reason': Schema.string(),

//         'suggestedAnimals': Schema.array(
//           items: Schema.string(),
//         ),

//         'suggestedOrgTypes': Schema.array(
//           items: Schema.enumString(
//             enumValues: [
//               'Gaushala',
//               'Animal Shelter',
//               'Poultry Farm',
//               'Dairy Farm',
//               'Cattle Shelter',
//               'Food Bank',
//               'Community Kitchen',
//               'NGO',
//             ],
//           ),
//         ),
//       },
//     );

//     // -------------------------------------------------------------------------
//     // FIREBASE AI LOGIC MODEL
//     // -------------------------------------------------------------------------

//     final model =
//         FirebaseAI.googleAI().generativeModel(
//       model: 'gemini-3.6-flash',
//       generationConfig:
//           GenerationConfig(
//         temperature: 0.2,

//         // Increased from 512 because your previous JSON response
//         // was getting truncated.
//         maxOutputTokens: 1024,

//         responseMimeType:
//             'application/json',

//         responseSchema:
//             donationSchema,
//       ),
//     );

//     // -------------------------------------------------------------------------
//     // EXPIRY STATUS
//     // -------------------------------------------------------------------------

//     String expiryStatus;

//     if (daysRemaining > 0) {
//       expiryStatus =
//           'The product has NOT expired. '
//           'It expires in $daysRemaining '
//           '${daysRemaining == 1 ? 'day' : 'days'}.';
//     } else if (daysRemaining == 0) {
//       expiryStatus =
//           'The product expires TODAY.';
//     } else {
//       final daysExpired =
//           daysRemaining.abs();

//       expiryStatus =
//           'The product expired $daysExpired '
//           '${daysExpired == 1 ? 'day' : 'days'} ago.';
//     }

//     // -------------------------------------------------------------------------
//     // GEMINI PROMPT
//     // -------------------------------------------------------------------------
//     //
//     // Keep this relatively short because the output only needs structured JSON.
//     //

//     final prompt = '''
// You are SmartShelf's donation-safety assistant.

// Analyze this grocery product and determine whether it could potentially be
// donated.

// EXPIRY STATUS:
// $expiryStatus

// PRODUCT:
// Name: ${product.name}
// Category: ${product.category}
// Brand: ${product.brand ?? 'Unknown'}
// Quantity: ${product.quantity} units
// Expiry date: ${product.expiryDate.toIso8601String()}
// Days remaining: $daysRemaining

// RULES:

// 1. A product that has NOT expired can be proactively donated.

// 2. A product that expires today can be donated immediately if its condition
//    is acceptable.

// 3. An expired product must be evaluated conservatively.

// 4. Do not claim an expired product is definitely safe.

// 5. Consider mold, spoilage, contamination, rancidity and other safety risks.

// 6. If potentially suitable as animal feed, suggest realistic animals.

// 7. If still suitable for human consumption, suggest Food Bank,
//    Community Kitchen or NGO.

// 8. If suitable for animal feed, suggest relevant organizations such as
//    Gaushala, Animal Shelter, Poultry Farm, Dairy Farm or Cattle Shelter.

// 9. If unsafe or insufficient information exists:
//    isSuitable must be false,
//    suggestedAnimals must be [],
//    suggestedOrgTypes must be [].

// 10. Only use these donation categories:
// human_consumption
// animal_feed
// non_food_use
// unsafe
// unknown

// 11. Only use these organization types:
// Gaushala
// Animal Shelter
// Poultry Farm
// Dairy Farm
// Cattle Shelter
// Food Bank
// Community Kitchen
// NGO

// Return ONLY valid JSON matching the provided schema.
// ''';

//     // =========================================================================
//     // GEMINI REQUEST
//     // =========================================================================

//     try {
//       final response = await model
//           .generateContent([
//         Content.text(prompt),
//       ])
//           .timeout(_timeout);

//       // -----------------------------------------------------------------------
//       // LOG RAW GEMINI RESPONSE
//       // -----------------------------------------------------------------------

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       debugPrint(
//         'GEMINI RESPONSE RECEIVED',
//       );

//       debugPrint(
//         'Product: ${product.name}',
//       );

//       debugPrint(
//         'Category: ${product.category}',
//       );

//       debugPrint(
//         'Days remaining: $daysRemaining',
//       );

//       debugPrint(
//         'Response text:',
//       );

//       debugPrint(
//         response.text,
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // -----------------------------------------------------------------------
//       // CHECK EMPTY RESPONSE
//       // -----------------------------------------------------------------------

//       final text =
//           response.text;

//       if (text == null ||
//           text.trim().isEmpty) {
//         throw Exception(
//           'Gemini returned an empty response',
//         );
//       }

//       // -----------------------------------------------------------------------
//       // CLEAN RESPONSE
//       // -----------------------------------------------------------------------

//       String cleanedText =
//           text.trim();

//       // Remove Markdown JSON fences if Gemini ever returns them.

//       if (cleanedText
//           .startsWith('```json')) {
//         cleanedText =
//             cleanedText.substring(
//           7,
//         );
//       }

//       if (cleanedText
//           .startsWith('```')) {
//         cleanedText =
//             cleanedText.substring(
//           3,
//         );
//       }

//       if (cleanedText
//           .endsWith('```')) {
//         cleanedText =
//             cleanedText.substring(
//           0,
//           cleanedText.length - 3,
//         );
//       }

//       cleanedText =
//           cleanedText.trim();

//       debugPrint(
//         'CLEANED GEMINI JSON:',
//       );

//       debugPrint(
//         cleanedText,
//       );

//       // -----------------------------------------------------------------------
//       // PARSE JSON
//       // -----------------------------------------------------------------------

//       final decoded =
//           jsonDecode(cleanedText);

//       if (decoded
//           is! Map<String, dynamic>) {
//         throw Exception(
//           'Gemini response was not a JSON object',
//         );
//       }

//       // -----------------------------------------------------------------------
//       // IS SUITABLE
//       // -----------------------------------------------------------------------

//       final isSuitable =
//           decoded['isSuitable'] == true;

//       // -----------------------------------------------------------------------
//       // DONATION CATEGORY
//       // -----------------------------------------------------------------------

//       final rawCategory =
//           decoded['donationCategory']
//               ?.toString()
//               .trim();

//       const validCategories = {
//         'human_consumption',
//         'animal_feed',
//         'non_food_use',
//         'unsafe',
//         'unknown',
//       };

//       final donationCategory =
//           validCategories.contains(
//         rawCategory,
//       )
//               ? rawCategory!
//               : 'unknown';

//       // -----------------------------------------------------------------------
//       // REASON
//       // -----------------------------------------------------------------------

//       final rawReason =
//           decoded['reason']
//               ?.toString()
//               .trim();

//       final reason =
//           rawReason == null ||
//                   rawReason.isEmpty
//               ? 'Gemini did not provide a reason.'
//               : rawReason;

//       // -----------------------------------------------------------------------
//       // SUGGESTED ANIMALS
//       // -----------------------------------------------------------------------

//       List<String>
//           suggestedAnimals = [];

//       final rawAnimals =
//           decoded['suggestedAnimals'];

//       if (rawAnimals is List) {
//         suggestedAnimals =
//             rawAnimals
//                 .map(
//                   (item) =>
//                       item.toString().trim(),
//                 )
//                 .where(
//                   (item) =>
//                       item.isNotEmpty,
//                 )
//                 .toSet()
//                 .toList();
//       }

//       // -----------------------------------------------------------------------
//       // SUGGESTED ORGANIZATION TYPES
//       // -----------------------------------------------------------------------

//       const validOrgTypes = {
//         'Gaushala',
//         'Animal Shelter',
//         'Poultry Farm',
//         'Dairy Farm',
//         'Cattle Shelter',
//         'Food Bank',
//         'Community Kitchen',
//         'NGO',
//       };

//       List<String>
//           suggestedOrgTypes = [];

//       final rawOrgTypes =
//           decoded['suggestedOrgTypes'];

//       if (rawOrgTypes is List) {
//         suggestedOrgTypes =
//             rawOrgTypes
//                 .map(
//                   (item) =>
//                       item.toString().trim(),
//                 )
//                 .where(
//                   (item) =>
//                       validOrgTypes.contains(
//                     item,
//                   ),
//                 )
//                 .toSet()
//                 .toList();
//       }

//       // -----------------------------------------------------------------------
//       // SAFETY VALIDATION
//       // -----------------------------------------------------------------------

//       if (!isSuitable ||
//           donationCategory ==
//               'unsafe' ||
//           donationCategory ==
//               'unknown') {
//         suggestedAnimals = [];
//         suggestedOrgTypes = [];
//       }

//       // -----------------------------------------------------------------------
//       // FINAL SUITABILITY
//       // -----------------------------------------------------------------------
//       //
//       // For the Places search we require at least one organization type.
//       //

//       final finalIsSuitable =
//           isSuitable &&
//               suggestedOrgTypes
//                   .isNotEmpty;

//       // -----------------------------------------------------------------------
//       // LOG PARSED RESULT
//       // -----------------------------------------------------------------------

//       debugPrint(
//         'GEMINI PARSED RESULT',
//       );

//       debugPrint(
//         'isSuitable: $finalIsSuitable',
//       );

//       debugPrint(
//         'donationCategory: $donationCategory',
//       );

//       debugPrint(
//         'reason: $reason',
//       );

//       debugPrint(
//         'suggestedAnimals: $suggestedAnimals',
//       );

//       debugPrint(
//         'suggestedOrgTypes: $suggestedOrgTypes',
//       );

//       debugPrint(
//         'usedAi: true',
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // -----------------------------------------------------------------------
//       // RETURN RESULT
//       // -----------------------------------------------------------------------

//       return GeminiDonationResult(
//         isSuitable:
//             finalIsSuitable,
//         donationCategory:
//             donationCategory,
//         reason:
//             reason,
//         suggestedAnimals:
//             suggestedAnimals,
//         suggestedOrgTypes:
//             suggestedOrgTypes,
//         usedAi: true,
//       );
//     }

//     // =========================================================================
//     // GEMINI ERROR
//     // =========================================================================

//     catch (e, stackTrace) {
//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       debugPrint(
//         'SMARTSHELF GEMINI ERROR',
//       );

//       debugPrint(
//         'Product: ${product.name}',
//       );

//       debugPrint(
//         'Category: ${product.category}',
//       );

//       debugPrint(
//         'Days remaining: ${product.daysRemaining}',
//       );

//       debugPrint(
//         'Error: $e',
//       );

//       debugPrint(
//         'Stack trace: $stackTrace',
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // Only use the rule-based fallback when Gemini actually fails.
//       return _fallbackGeminiResult(
//         product,
//       );
//     }
//   }

//   // ===========================================================================
//   // FALLBACK RESULT
//   // ===========================================================================
//   //
//   // This is NOT used when Gemini works.
//   // It is only used when the Gemini request or JSON parsing fails.
//   //

//   static GeminiDonationResult
//       _fallbackGeminiResult(
//     ProductModel product,
//   ) {
//     final daysRemaining =
//         product.daysRemaining;

//     final category =
//         product.category.toLowerCase();

//     // -------------------------------------------------------------------------
//     // FUTURE PRODUCT
//     // -------------------------------------------------------------------------

//     if (daysRemaining > 0) {
//       // Dry / bakery products
//       if (_containsAny(
//         category,
//         [
//           'grain',
//           'cereal',
//           'flour',
//           'rice',
//           'wheat',
//           'bakery',
//           'bread',
//           'biscuit',
//           'cookie',
//           'cracker',
//           'snack',
//           'chips',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'animal_feed',
//           reason:
//               'Gemini was unavailable. This product has not expired and may potentially be redirected to an appropriate animal-feed organization before expiry. The receiving organization should inspect it before accepting it.',
//           suggestedAnimals: [
//             'Cattle',
//             'Goats',
//             'Chickens',
//             'Poultry',
//           ],
//           suggestedOrgTypes: [
//             'Gaushala',
//             'Cattle Shelter',
//             'Poultry Farm',
//             'Animal Shelter',
//           ],
//           usedAi: false,
//         );
//       }

//       // Fruit / vegetables
//       if (_containsAny(
//         category,
//         [
//           'fruit',
//           'vegetable',
//           'produce',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'animal_feed',
//           reason:
//               'This product has not expired and may potentially be donated as animal feed if it remains in acceptable condition.',
//           suggestedAnimals: [
//             'Cattle',
//             'Goats',
//             'Poultry',
//           ],
//           suggestedOrgTypes: [
//             'Gaushala',
//             'Cattle Shelter',
//             'Animal Shelter',
//           ],
//           usedAi: false,
//         );
//       }

//       // Dairy / beverages
//       if (_containsAny(
//         category,
//         [
//           'dairy',
//           'milk',
//           'beverage',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'human_consumption',
//           reason:
//               'This product has not expired yet and may potentially be donated for human consumption if it is unopened, properly stored, and safe.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [
//             'Food Bank',
//             'Community Kitchen',
//             'NGO',
//           ],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: false,
//         donationCategory:
//             'unknown',
//         reason:
//             'Gemini could not be reached, so there is not enough information to safely classify this product for donation.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // -------------------------------------------------------------------------
//     // EXPIRES TODAY
//     // -------------------------------------------------------------------------

//     if (daysRemaining == 0) {
//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'human_consumption',
//         reason:
//             'This product expires today. It may potentially be donated immediately if its packaging, storage conditions, and physical condition are acceptable.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [
//           'Food Bank',
//           'Community Kitchen',
//           'NGO',
//         ],
//         usedAi: false,
//       );
//     }

//     // -------------------------------------------------------------------------
//     // EXPIRED PRODUCT
//     // -------------------------------------------------------------------------

//     final daysExpired =
//         daysRemaining.abs();

//     // High-risk categories
//     if (_containsAny(
//       category,
//       [
//         'milk',
//         'dairy',
//         'meat',
//         'fish',
//         'seafood',
//         'chicken',
//         'egg',
//         'eggs',
//       ],
//     )) {
//       return GeminiDonationResult(
//         isSuitable: false,
//         donationCategory:
//             'unsafe',
//         reason:
//             'This product has expired $daysExpired ${daysExpired == 1 ? 'day' : 'days'} ago and belongs to a highly perishable category. Without inspection and additional safety information, it should not be recommended for donation or animal consumption.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // Bakery / dry food
//     if (_containsAny(
//       category,
//       [
//         'bakery',
//         'bread',
//         'biscuit',
//         'cookie',
//         'cracker',
//         'cake',
//         'pastry',
//         'grain',
//         'cereal',
//         'flour',
//         'rice',
//         'wheat',
//         'snack',
//         'chips',
//       ],
//     )) {
//       if (daysExpired > 14) {
//         return GeminiDonationResult(
//           isSuitable: false,
//           donationCategory:
//               'unsafe',
//           reason:
//               'This product has been expired for more than two weeks. Without reliable information about its current condition and storage, it should not be recommended for donation.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'animal_feed',
//         reason:
//             'This dry or bakery product has expired $daysExpired ${daysExpired == 1 ? 'day' : 'days'} ago. It may potentially be repurposed as animal feed only if it has no mold, insects, contamination, unusual odor, rancidity, or other signs of spoilage. The receiving organization must make the final decision.',
//         suggestedAnimals: [
//           'Cattle',
//           'Goats',
//           'Chickens',
//           'Poultry',
//         ],
//         suggestedOrgTypes: [
//           'Gaushala',
//           'Cattle Shelter',
//           'Poultry Farm',
//           'Animal Shelter',
//         ],
//         usedAi: false,
//       );
//     }

//     // Fruit / vegetables
//     if (_containsAny(
//       category,
//       [
//         'fruit',
//         'vegetable',
//         'produce',
//       ],
//     )) {
//       if (daysExpired > 7) {
//         return GeminiDonationResult(
//           isSuitable: false,
//           donationCategory:
//               'unsafe',
//           reason:
//               'This produce has been expired for $daysExpired days. Without knowing its current physical condition, it should not be recommended for donation.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'animal_feed',
//         reason:
//             'Some expired produce may potentially be used as animal feed if it is free from mold, toxic substances, severe decomposition, and contamination. The receiving organization must inspect it before accepting it.',
//         suggestedAnimals: [
//           'Cattle',
//           'Goats',
//           'Poultry',
//         ],
//         suggestedOrgTypes: [
//           'Gaushala',
//           'Cattle Shelter',
//           'Animal Shelter',
//         ],
//         usedAi: false,
//       );
//     }

//     // Unknown
//     return GeminiDonationResult(
//       isSuitable: false,
//       donationCategory:
//           'unknown',
//       reason:
//           'Gemini could not be reached and there is not enough reliable information to safely determine whether this expired product can be donated.',
//       suggestedAnimals: [],
//       suggestedOrgTypes: [],
//       usedAi: false,
//     );
//   }

//   // ===========================================================================
//   // GOOGLE PLACES
//   // ===========================================================================

//   static Future<List<DonationCenter>>
//       findNearbyDonationCenters({
//     required double latitude,
//     required double longitude,
//     required List<String> orgTypes,
//     int radiusMeters = 10000,
//   }) async {
//     // -------------------------------------------------------------------------
//     // DEMO MODE
//     // -------------------------------------------------------------------------

//     if (_kGooglePlacesApiKey ==
//         'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
//       return _mockDonationCenters(
//         latitude,
//         longitude,
//         orgTypes,
//       );
//     }

//     try {
//       final keywords =
//           orgTypes.join('|');

//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
//         '?location=$latitude,$longitude'
//         '&radius=$radiusMeters'
//         '&keyword=${Uri.encodeComponent(keywords)}'
//         '&key=$_kGooglePlacesApiKey',
//       );

//       final response =
//           await http
//               .get(url)
//               .timeout(_timeout);

//       if (response.statusCode ==
//           200) {
//         final data =
//             jsonDecode(
//           response.body,
//         ) as Map<String, dynamic>;

//         final results =
//             data['results'];

//         if (results is! List) {
//           return _mockDonationCenters(
//             latitude,
//             longitude,
//             orgTypes,
//           );
//         }

//         return results
//             .take(6)
//             .map(
//           (place) {
//             final placeMap =
//                 place
//                     as Map<String, dynamic>;

//             final geometry =
//                 placeMap['geometry']
//                     as Map<String, dynamic>;

//             final location =
//                 geometry['location']
//                     as Map<String, dynamic>;

//             final lat =
//                 (location['lat'] as num)
//                     .toDouble();

//             final lng =
//                 (location['lng'] as num)
//                     .toDouble();

//             return DonationCenter(
//               name:
//                   placeMap['name']
//                           ?.toString() ??
//                       'Unknown Center',
//               type: _inferType(
//                 placeMap['types']
//                         as List<dynamic>? ??
//                     [],
//                 orgTypes,
//               ),
//               address:
//                   (placeMap['vicinity'] ??
//                           placeMap[
//                               'formatted_address'] ??
//                           'Address not available')
//                       .toString(),
//               distanceKm:
//                   _haversineDistance(
//                 latitude,
//                 longitude,
//                 lat,
//                 lng,
//               ),
//               rating:
//                   placeMap['rating'] != null
//                       ? (placeMap['rating']
//                               as num)
//                           .toDouble()
//                       : null,
//               reviewCount:
//                   placeMap[
//                           'user_ratings_total']
//                       as int?,
//               phone: null,
//               lat: lat,
//               lng: lng,
//               placeId:
//                   placeMap['place_id']
//                       ?.toString(),
//             );
//           },
//         ).toList()
//           ..sort(
//             (a, b) =>
//                 a.distanceKm.compareTo(
//               b.distanceKm,
//             ),
//           );
//       }

//       debugPrint(
//         'Google Places HTTP error: '
//         '${response.statusCode}',
//       );
//     } catch (e) {
//       debugPrint(
//         'Google Places error: $e',
//       );
//     }

//     return _mockDonationCenters(
//       latitude,
//       longitude,
//       orgTypes,
//     );
//   }

//   // ===========================================================================
//   // INFER GOOGLE PLACE TYPE
//   // ===========================================================================

//   static String _inferType(
//     List<dynamic> types,
//     List<String> orgTypes,
//   ) {
//     final text =
//         types
//             .map(
//               (type) =>
//                   type
//                       .toString()
//                       .toLowerCase(),
//             )
//             .join(' ');

//     if (text.contains(
//       'veterinary',
//     )) {
//       return 'Animal Shelter';
//     }

//     if (text.contains(
//           'restaurant',
//         ) ||
//         text.contains(
//           'meal',
//         )) {
//       if (orgTypes.contains(
//         'Community Kitchen',
//       )) {
//         return 'Community Kitchen';
//       }
//     }

//     if (text.contains(
//           'church',
//         ) ||
//         text.contains(
//           'mosque',
//         ) ||
//         text.contains(
//           'temple',
//         )) {
//       if (orgTypes.contains(
//         'NGO',
//       )) {
//         return 'NGO';
//       }
//     }

//     if (orgTypes.isNotEmpty) {
//       return orgTypes.first;
//     }

//     return 'Donation Center';
//   }

//   // ===========================================================================
//   // MOCK DONATION CENTERS
//   // ===========================================================================

//   static List<DonationCenter>
//       _mockDonationCenters(
//     double latitude,
//     double longitude,
//     List<String> orgTypes,
//   ) {
//     final centers =
//         <DonationCenter>[];

//     final primaryType =
//         orgTypes.isNotEmpty
//             ? orgTypes.first
//             : 'Animal Shelter';

//     final secondType =
//         orgTypes.length > 1
//             ? orgTypes[1]
//             : 'NGO';

//     final thirdType =
//         orgTypes.length > 2
//             ? orgTypes[2]
//             : primaryType;

//     centers.add(
//       DonationCenter(
//         name:
//             'Shri Gopal Gaushala',
//         type:
//             orgTypes.contains(
//               'Gaushala',
//             )
//                 ? 'Gaushala'
//                 : primaryType,
//         address:
//             'Demo Road, Near Local Market',
//         distanceKm: 2.4,
//         rating: 4.5,
//         reviewCount: 128,
//         phone:
//             '+91 98765 43210',
//         lat:
//             latitude + 0.015,
//         lng:
//             longitude + 0.010,
//         placeId:
//             'demo_gaushala',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Happy Paws Animal Shelter',
//         type:
//             orgTypes.contains(
//               'Animal Shelter',
//             )
//                 ? 'Animal Shelter'
//                 : secondType,
//         address:
//             'Green Park, Community Road',
//         distanceKm: 3.8,
//         rating: 4.3,
//         reviewCount: 94,
//         phone:
//             '+91 98765 12345',
//         lat:
//             latitude - 0.020,
//         lng:
//             longitude + 0.014,
//         placeId:
//             'demo_animal_shelter',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Sunrise Dairy & Cattle Farm',
//         type:
//             orgTypes.contains(
//               'Dairy Farm',
//             )
//                 ? 'Dairy Farm'
//                 : thirdType,
//         address:
//             'Village Road, Outer Area',
//         distanceKm: 5.1,
//         rating: 4.6,
//         reviewCount: 76,
//         phone:
//             '+91 99887 66554',
//         lat:
//             latitude + 0.035,
//         lng:
//             longitude - 0.018,
//         placeId:
//             'demo_dairy',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'City Food Bank & NGO',
//         type:
//             orgTypes.contains(
//               'Food Bank',
//             )
//                 ? 'Food Bank'
//                 : 'NGO',
//         address:
//             'Community Center, Main Road',
//         distanceKm: 6.3,
//         rating: 4.7,
//         reviewCount: 211,
//         phone:
//             '+91 91234 56789',
//         lat:
//             latitude - 0.030,
//         lng:
//             longitude - 0.025,
//         placeId:
//             'demo_food_bank',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Prani Mitra Animal Care',
//         type:
//             'Animal Shelter',
//         address:
//             'Sector 12, Animal Care Road',
//         distanceKm: 7.2,
//         rating: 4.4,
//         reviewCount: 61,
//         phone:
//             '+91 90000 11111',
//         lat:
//             latitude + 0.040,
//         lng:
//             longitude + 0.025,
//         placeId:
//             'demo_prani_mitra',
//       ),
//     );

//     centers.sort(
//       (a, b) =>
//           a.distanceKm.compareTo(
//         b.distanceKm,
//       ),
//     );

//     return centers
//         .take(5)
//         .toList();
//   }

//   // ===========================================================================
//   // HAVERSINE DISTANCE
//   // ===========================================================================

//   static double _haversineDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const earthRadiusKm =
//         6371.0;

//     final dLat =
//         _toRadians(
//       lat2 - lat1,
//     );

//     final dLon =
//         _toRadians(
//       lon2 - lon1,
//     );

//     final lat1Rad =
//         _toRadians(lat1);

//     final lat2Rad =
//         _toRadians(lat2);

//     final sinLat =
//         math.sin(dLat / 2);

//     final sinLon =
//         math.sin(dLon / 2);

//     final a =
//         sinLat * sinLat +
//             math.cos(lat1Rad) *
//                 math.cos(lat2Rad) *
//                 sinLon *
//                 sinLon;

//     final c =
//         2 *
//             math.atan2(
//               math.sqrt(a),
//               math.sqrt(
//                 1 - a,
//               ),
//             );

//     return earthRadiusKm * c;
//   }

//   static double _toRadians(
//     double degrees,
//   ) {
//     return degrees *
//         math.pi /
//         180.0;
//   }

//   // ===========================================================================
//   // CATEGORY HELPER
//   // ===========================================================================

//   static bool _containsAny(
//     String value,
//     List<String> keywords,
//   ) {
//     return keywords.any(
//       (keyword) =>
//           value.contains(
//         keyword,
//       ),
//     );
//   }
// }

// // =============================================================================
// // DONATION CENTER MODEL
// // =============================================================================

// class DonationCenter {
//   final String name;
//   final String type;
//   final String address;
//   final double distanceKm;
//   final double? rating;
//   final int? reviewCount;
//   final String? phone;
//   final double lat;
//   final double lng;
//   final String? placeId;

//   DonationCenter({
//     required this.name,
//     required this.type,
//     required this.address,
//     required this.distanceKm,
//     required this.rating,
//     required this.reviewCount,
//     required this.phone,
//     required this.lat,
//     required this.lng,
//     required this.placeId,
//   });

//   String get googleMapsUrl {
//     if (placeId != null &&
//         placeId!.isNotEmpty) {
//       return 'https://www.google.com/maps/search/?api=1'
//           '&query=${Uri.encodeComponent(name)}'
//           '&query_place_id=$placeId';
//     }

//     return 'https://www.google.com/maps/search/?api=1'
//         '&query=$lat,$lng';
//   }
// }

// // =============================================================================
// // GEMINI DONATION RESULT
// // =============================================================================

// class GeminiDonationResult {
//   final bool isSuitable;

//   final String donationCategory;

//   final String reason;

//   final List<String>
//       suggestedAnimals;

//   final List<String>
//       suggestedOrgTypes;

//   final bool usedAi;

//   GeminiDonationResult({
//     required this.isSuitable,
//     required this.donationCategory,
//     required this.reason,
//     required this.suggestedAnimals,
//     required this.suggestedOrgTypes,
//     required this.usedAi,
//   });
// }

//version 4- cloud fun -x

// import 'dart:convert';
// import 'dart:math' as math;

// import 'package:firebase_ai/firebase_ai.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// import '../models/product_model.dart';

// class DonationService {
//   // ===========================================================================
//   // GOOGLE PLACES API KEY
//   // ===========================================================================
//   //
//   // Keep your existing Google Places API key here.
//   //
//   // If you keep the placeholder, demo donation centers will be returned.
//   //
//   static const String _kGooglePlacesApiKey =
//       'YOUR_GOOGLE_PLACES_API_KEY_HERE';

//   static const Duration _timeout =
//       Duration(seconds: 45);

//   // ===========================================================================
//   // GEMINI DONATION ASSESSMENT
//   // ===========================================================================

//   static Future<GeminiDonationResult>
//     assessDonationSuitability(
//   ProductModel product,
// ) async {
//   const cloudFunctionUrl =
//       'https://asia-south2-smartshelf-4b145.cloudfunctions.net/checkDonationEligibility';

//   try {
//     /* -----------------------------------------------------------------------
//        GET CURRENT FIREBASE USER
//        ----------------------------------------------------------------------- */

//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       throw Exception(
//         'You must be logged in to check donation suitability.',
//       );
//     }

//     /* -----------------------------------------------------------------------
//        GET FRESH FIREBASE ID TOKEN
//        ----------------------------------------------------------------------- */

//     final idToken = await user.getIdToken(true);

//     if (idToken == null || idToken.isEmpty) {
//       throw Exception(
//         'Unable to obtain Firebase authentication token.',
//       );
//     }

//     /* -----------------------------------------------------------------------
//        DETERMINE SMARTSHELF STATUS
//        ----------------------------------------------------------------------- */

//     final daysRemaining = product.daysRemaining;

//     String statusCategory;

//     if (product.isExpired) {
//       statusCategory = 'Expired';
//     } else if (product.isExpiringSoon) {
//       statusCategory = 'Expiring Soon';
//     } else {
//       statusCategory = 'Fresh';
//     }

//     debugPrint('========================================');
//     debugPrint('DONATION SUITABILITY REQUEST');
//     debugPrint('Product: ${product.name}');
//     debugPrint('Product category: ${product.category}');
//     debugPrint('Status category: $statusCategory');
//     debugPrint('Expiry date: ${product.expiryDate}');
//     debugPrint('Days remaining: $daysRemaining');
//     debugPrint('Using Cloud Function: true');
//     debugPrint('Using Gemini key from Flutter: false');
//     debugPrint('========================================');

//     /* -----------------------------------------------------------------------
//        REQUEST BODY
//        ----------------------------------------------------------------------- */

//     final requestBody = {
//       'productName': product.name,
//       'productCategory': product.category,
//       'statusCategory': statusCategory,
//       'brand': product.brand ?? '',
//       'quantity': product.quantity,
//       'expiryDate': product.expiryDate.toIso8601String(),
//       'daysRemaining': daysRemaining,
//     };

//     /* -----------------------------------------------------------------------
//        CALL CLOUD FUNCTION
//        ----------------------------------------------------------------------- */

//     final response = await http
//         .post(
//           Uri.parse(cloudFunctionUrl),
//           headers: {
//             'Content-Type': 'application/json',
//             'Authorization': 'Bearer $idToken',
//           },
//           body: jsonEncode(requestBody),
//         )
//         .timeout(
//           const Duration(seconds: 60),
//         );

//     debugPrint(
//       'Donation Cloud Function status: '
//       '${response.statusCode}',
//     );

//     debugPrint(
//       'Donation Cloud Function response: '
//       '${response.body}',
//     );

//     /* -----------------------------------------------------------------------
//        HTTP ERROR
//        ----------------------------------------------------------------------- */

//     if (response.statusCode != 200) {
//       String errorMessage =
//           'Donation suitability request failed.';

//       try {
//         final errorData =
//             jsonDecode(response.body);

//         if (errorData is Map<String, dynamic> &&
//             errorData['error'] != null) {
//           errorMessage =
//               errorData['error'].toString();
//         }
//       } catch (_) {
//         // Keep default error message.
//       }

//       throw Exception(
//         '$errorMessage '
//         '(HTTP ${response.statusCode})',
//       );
//     }

//     /* -----------------------------------------------------------------------
//        PARSE RESPONSE
//        ----------------------------------------------------------------------- */

//     final decoded =
//         jsonDecode(response.body);

//     if (decoded is! Map<String, dynamic>) {
//       throw Exception(
//         'Cloud Function returned an invalid response.',
//       );
//     }

//     if (decoded['success'] != true) {
//       throw Exception(
//         decoded['error']?.toString() ??
//             'Donation suitability check failed.',
//       );
//     }

//     final result =
//         decoded['result'];

//     if (result is! Map<String, dynamic>) {
//       throw Exception(
//         'Cloud Function returned invalid donation result.',
//       );
//     }

//     /* -----------------------------------------------------------------------
//        CONSUMABLE
//        ----------------------------------------------------------------------- */

//     final consumable =
//         result['consumable'] == true;

//     /* -----------------------------------------------------------------------
//        DECISION
//        ----------------------------------------------------------------------- */

//     final decision =
//         result['decision']?.toString().trim();

//     /* -----------------------------------------------------------------------
//        REASON
//        ----------------------------------------------------------------------- */

//     final reason =
//         result['reason']?.toString().trim();

//     if (reason == null || reason.isEmpty) {
//       throw Exception(
//         'Gemini did not provide a donation suitability reason.',
//       );
//     }

//     /* -----------------------------------------------------------------------
//        MAP TO EXISTING DONATION MODEL
//        -----------------------------------------------------------------------

//        We keep your existing GeminiDonationResult so the existing UI does not
//        need to be redesigned.

//        For now:

//        Consumable:
//          human_consumption

//        Not consumable:
//          unsafe

//        We intentionally leave organization types empty because you said that
//        donation-place/Serp work will be handled later.
//        ----------------------------------------------------------------------- */

//     final donationCategory =
//         consumable
//             ? 'human_consumption'
//             : 'unsafe';

//     final resultModel =
//         GeminiDonationResult(
//       isSuitable: consumable,
//       donationCategory: donationCategory,
//       reason: reason,
//       suggestedAnimals: const [],
//       suggestedOrgTypes: const [],
//       usedAi: decoded['usedAi'] == true,
//     );

//     /* -----------------------------------------------------------------------
//        LOG FINAL RESULT
//        ----------------------------------------------------------------------- */

//     debugPrint('========================================');
//     debugPrint('DONATION SUITABILITY RESULT');
//     debugPrint(
//       'Product: ${product.name}',
//     );
//     debugPrint(
//       'Status category: $statusCategory',
//     );
//     debugPrint(
//       'Consumable: $consumable',
//     );
//     debugPrint(
//       'Decision: ${decision ?? 'Not provided'}',
//     );
//     debugPrint(
//       'Reason: $reason',
//     );
//     debugPrint(
//       'Used Gemini: ${resultModel.usedAi}',
//     );
//     debugPrint('========================================');

//     return resultModel;
//   } catch (e, stackTrace) {
//     debugPrint('========================================');
//     debugPrint('DONATION SUITABILITY ERROR');
//     debugPrint(
//       'Product: ${product.name}',
//     );
//     debugPrint(
//       'Error: $e',
//     );
//     debugPrint(
//       'Stack trace: $stackTrace',
//     );
//     debugPrint('========================================');

//     /*
//      * IMPORTANT:
//      *
//      * We are NOT pretending that a hard-coded answer came from Gemini.
//      *
//      * If Cloud Function/Gemini fails, return an unsafe result with
//      * usedAi = false.
//      */

//     return GeminiDonationResult(
//       isSuitable: false,
//       donationCategory: 'unknown',
//       reason:
//           'Donation suitability could not be verified by Gemini. '
//           'Please try again.',
//       suggestedAnimals: const [],
//       suggestedOrgTypes: const [],
//       usedAi: false,
//     );
//   }
// }

//     // -------------------------------------------------------------------------
//     // GEMINI RESPONSE SCHEMA
//     // -------------------------------------------------------------------------

//     final donationSchema = Schema.object(
//       properties: {
//         'isSuitable': Schema.boolean(),

//         'donationCategory': Schema.enumString(
//           enumValues: [
//             'human_consumption',
//             'animal_feed',
//             'non_food_use',
//             'unsafe',
//             'unknown',
//           ],
//         ),

//         'reason': Schema.string(),

//         'suggestedAnimals': Schema.array(
//           items: Schema.string(),
//         ),

//         'suggestedOrgTypes': Schema.array(
//           items: Schema.enumString(
//             enumValues: [
//               'Gaushala',
//               'Animal Shelter',
//               'Poultry Farm',
//               'Dairy Farm',
//               'Cattle Shelter',
//               'Food Bank',
//               'Community Kitchen',
//               'NGO',
//             ],
//           ),
//         ),
//       },
//     );

//     // -------------------------------------------------------------------------
//     // FIREBASE AI LOGIC MODEL
//     // -------------------------------------------------------------------------

//     final model =
//         FirebaseAI.googleAI().generativeModel(
//       model: 'gemini-3.6-flash',
//       generationConfig:
//           GenerationConfig(
//         temperature: 0.2,

//         // Increased from 512 because your previous JSON response
//         // was getting truncated.
//         maxOutputTokens: 1024,

//         responseMimeType:
//             'application/json',

//         responseSchema:
//             donationSchema,
//       ),
//     );

//     // -------------------------------------------------------------------------
//     // EXPIRY STATUS
//     // -------------------------------------------------------------------------

//     String expiryStatus;

//     if (daysRemaining > 0) {
//       expiryStatus =
//           'The product has NOT expired. '
//           'It expires in $daysRemaining '
//           '${daysRemaining == 1 ? 'day' : 'days'}.';
//     } else if (daysRemaining == 0) {
//       expiryStatus =
//           'The product expires TODAY.';
//     } else {
//       final daysExpired =
//           daysRemaining.abs();

//       expiryStatus =
//           'The product expired $daysExpired '
//           '${daysExpired == 1 ? 'day' : 'days'} ago.';
//     }

//     // -------------------------------------------------------------------------
//     // GEMINI PROMPT
//     // -------------------------------------------------------------------------
//     //
//     // Keep this relatively short because the output only needs structured JSON.
//     //

//     final prompt = '''
// You are SmartShelf's donation-safety assistant.

// Analyze this grocery product and determine whether it could potentially be
// donated.

// EXPIRY STATUS:
// $expiryStatus

// PRODUCT:
// Name: ${product.name}
// Category: ${product.category}
// Brand: ${product.brand ?? 'Unknown'}
// Quantity: ${product.quantity} units
// Expiry date: ${product.expiryDate.toIso8601String()}
// Days remaining: $daysRemaining

// RULES:

// 1. A product that has NOT expired can be proactively donated.

// 2. A product that expires today can be donated immediately if its condition
//    is acceptable.

// 3. An expired product must be evaluated conservatively.

// 4. Do not claim an expired product is definitely safe.

// 5. Consider mold, spoilage, contamination, rancidity and other safety risks.

// 6. If potentially suitable as animal feed, suggest realistic animals.

// 7. If still suitable for human consumption, suggest Food Bank,
//    Community Kitchen or NGO.

// 8. If suitable for animal feed, suggest relevant organizations such as
//    Gaushala, Animal Shelter, Poultry Farm, Dairy Farm or Cattle Shelter.

// 9. If unsafe or insufficient information exists:
//    isSuitable must be false,
//    suggestedAnimals must be [],
//    suggestedOrgTypes must be [].

// 10. Only use these donation categories:
// human_consumption
// animal_feed
// non_food_use
// unsafe
// unknown

// 11. Only use these organization types:
// Gaushala
// Animal Shelter
// Poultry Farm
// Dairy Farm
// Cattle Shelter
// Food Bank
// Community Kitchen
// NGO

// Return ONLY valid JSON matching the provided schema.
// ''';

//     // =========================================================================
//     // GEMINI REQUEST
//     // =========================================================================

//     try {
//       final response = await model
//           .generateContent([
//         Content.text(prompt),
//       ])
//           .timeout(_timeout);

//       // -----------------------------------------------------------------------
//       // LOG RAW GEMINI RESPONSE
//       // -----------------------------------------------------------------------

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       debugPrint(
//         'GEMINI RESPONSE RECEIVED',
//       );

//       debugPrint(
//         'Product: ${product.name}',
//       );

//       debugPrint(
//         'Category: ${product.category}',
//       );

//       debugPrint(
//         'Days remaining: $daysRemaining',
//       );

//       debugPrint(
//         'Response text:',
//       );

//       debugPrint(
//         response.text,
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // -----------------------------------------------------------------------
//       // CHECK EMPTY RESPONSE
//       // -----------------------------------------------------------------------

//       final text =
//           response.text;

//       if (text == null ||
//           text.trim().isEmpty) {
//         throw Exception(
//           'Gemini returned an empty response',
//         );
//       }

//       // -----------------------------------------------------------------------
//       // CLEAN RESPONSE
//       // -----------------------------------------------------------------------

//       String cleanedText =
//           text.trim();

//       // Remove Markdown JSON fences if Gemini ever returns them.

//       if (cleanedText
//           .startsWith('```json')) {
//         cleanedText =
//             cleanedText.substring(
//           7,
//         );
//       }

//       if (cleanedText
//           .startsWith('```')) {
//         cleanedText =
//             cleanedText.substring(
//           3,
//         );
//       }

//       if (cleanedText
//           .endsWith('```')) {
//         cleanedText =
//             cleanedText.substring(
//           0,
//           cleanedText.length - 3,
//         );
//       }

//       cleanedText =
//           cleanedText.trim();

//       debugPrint(
//         'CLEANED GEMINI JSON:',
//       );

//       debugPrint(
//         cleanedText,
//       );

//       // -----------------------------------------------------------------------
//       // PARSE JSON
//       // -----------------------------------------------------------------------

//       final decoded =
//           jsonDecode(cleanedText);

//       if (decoded
//           is! Map<String, dynamic>) {
//         throw Exception(
//           'Gemini response was not a JSON object',
//         );
//       }

//       // -----------------------------------------------------------------------
//       // IS SUITABLE
//       // -----------------------------------------------------------------------

//       final isSuitable =
//           decoded['isSuitable'] == true;

//       // -----------------------------------------------------------------------
//       // DONATION CATEGORY
//       // -----------------------------------------------------------------------

//       final rawCategory =
//           decoded['donationCategory']
//               ?.toString()
//               .trim();

//       const validCategories = {
//         'human_consumption',
//         'animal_feed',
//         'non_food_use',
//         'unsafe',
//         'unknown',
//       };

//       final donationCategory =
//           validCategories.contains(
//         rawCategory,
//       )
//               ? rawCategory!
//               : 'unknown';

//       // -----------------------------------------------------------------------
//       // REASON
//       // -----------------------------------------------------------------------

//       final rawReason =
//           decoded['reason']
//               ?.toString()
//               .trim();

//       final reason =
//           rawReason == null ||
//                   rawReason.isEmpty
//               ? 'Gemini did not provide a reason.'
//               : rawReason;

//       // -----------------------------------------------------------------------
//       // SUGGESTED ANIMALS
//       // -----------------------------------------------------------------------

//       List<String>
//           suggestedAnimals = [];

//       final rawAnimals =
//           decoded['suggestedAnimals'];

//       if (rawAnimals is List) {
//         suggestedAnimals =
//             rawAnimals
//                 .map(
//                   (item) =>
//                       item.toString().trim(),
//                 )
//                 .where(
//                   (item) =>
//                       item.isNotEmpty,
//                 )
//                 .toSet()
//                 .toList();
//       }

//       // -----------------------------------------------------------------------
//       // SUGGESTED ORGANIZATION TYPES
//       // -----------------------------------------------------------------------

//       const validOrgTypes = {
//         'Gaushala',
//         'Animal Shelter',
//         'Poultry Farm',
//         'Dairy Farm',
//         'Cattle Shelter',
//         'Food Bank',
//         'Community Kitchen',
//         'NGO',
//       };

//       List<String>
//           suggestedOrgTypes = [];

//       final rawOrgTypes =
//           decoded['suggestedOrgTypes'];

//       if (rawOrgTypes is List) {
//         suggestedOrgTypes =
//             rawOrgTypes
//                 .map(
//                   (item) =>
//                       item.toString().trim(),
//                 )
//                 .where(
//                   (item) =>
//                       validOrgTypes.contains(
//                     item,
//                   ),
//                 )
//                 .toSet()
//                 .toList();
//       }

//       // -----------------------------------------------------------------------
//       // SAFETY VALIDATION
//       // -----------------------------------------------------------------------

//       if (!isSuitable ||
//           donationCategory ==
//               'unsafe' ||
//           donationCategory ==
//               'unknown') {
//         suggestedAnimals = [];
//         suggestedOrgTypes = [];
//       }

//       // -----------------------------------------------------------------------
//       // FINAL SUITABILITY
//       // -----------------------------------------------------------------------
//       //
//       // For the Places search we require at least one organization type.
//       //

//       final finalIsSuitable =
//           isSuitable &&
//               suggestedOrgTypes
//                   .isNotEmpty;

//       // -----------------------------------------------------------------------
//       // LOG PARSED RESULT
//       // -----------------------------------------------------------------------

//       debugPrint(
//         'GEMINI PARSED RESULT',
//       );

//       debugPrint(
//         'isSuitable: $finalIsSuitable',
//       );

//       debugPrint(
//         'donationCategory: $donationCategory',
//       );

//       debugPrint(
//         'reason: $reason',
//       );

//       debugPrint(
//         'suggestedAnimals: $suggestedAnimals',
//       );

//       debugPrint(
//         'suggestedOrgTypes: $suggestedOrgTypes',
//       );

//       debugPrint(
//         'usedAi: true',
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // -----------------------------------------------------------------------
//       // RETURN RESULT
//       // -----------------------------------------------------------------------

//       return GeminiDonationResult(
//         isSuitable:
//             finalIsSuitable,
//         donationCategory:
//             donationCategory,
//         reason:
//             reason,
//         suggestedAnimals:
//             suggestedAnimals,
//         suggestedOrgTypes:
//             suggestedOrgTypes,
//         usedAi: true,
//       );
//     }

//     // =========================================================================
//     // GEMINI ERROR
//     // =========================================================================

//     catch (e, stackTrace) {
//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       debugPrint(
//         'SMARTSHELF GEMINI ERROR',
//       );

//       debugPrint(
//         'Product: ${product.name}',
//       );

//       debugPrint(
//         'Category: ${product.category}',
//       );

//       debugPrint(
//         'Days remaining: ${product.daysRemaining}',
//       );

//       debugPrint(
//         'Error: $e',
//       );

//       debugPrint(
//         'Stack trace: $stackTrace',
//       );

//       debugPrint(
//         '════════════════════════════════════════',
//       );

//       // Only use the rule-based fallback when Gemini actually fails.
//       return _fallbackGeminiResult(
//         product,
//       );
//     }
//   }

//   // ===========================================================================
//   // FALLBACK RESULT
//   // ===========================================================================
//   //
//   // This is NOT used when Gemini works.
//   // It is only used when the Gemini request or JSON parsing fails.
//   //

//   static GeminiDonationResult
//       _fallbackGeminiResult(
//     ProductModel product,
//   ) {
//     final daysRemaining =
//         product.daysRemaining;

//     final category =
//         product.category.toLowerCase();

//     // -------------------------------------------------------------------------
//     // FUTURE PRODUCT
//     // -------------------------------------------------------------------------

//     if (daysRemaining > 0) {
//       // Dry / bakery products
//       if (_containsAny(
//         category,
//         [
//           'grain',
//           'cereal',
//           'flour',
//           'rice',
//           'wheat',
//           'bakery',
//           'bread',
//           'biscuit',
//           'cookie',
//           'cracker',
//           'snack',
//           'chips',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'animal_feed',
//           reason:
//               'Gemini was unavailable. This product has not expired and may potentially be redirected to an appropriate animal-feed organization before expiry. The receiving organization should inspect it before accepting it.',
//           suggestedAnimals: [
//             'Cattle',
//             'Goats',
//             'Chickens',
//             'Poultry',
//           ],
//           suggestedOrgTypes: [
//             'Gaushala',
//             'Cattle Shelter',
//             'Poultry Farm',
//             'Animal Shelter',
//           ],
//           usedAi: false,
//         );
//       }

//       // Fruit / vegetables
//       if (_containsAny(
//         category,
//         [
//           'fruit',
//           'vegetable',
//           'produce',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'animal_feed',
//           reason:
//               'This product has not expired and may potentially be donated as animal feed if it remains in acceptable condition.',
//           suggestedAnimals: [
//             'Cattle',
//             'Goats',
//             'Poultry',
//           ],
//           suggestedOrgTypes: [
//             'Gaushala',
//             'Cattle Shelter',
//             'Animal Shelter',
//           ],
//           usedAi: false,
//         );
//       }

//       // Dairy / beverages
//       if (_containsAny(
//         category,
//         [
//           'dairy',
//           'milk',
//           'beverage',
//         ],
//       )) {
//         return GeminiDonationResult(
//           isSuitable: true,
//           donationCategory:
//               'human_consumption',
//           reason:
//               'This product has not expired yet and may potentially be donated for human consumption if it is unopened, properly stored, and safe.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [
//             'Food Bank',
//             'Community Kitchen',
//             'NGO',
//           ],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: false,
//         donationCategory:
//             'unknown',
//         reason:
//             'Gemini could not be reached, so there is not enough information to safely classify this product for donation.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // -------------------------------------------------------------------------
//     // EXPIRES TODAY
//     // -------------------------------------------------------------------------

//     if (daysRemaining == 0) {
//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'human_consumption',
//         reason:
//             'This product expires today. It may potentially be donated immediately if its packaging, storage conditions, and physical condition are acceptable.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [
//           'Food Bank',
//           'Community Kitchen',
//           'NGO',
//         ],
//         usedAi: false,
//       );
//     }

//     // -------------------------------------------------------------------------
//     // EXPIRED PRODUCT
//     // -------------------------------------------------------------------------

//     final daysExpired =
//         daysRemaining.abs();

//     // High-risk categories
//     if (_containsAny(
//       category,
//       [
//         'milk',
//         'dairy',
//         'meat',
//         'fish',
//         'seafood',
//         'chicken',
//         'egg',
//         'eggs',
//       ],
//     )) {
//       return GeminiDonationResult(
//         isSuitable: false,
//         donationCategory:
//             'unsafe',
//         reason:
//             'This product has expired $daysExpired ${daysExpired == 1 ? 'day' : 'days'} ago and belongs to a highly perishable category. Without inspection and additional safety information, it should not be recommended for donation or animal consumption.',
//         suggestedAnimals: [],
//         suggestedOrgTypes: [],
//         usedAi: false,
//       );
//     }

//     // Bakery / dry food
//     if (_containsAny(
//       category,
//       [
//         'bakery',
//         'bread',
//         'biscuit',
//         'cookie',
//         'cracker',
//         'cake',
//         'pastry',
//         'grain',
//         'cereal',
//         'flour',
//         'rice',
//         'wheat',
//         'snack',
//         'chips',
//       ],
//     )) {
//       if (daysExpired > 14) {
//         return GeminiDonationResult(
//           isSuitable: false,
//           donationCategory:
//               'unsafe',
//           reason:
//               'This product has been expired for more than two weeks. Without reliable information about its current condition and storage, it should not be recommended for donation.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'animal_feed',
//         reason:
//             'This dry or bakery product has expired $daysExpired ${daysExpired == 1 ? 'day' : 'days'} ago. It may potentially be repurposed as animal feed only if it has no mold, insects, contamination, unusual odor, rancidity, or other signs of spoilage. The receiving organization must make the final decision.',
//         suggestedAnimals: [
//           'Cattle',
//           'Goats',
//           'Chickens',
//           'Poultry',
//         ],
//         suggestedOrgTypes: [
//           'Gaushala',
//           'Cattle Shelter',
//           'Poultry Farm',
//           'Animal Shelter',
//         ],
//         usedAi: false,
//       );
//     }

//     // Fruit / vegetables
//     if (_containsAny(
//       category,
//       [
//         'fruit',
//         'vegetable',
//         'produce',
//       ],
//     )) {
//       if (daysExpired > 7) {
//         return GeminiDonationResult(
//           isSuitable: false,
//           donationCategory:
//               'unsafe',
//           reason:
//               'This produce has been expired for $daysExpired days. Without knowing its current physical condition, it should not be recommended for donation.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       return GeminiDonationResult(
//         isSuitable: true,
//         donationCategory:
//             'animal_feed',
//         reason:
//             'Some expired produce may potentially be used as animal feed if it is free from mold, toxic substances, severe decomposition, and contamination. The receiving organization must inspect it before accepting it.',
//         suggestedAnimals: [
//           'Cattle',
//           'Goats',
//           'Poultry',
//         ],
//         suggestedOrgTypes: [
//           'Gaushala',
//           'Cattle Shelter',
//           'Animal Shelter',
//         ],
//         usedAi: false,
//       );
//     }

//     // Unknown
//     return GeminiDonationResult(
//       isSuitable: false,
//       donationCategory:
//           'unknown',
//       reason:
//           'Gemini could not be reached and there is not enough reliable information to safely determine whether this expired product can be donated.',
//       suggestedAnimals: [],
//       suggestedOrgTypes: [],
//       usedAi: false,
//     );
//   }

//   // ===========================================================================
//   // GOOGLE PLACES
//   // ===========================================================================

//   static Future<List<DonationCenter>>
//       findNearbyDonationCenters({
//     required double latitude,
//     required double longitude,
//     required List<String> orgTypes,
//     int radiusMeters = 10000,
//   }) async {
//     // -------------------------------------------------------------------------
//     // DEMO MODE
//     // -------------------------------------------------------------------------

//     if (_kGooglePlacesApiKey ==
//         'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
//       return _mockDonationCenters(
//         latitude,
//         longitude,
//         orgTypes,
//       );
//     }

//     try {
//       final keywords =
//           orgTypes.join('|');

//       final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
//         '?location=$latitude,$longitude'
//         '&radius=$radiusMeters'
//         '&keyword=${Uri.encodeComponent(keywords)}'
//         '&key=$_kGooglePlacesApiKey',
//       );

//       final response =
//           await http
//               .get(url)
//               .timeout(_timeout);

//       if (response.statusCode ==
//           200) {
//         final data =
//             jsonDecode(
//           response.body,
//         ) as Map<String, dynamic>;

//         final results =
//             data['results'];

//         if (results is! List) {
//           return _mockDonationCenters(
//             latitude,
//             longitude,
//             orgTypes,
//           );
//         }

//         return results
//             .take(6)
//             .map(
//           (place) {
//             final placeMap =
//                 place
//                     as Map<String, dynamic>;

//             final geometry =
//                 placeMap['geometry']
//                     as Map<String, dynamic>;

//             final location =
//                 geometry['location']
//                     as Map<String, dynamic>;

//             final lat =
//                 (location['lat'] as num)
//                     .toDouble();

//             final lng =
//                 (location['lng'] as num)
//                     .toDouble();

//             return DonationCenter(
//               name:
//                   placeMap['name']
//                           ?.toString() ??
//                       'Unknown Center',
//               type: _inferType(
//                 placeMap['types']
//                         as List<dynamic>? ??
//                     [],
//                 orgTypes,
//               ),
//               address:
//                   (placeMap['vicinity'] ??
//                           placeMap[
//                               'formatted_address'] ??
//                           'Address not available')
//                       .toString(),
//               distanceKm:
//                   _haversineDistance(
//                 latitude,
//                 longitude,
//                 lat,
//                 lng,
//               ),
//               rating:
//                   placeMap['rating'] != null
//                       ? (placeMap['rating']
//                               as num)
//                           .toDouble()
//                       : null,
//               reviewCount:
//                   placeMap[
//                           'user_ratings_total']
//                       as int?,
//               phone: null,
//               lat: lat,
//               lng: lng,
//               placeId:
//                   placeMap['place_id']
//                       ?.toString(),
//             );
//           },
//         ).toList()
//           ..sort(
//             (a, b) =>
//                 a.distanceKm.compareTo(
//               b.distanceKm,
//             ),
//           );
//       }

//       debugPrint(
//         'Google Places HTTP error: '
//         '${response.statusCode}',
//       );
//     } catch (e) {
//       debugPrint(
//         'Google Places error: $e',
//       );
//     }

//     return _mockDonationCenters(
//       latitude,
//       longitude,
//       orgTypes,
//     );
//   }

//   // ===========================================================================
//   // INFER GOOGLE PLACE TYPE
//   // ===========================================================================

//   static String _inferType(
//     List<dynamic> types,
//     List<String> orgTypes,
//   ) {
//     final text =
//         types
//             .map(
//               (type) =>
//                   type
//                       .toString()
//                       .toLowerCase(),
//             )
//             .join(' ');

//     if (text.contains(
//       'veterinary',
//     )) {
//       return 'Animal Shelter';
//     }

//     if (text.contains(
//           'restaurant',
//         ) ||
//         text.contains(
//           'meal',
//         )) {
//       if (orgTypes.contains(
//         'Community Kitchen',
//       )) {
//         return 'Community Kitchen';
//       }
//     }

//     if (text.contains(
//           'church',
//         ) ||
//         text.contains(
//           'mosque',
//         ) ||
//         text.contains(
//           'temple',
//         )) {
//       if (orgTypes.contains(
//         'NGO',
//       )) {
//         return 'NGO';
//       }
//     }

//     if (orgTypes.isNotEmpty) {
//       return orgTypes.first;
//     }

//     return 'Donation Center';
//   }

//   // ===========================================================================
//   // MOCK DONATION CENTERS
//   // ===========================================================================

//   static List<DonationCenter>
//       _mockDonationCenters(
//     double latitude,
//     double longitude,
//     List<String> orgTypes,
//   ) {
//     final centers =
//         <DonationCenter>[];

//     final primaryType =
//         orgTypes.isNotEmpty
//             ? orgTypes.first
//             : 'Animal Shelter';

//     final secondType =
//         orgTypes.length > 1
//             ? orgTypes[1]
//             : 'NGO';

//     final thirdType =
//         orgTypes.length > 2
//             ? orgTypes[2]
//             : primaryType;

//     centers.add(
//       DonationCenter(
//         name:
//             'Shri Gopal Gaushala',
//         type:
//             orgTypes.contains(
//               'Gaushala',
//             )
//                 ? 'Gaushala'
//                 : primaryType,
//         address:
//             'Demo Road, Near Local Market',
//         distanceKm: 2.4,
//         rating: 4.5,
//         reviewCount: 128,
//         phone:
//             '+91 98765 43210',
//         lat:
//             latitude + 0.015,
//         lng:
//             longitude + 0.010,
//         placeId:
//             'demo_gaushala',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Happy Paws Animal Shelter',
//         type:
//             orgTypes.contains(
//               'Animal Shelter',
//             )
//                 ? 'Animal Shelter'
//                 : secondType,
//         address:
//             'Green Park, Community Road',
//         distanceKm: 3.8,
//         rating: 4.3,
//         reviewCount: 94,
//         phone:
//             '+91 98765 12345',
//         lat:
//             latitude - 0.020,
//         lng:
//             longitude + 0.014,
//         placeId:
//             'demo_animal_shelter',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Sunrise Dairy & Cattle Farm',
//         type:
//             orgTypes.contains(
//               'Dairy Farm',
//             )
//                 ? 'Dairy Farm'
//                 : thirdType,
//         address:
//             'Village Road, Outer Area',
//         distanceKm: 5.1,
//         rating: 4.6,
//         reviewCount: 76,
//         phone:
//             '+91 99887 66554',
//         lat:
//             latitude + 0.035,
//         lng:
//             longitude - 0.018,
//         placeId:
//             'demo_dairy',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'City Food Bank & NGO',
//         type:
//             orgTypes.contains(
//               'Food Bank',
//             )
//                 ? 'Food Bank'
//                 : 'NGO',
//         address:
//             'Community Center, Main Road',
//         distanceKm: 6.3,
//         rating: 4.7,
//         reviewCount: 211,
//         phone:
//             '+91 91234 56789',
//         lat:
//             latitude - 0.030,
//         lng:
//             longitude - 0.025,
//         placeId:
//             'demo_food_bank',
//       ),
//     );

//     centers.add(
//       DonationCenter(
//         name:
//             'Prani Mitra Animal Care',
//         type:
//             'Animal Shelter',
//         address:
//             'Sector 12, Animal Care Road',
//         distanceKm: 7.2,
//         rating: 4.4,
//         reviewCount: 61,
//         phone:
//             '+91 90000 11111',
//         lat:
//             latitude + 0.040,
//         lng:
//             longitude + 0.025,
//         placeId:
//             'demo_prani_mitra',
//       ),
//     );

//     centers.sort(
//       (a, b) =>
//           a.distanceKm.compareTo(
//         b.distanceKm,
//       ),
//     );

//     return centers
//         .take(5)
//         .toList();
//   }

//   // ===========================================================================
//   // HAVERSINE DISTANCE
//   // ===========================================================================

//   static double _haversineDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const earthRadiusKm =
//         6371.0;

//     final dLat =
//         _toRadians(
//       lat2 - lat1,
//     );

//     final dLon =
//         _toRadians(
//       lon2 - lon1,
//     );

//     final lat1Rad =
//         _toRadians(lat1);

//     final lat2Rad =
//         _toRadians(lat2);

//     final sinLat =
//         math.sin(dLat / 2);

//     final sinLon =
//         math.sin(dLon / 2);

//     final a =
//         sinLat * sinLat +
//             math.cos(lat1Rad) *
//                 math.cos(lat2Rad) *
//                 sinLon *
//                 sinLon;

//     final c =
//         2 *
//             math.atan2(
//               math.sqrt(a),
//               math.sqrt(
//                 1 - a,
//               ),
//             );

//     return earthRadiusKm * c;
//   }

//   static double _toRadians(
//     double degrees,
//   ) {
//     return degrees *
//         math.pi /
//         180.0;
//   }

//   // ===========================================================================
//   // CATEGORY HELPER
//   // ===========================================================================

//   static bool _containsAny(
//     String value,
//     List<String> keywords,
//   ) {
//     return keywords.any(
//       (keyword) =>
//           value.contains(
//         keyword,
//       ),
//     );
//   }
// }

// // =============================================================================
// // DONATION CENTER MODEL
// // =============================================================================

// class DonationCenter {
//   final String name;
//   final String type;
//   final String address;
//   final double distanceKm;
//   final double? rating;
//   final int? reviewCount;
//   final String? phone;
//   final double lat;
//   final double lng;
//   final String? placeId;

//   DonationCenter({
//     required this.name,
//     required this.type,
//     required this.address,
//     required this.distanceKm,
//     required this.rating,
//     required this.reviewCount,
//     required this.phone,
//     required this.lat,
//     required this.lng,
//     required this.placeId,
//   });

//   String get googleMapsUrl {
//     if (placeId != null &&
//         placeId!.isNotEmpty) {
//       return 'https://www.google.com/maps/search/?api=1'
//           '&query=${Uri.encodeComponent(name)}'
//           '&query_place_id=$placeId';
//     }

//     return 'https://www.google.com/maps/search/?api=1'
//         '&query=$lat,$lng';
//   }
// }

// // =============================================================================
// // GEMINI DONATION RESULT
// // =============================================================================

// class GeminiDonationResult {
//   final bool isSuitable;

//   final String donationCategory;

//   final String reason;

//   final List<String>
//       suggestedAnimals;

//   final List<String>
//       suggestedOrgTypes;

//   final bool usedAi;

//   GeminiDonationResult({
//     required this.isSuitable,
//     required this.donationCategory,
//     required this.reason,
//     required this.suggestedAnimals,
//     required this.suggestedOrgTypes,
//     required this.usedAi,
//   });
// }


// version clould 2.0 

// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// import '../models/product_model.dart';

// class DonationService {
//   /* ======================================================================== */
//   /* CONFIGURATION                                                            */
//   /* ======================================================================== */

//   static const Duration _timeout = Duration(seconds: 45);

//   static const String _functionUrl =
//       'https://asia-south2-smartshelf-4b145.cloudfunctions.net/'
//       'checkDonationEligibility';

//   /* ======================================================================== */
//   /* MAIN METHOD USED BY DONATE DIALOG                                       */
//   /* ======================================================================== */

//   static Future<DonationAssessmentResult>
//       assessAndFindDonationOptions({
//     required ProductModel product,
//   }) async {
//     /*
//      * We intentionally do NOT request device/browser location here.
//      *
//      * Current flow:
//      *
//      * Flutter
//      *   ↓
//      * Firebase Auth
//      *   ↓
//      * Cloud Function
//      *   ↓
//      * Gemini
//      *
//      * Donation centers are currently empty because live Places searching
//      * is being deferred.
//      */

//     final donation = await assessDonationSuitability(product);

//     return DonationAssessmentResult(
//       donation: donation,
//       centers: const [],
//     );
//   }

//   /* ======================================================================== */
//   /* GEMINI DONATION SUITABILITY                                             */
//   /* ======================================================================== */

//   static Future<GeminiDonationResult>
//       assessDonationSuitability(
//     ProductModel product,
//   ) async {
//     try {
//       /* -------------------------------------------------------------------- */
//       /* CHECK AUTH                                                           */
//       /* -------------------------------------------------------------------- */

//       final user = FirebaseAuth.instance.currentUser;

//       if (user == null) {
//         return const GeminiDonationResult(
//           isSuitable: false,
//           donationCategory: 'unknown',
//           reason:
//               'Please sign in before checking donation suitability.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* GET FIREBASE AUTH TOKEN                                              */
//       /* -------------------------------------------------------------------- */

//       final idToken = await user.getIdToken(true);

//       if (idToken == null || idToken.trim().isEmpty) {
//         return const GeminiDonationResult(
//           isSuitable: false,
//           donationCategory: 'unknown',
//           reason:
//               'Could not authenticate the donation request. Please sign in again.',
//           suggestedAnimals: [],
//           suggestedOrgTypes: [],
//           usedAi: false,
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* DETERMINE EXPIRY STATUS                                              */
//       /* -------------------------------------------------------------------- */

//       final int daysRemaining = product.daysRemaining;

//       final String statusCategory;

//       if (product.isExpired) {
//         statusCategory = 'Expired';
//       } else if (product.isExpiringSoon) {
//         statusCategory = 'Expiring Soon';
//       } else {
//         statusCategory = 'Fresh';
//       }

//       /* -------------------------------------------------------------------- */
//       /* SAFE BRAND                                                           */
//       /* -------------------------------------------------------------------- */

//       final String brand =
//           (product.brand ?? '').trim();

//       /* -------------------------------------------------------------------- */
//       /* REQUEST BODY                                                         */
//       /* -------------------------------------------------------------------- */

//       final Map<String, dynamic> requestBody = {
//         'productName': product.name,
//         'productCategory': product.category,
//         'statusCategory': statusCategory,
//         'brand': brand,
//         'quantity': product.quantity,
//         'expiryDate': product.expiryDate.toIso8601String(),
//         'daysRemaining': daysRemaining,
//       };

//       if (kDebugMode) {
//         debugPrint(
//           'Donation Gemini request: '
//           '${jsonEncode(requestBody)}',
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* CALL CLOUD FUNCTION                                                  */
//       /* -------------------------------------------------------------------- */

//       final response = await http
//           .post(
//             Uri.parse(_functionUrl),
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $idToken',
//             },
//             body: jsonEncode(requestBody),
//           )
//           .timeout(_timeout);

//       if (kDebugMode) {
//         debugPrint(
//           'Donation Cloud Function status: '
//           '${response.statusCode}',
//         );

//         debugPrint(
//           'Donation Cloud Function response: '
//           '${response.body}',
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* HTTP ERROR                                                           */
//       /* -------------------------------------------------------------------- */

//       if (response.statusCode < 200 ||
//           response.statusCode >= 300) {
//         throw Exception(
//           'Donation analysis service returned '
//           'HTTP ${response.statusCode}.',
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* DECODE RESPONSE                                                      */
//       /* -------------------------------------------------------------------- */

//       final dynamic decoded = jsonDecode(response.body);

//       if (decoded is! Map<String, dynamic>) {
//         throw Exception(
//           'Donation analysis returned an invalid response.',
//         );
//       }

//       if (decoded['success'] != true) {
//         final message =
//             decoded['error']?.toString().trim();

//         throw Exception(
//           message == null || message.isEmpty
//               ? 'Donation analysis failed.'
//               : message,
//         );
//       }

//       final dynamic rawResult = decoded['result'];

//       if (rawResult is! Map<String, dynamic>) {
//         throw Exception(
//           'Donation analysis returned no result.',
//         );
//       }

//       /* -------------------------------------------------------------------- */
//       /* READ GEMINI RESULT                                                   */
//       /* -------------------------------------------------------------------- */

//       final bool isSuitable =
//           rawResult['isSuitable'] == true ||
//           rawResult['consumable'] == true;

//       String donationCategory =
//           _normalizeDonationCategory(
//         rawResult['donationCategory'],
//       );

//       /*
//        * If the backend returns only `decision`/`consumable`,
//        * derive a safe category.
//        */
//       if (donationCategory == 'unknown') {
//         donationCategory =
//             _categoryFromDecision(
//           decision: rawResult['decision'],
//           consumable: isSuitable,
//         );
//       }

//       final String reason =
//           rawResult['reason']?.toString().trim() ??
//               'Gemini did not provide a recommendation.';

//       final List<String> suggestedAnimals =
//           _readStringList(
//         rawResult['suggestedAnimals'],
//       );

//       final List<String> suggestedOrgTypes =
//           _readStringList(
//         rawResult['suggestedOrgTypes'],
//       );

//       final bool usedAi =
//           decoded['usedAi'] == true;

//       return GeminiDonationResult(
//         isSuitable: isSuitable,
//         donationCategory: donationCategory,
//         reason: reason.isEmpty
//             ? 'Gemini did not provide a recommendation.'
//             : reason,
//         suggestedAnimals: suggestedAnimals,
//         suggestedOrgTypes: suggestedOrgTypes,
//         usedAi: usedAi,
//       );
//     } catch (error, stackTrace) {
//       if (kDebugMode) {
//         debugPrint(
//           'Donation suitability error: $error',
//         );

//         debugPrint(
//           '$stackTrace',
//         );
//       }

//       /*
//        * IMPORTANT:
//        *
//        * We do NOT manufacture a Gemini answer here.
//        *
//        * If Gemini/Cloud Function fails, the UI clearly shows
//        * "Analysis Unavailable".
//        */
//       return GeminiDonationResult(
//         isSuitable: false,
//         donationCategory: 'unknown',
//         reason:
//             'Gemini could not verify donation suitability. '
//             'Please try again.',
//         suggestedAnimals: const [],
//         suggestedOrgTypes: const [],
//         usedAi: false,
//       );
//     }
//   }

//   /* ======================================================================== */
//   /* CATEGORY NORMALIZATION                                                  */
//   /* ======================================================================== */

//   static String _normalizeDonationCategory(
//     dynamic value,
//   ) {
//     if (value == null) {
//       return 'unknown';
//     }

//     final String category =
//         value.toString().trim().toLowerCase();

//     switch (category) {
//       case 'animal_feed':
//       case 'animal feed':
//       case 'animal-feed':
//         return 'animal_feed';

//       case 'human_consumption':
//       case 'human consumption':
//       case 'human-consumption':
//       case 'community donation':
//         return 'human_consumption';

//       case 'non_food_use':
//       case 'non food use':
//       case 'non-food-use':
//       case 'non-food':
//         return 'non_food_use';

//       case 'unsafe':
//       case 'not suitable':
//       case 'not_suitable':
//         return 'unsafe';

//       default:
//         return 'unknown';
//     }
//   }

//   /* ======================================================================== */
//   /* CATEGORY FROM DECISION                                                  */
//   /* ======================================================================== */

//   static String _categoryFromDecision({
//     dynamic decision,
//     required bool consumable,
//   }) {
//     final String value =
//         decision?.toString().trim().toLowerCase() ?? '';

//     if (value.contains('animal') ||
//         value.contains('feed') ||
//         value.contains('cattle') ||
//         value.contains('poultry') ||
//         value.contains('livestock')) {
//       return 'animal_feed';
//     }

//     if (value.contains('human') ||
//         value.contains('community') ||
//         value.contains('food bank')) {
//       return 'human_consumption';
//     }

//     if (value.contains('non-food') ||
//         value.contains('non food') ||
//         value.contains('recycling')) {
//       return 'non_food_use';
//     }

//     if (value.contains('unsafe') ||
//         value.contains('not suitable') ||
//         value.contains('reject')) {
//       return 'unsafe';
//     }

//     /*
//      * Do not automatically label every consumable item as
//      * human_consumption unless Gemini explicitly indicates it.
//      */
//     if (!consumable) {
//       return 'unsafe';
//     }

//     return 'unknown';
//   }

//   /* ======================================================================== */
//   /* STRING LIST PARSER                                                       */
//   /* ======================================================================== */

//   static List<String> _readStringList(
//     dynamic value,
//   ) {
//     if (value is! List) {
//       return const [];
//     }

//     return value
//         .map(
//           (item) => item.toString().trim(),
//         )
//         .where(
//           (item) => item.isNotEmpty,
//         )
//         .toList();
//   }

//   /* ======================================================================== */
//   /* GOOGLE MAPS / PLACES                                                     */
//   /* ======================================================================== */

//   /*
//    * Places searching is intentionally deferred.
//    *
//    * Your DonateDialog still expects DonationCenter objects,
//    * so the model is kept below.
//    *
//    * When you are ready to use the city stored in Firestore,
//    * we can add:
//    *
//    * Firebase Auth UID
//    *       ↓
//    * users/{uid}
//    *       ↓
//    * saved city
//    *       ↓
//    * SerpAPI / Google Places
//    *
//    * without changing the DonateDialog UI.
//    */

//   static Future<List<DonationCenter>>
//       findNearbyDonationCenters({
//     required String location,
//     String? donationCategory,
//     int maxResults = 10,
//   }) async {
//     /*
//      * Not used at the moment.
//      *
//      * Returning an empty list prevents the application from
//      * requesting live location or making unnecessary Places
//      * API calls.
//      */
//     return const [];
//   }
// }

// /* ========================================================================== */
// /* DONATION ASSESSMENT RESULT                                                 */
// /* ========================================================================== */

// class DonationAssessmentResult {
//   final GeminiDonationResult donation;

//   final List<DonationCenter> centers;

//   const DonationAssessmentResult({
//     required this.donation,
//     required this.centers,
//   });
// }

// /* ========================================================================== */
// /* GEMINI DONATION RESULT                                                     */
// /* ========================================================================== */

// class GeminiDonationResult {
//   final bool isSuitable;

//   final String donationCategory;

//   final String reason;

//   final List<String> suggestedAnimals;

//   final List<String> suggestedOrgTypes;

//   final bool usedAi;

//   const GeminiDonationResult({
//     required this.isSuitable,
//     required this.donationCategory,
//     required this.reason,
//     required this.suggestedAnimals,
//     required this.suggestedOrgTypes,
//     required this.usedAi,
//   });
// }

// /* ========================================================================== */
// /* DONATION CENTER                                                            */
// /* ========================================================================== */

// class DonationCenter {
//   final String name;

//   final String type;

//   final String address;

//   final String? phone;

//   final double? rating;

//   final int? reviewCount;

//   final double? latitude;

//   final double? longitude;

//   final double? distanceKm;

//   final String? placeId;

//   const DonationCenter({
//     required this.name,
//     required this.type,
//     required this.address,
//     this.phone,
//     this.rating,
//     this.reviewCount,
//     this.latitude,
//     this.longitude,
//     this.distanceKm,
//     this.placeId,
//   });

//   String get googleMapsUrl {
//     /*
//      * If coordinates are eventually supplied, use them.
//      */
//     if (latitude != null && longitude != null) {
//       return 'https://www.google.com/maps/search/?api=1'
//           '&query=$latitude,$longitude';
//     }

//     /*
//      * Otherwise search by name/address.
//      */
//     final query = Uri.encodeComponent(
//       '$name, $address',
//     );

//     return 'https://www.google.com/maps/search/?api=1'
//         '&query=$query';
//   }
// }

// version cloud 3

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class DonationService {
  /* ======================================================================== */
  /* CONFIGURATION                                                            */
  /* ======================================================================== */

  static const Duration _timeout = Duration(seconds: 60);

  /*
   * IMPORTANT:
   *
   * This endpoint must exist in your Firebase Cloud Functions:
   *
   * exports.findDonationPlaces = onRequest(...)
   *
   * The Cloud Function is responsible for:
   *
   * Firebase Auth
   *      ↓
   * Firestore users/{uid}.location
   *      ↓
   * Gemini donation suitability
   *      ↓
   * SerpAPI Google Maps search
   */
  static const String _functionUrl =
      'https://asia-south2-smartshelf-4b145.cloudfunctions.net/'
      'findDonationPlaces';

  /* ======================================================================== */
  /* MAIN METHOD USED BY DONATE DIALOG                                       */
  /* ======================================================================== */

  static Future<DonationAssessmentResult>
      assessAndFindDonationOptions({
    required ProductModel product,
  }) async {
    try {
      /* -------------------------------------------------------------------- */
      /* CHECK AUTH                                                           */
      /* -------------------------------------------------------------------- */

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception(
          'Please sign in before finding donation options.',
        );
      }

      /* -------------------------------------------------------------------- */
      /* GET FIREBASE AUTH TOKEN                                              */
      /* -------------------------------------------------------------------- */

      final String? idToken =
          await user.getIdToken(true);

      if (idToken == null ||
          idToken.trim().isEmpty) {
        throw Exception(
          'Could not authenticate the donation request. '
          'Please sign in again.',
        );
      }

      /* -------------------------------------------------------------------- */
      /* DETERMINE EXPIRY STATUS                                              */
      /* -------------------------------------------------------------------- */

      final int daysRemaining =
          product.daysRemaining;

      final String statusCategory;

      if (product.isExpired) {
        statusCategory = 'Expired';
      } else if (product.isExpiringSoon) {
        statusCategory = 'Expiring Soon';
      } else {
        statusCategory = 'Fresh';
      }

      /* -------------------------------------------------------------------- */
      /* SAFE BRAND                                                           */
      /* -------------------------------------------------------------------- */

      final String brand =
          (product.brand ?? '').trim();

      /* -------------------------------------------------------------------- */
      /* REQUEST BODY                                                         */
      /* -------------------------------------------------------------------- */

      final Map<String, dynamic> requestBody = {
        'productName': product.name,
        'productCategory': product.category,
        'statusCategory': statusCategory,
        'brand': brand,
        'quantity': product.quantity,
        'expiryDate':
            product.expiryDate.toIso8601String(),
        'daysRemaining': daysRemaining,
      };

      if (kDebugMode) {
        debugPrint(
          'Donation request: '
          '${jsonEncode(requestBody)}',
        );
      }

      /* -------------------------------------------------------------------- */
      /* CALL CLOUD FUNCTION                                                  */
      /* -------------------------------------------------------------------- */

      final http.Response response =
          await http
              .post(
                Uri.parse(_functionUrl),
                headers: {
                  'Content-Type':
                      'application/json',
                  'Authorization':
                      'Bearer $idToken',
                },
                body: jsonEncode(requestBody),
              )
              .timeout(_timeout);

      if (kDebugMode) {
        debugPrint(
          'Donation Cloud Function status: '
          '${response.statusCode}',
        );

        debugPrint(
          'Donation Cloud Function response: '
          '${response.body}',
        );
      }

      /* -------------------------------------------------------------------- */
      /* HTTP ERROR                                                           */
      /* -------------------------------------------------------------------- */

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        String errorMessage =
            'Donation service returned '
            'HTTP ${response.statusCode}.';

        try {
          final dynamic errorDecoded =
              jsonDecode(response.body);

          if (errorDecoded
              is Map<String, dynamic>) {
            final String? serverError =
                errorDecoded['error']
                    ?.toString()
                    .trim();

            if (serverError != null &&
                serverError.isNotEmpty) {
              errorMessage = serverError;
            }
          }
        } catch (_) {
          /*
           * Keep the default HTTP error message
           * if the response is not valid JSON.
           */
        }

        throw Exception(errorMessage);
      }

      /* -------------------------------------------------------------------- */
      /* DECODE RESPONSE                                                      */
      /* -------------------------------------------------------------------- */

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Donation service returned an invalid response.',
        );
      }

      /* -------------------------------------------------------------------- */
      /* CHECK SUCCESS                                                        */
      /* -------------------------------------------------------------------- */

      if (decoded['success'] != true) {
        final String? serverMessage =
            decoded['error']
                ?.toString()
                .trim();

        throw Exception(
          serverMessage == null ||
                  serverMessage.isEmpty
              ? 'Donation search failed.'
              : serverMessage,
        );
      }

      /* -------------------------------------------------------------------- */
      /* READ DONATION RESULT                                                 */
      /* -------------------------------------------------------------------- */

      /*
       * New backend response:
       *
       * {
       *   "donation": {...},
       *   "places": [...]
       * }
       *
       * `result` is also supported for compatibility
       * with your existing checkDonationEligibility
       * Cloud Function.
       */

      final dynamic rawDonation =
          decoded['donation'] ??
          decoded['result'];

      if (rawDonation
          is! Map<String, dynamic>) {
        throw Exception(
          'Donation analysis returned no result.',
        );
      }

      final GeminiDonationResult donation =
          _parseDonationResult(
        rawDonation,
        decoded,
      );

      /* -------------------------------------------------------------------- */
      /* READ DONATION CENTERS                                                */
      /* -------------------------------------------------------------------- */

      final List<DonationCenter> centers =
          _parseDonationCenters(
        decoded['places'] ??
            decoded['centers'],
      );

      return DonationAssessmentResult(
        donation: donation,
        centers: centers,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Donation service error: $error',
        );

        debugPrint(
          'Donation service stack trace:\n'
          '$stackTrace',
        );
      }

      /*
       * Do not manufacture a successful donation
       * recommendation if the backend fails.
       *
       * Throw the error so DonateDialog can show
       * its error state.
       */

      throw Exception(
        error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  /* ======================================================================== */
  /* PARSE GEMINI DONATION RESULT                                            */
  /* ======================================================================== */

  static GeminiDonationResult
      _parseDonationResult(
    Map<String, dynamic> rawResult,
    Map<String, dynamic> response,
  ) {
    /* ---------------------------------------------------------------------- */
    /* SUITABILITY                                                             */
    /* ---------------------------------------------------------------------- */

    final bool isSuitable =
        rawResult['isSuitable'] == true ||
        rawResult['consumable'] == true;

    /* ---------------------------------------------------------------------- */
    /* DONATION CATEGORY                                                       */
    /* ---------------------------------------------------------------------- */

    String donationCategory =
        _normalizeDonationCategory(
      rawResult['donationCategory'],
    );

    /*
     * Compatibility with older backend responses
     * that might return `decision` instead.
     */
    if (donationCategory == 'unknown') {
      donationCategory =
          _categoryFromDecision(
        decision: rawResult['decision'],
        consumable: isSuitable,
      );
    }

    /* ---------------------------------------------------------------------- */
    /* REASON                                                                  */
    /* ---------------------------------------------------------------------- */

    final String reason =
        rawResult['reason']
                ?.toString()
                .trim() ??
            'Donation suitability could not be determined.';

    /* ---------------------------------------------------------------------- */
    /* SUGGESTED ANIMALS                                                       */
    /* ---------------------------------------------------------------------- */

    final List<String> suggestedAnimals =
        _readStringList(
      rawResult['suggestedAnimals'],
    );

    /* ---------------------------------------------------------------------- */
    /* SUGGESTED ORGANIZATION TYPES                                            */
    /* ---------------------------------------------------------------------- */

    final List<String> suggestedOrgTypes =
        _readStringList(
      rawResult['suggestedOrgTypes'],
    );

    /* ---------------------------------------------------------------------- */
    /* AI FLAG                                                                 */
    /* ---------------------------------------------------------------------- */

    final bool usedAi =
        response['usedAi'] == true ||
        rawResult['usedAi'] == true;

    return GeminiDonationResult(
      isSuitable: isSuitable,
      donationCategory: donationCategory,
      reason: reason.isEmpty
          ? 'Donation suitability could not be determined.'
          : reason,
      suggestedAnimals: suggestedAnimals,
      suggestedOrgTypes: suggestedOrgTypes,
      usedAi: usedAi,
    );
  }

  /* ======================================================================== */
  /* PARSE DONATION CENTERS                                                   */
  /* ======================================================================== */

  static List<DonationCenter>
      _parseDonationCenters(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    final List<DonationCenter> centers =
        [];

    for (final dynamic item in value) {
      if (item is! Map) {
        continue;
      }

      final Map<String, dynamic> map =
          Map<String, dynamic>.from(item);

      /* -------------------------------------------------------------------- */
      /* NAME                                                                  */
      /* -------------------------------------------------------------------- */

      final String name =
          map['name']
                  ?.toString()
                  .trim() ??
              '';

      if (name.isEmpty) {
        continue;
      }

      /* -------------------------------------------------------------------- */
      /* TYPE                                                                  */
      /* -------------------------------------------------------------------- */

      final String rawType =
          map['type']
                  ?.toString()
                  .trim() ??
              '';

      final String type =
          rawType.isEmpty
              ? 'Donation Organization'
              : rawType;

      /* -------------------------------------------------------------------- */
      /* ADDRESS                                                               */
      /* -------------------------------------------------------------------- */

      final String address =
          map['address']
                  ?.toString()
                  .trim() ??
              '';

      /* -------------------------------------------------------------------- */
      /* PHONE                                                                 */
      /* -------------------------------------------------------------------- */

      final String? phone =
          _nullableString(
        map['phone'],
      );

      /* -------------------------------------------------------------------- */
      /* RATING                                                                */
      /* -------------------------------------------------------------------- */

      final double? rating =
          _toDouble(
        map['rating'],
      );

      /* -------------------------------------------------------------------- */
      /* REVIEW COUNT                                                          */
      /* -------------------------------------------------------------------- */

      final int? reviewCount =
          _toInt(
        map['reviewCount'] ??
            map['reviews'],
      );

      /* -------------------------------------------------------------------- */
      /* LATITUDE                                                              */
      /* -------------------------------------------------------------------- */

      final double? latitude =
          _toDouble(
        map['latitude'] ??
            map['lat'],
      );

      /* -------------------------------------------------------------------- */
      /* LONGITUDE                                                             */
      /* -------------------------------------------------------------------- */

      final double? longitude =
          _toDouble(
        map['longitude'] ??
            map['lng'] ??
            map['lon'],
      );

      /* -------------------------------------------------------------------- */
      /* DISTANCE                                                              */
      /* -------------------------------------------------------------------- */

      /*
       * Usually this will be null because the new
       * architecture searches by city instead of
       * device GPS.
       */
      final double? distanceKm =
          _toDouble(
        map['distanceKm'],
      );

      /* -------------------------------------------------------------------- */
      /* PLACE ID                                                              */
      /* -------------------------------------------------------------------- */

      final String? placeId =
          _nullableString(
        map['placeId'] ??
            map['dataId'] ??
            map['data_id'] ??
            map['dataCid'] ??
            map['data_cid'],
      );

      /* -------------------------------------------------------------------- */
      /* GOOGLE MAPS URL                                                       */
      /* -------------------------------------------------------------------- */

      final String? mapsUrl =
          _nullableString(
        map['googleMapsUrl'] ??
            map['mapsUrl'] ??
            map['link'],
      );

      /* -------------------------------------------------------------------- */
      /* ADD CENTER                                                            */
      /* -------------------------------------------------------------------- */

      centers.add(
        DonationCenter(
          name: name,
          type: type,
          address: address,
          phone: phone,
          rating: rating,
          reviewCount: reviewCount,
          latitude: latitude,
          longitude: longitude,
          distanceKm: distanceKm,
          placeId: placeId,
          mapsUrl: mapsUrl,
        ),
      );
    }

    return centers;
  }

  /* ======================================================================== */
  /* CATEGORY NORMALIZATION                                                   */
  /* ======================================================================== */

  static String _normalizeDonationCategory(
    dynamic value,
  ) {
    if (value == null) {
      return 'unknown';
    }

    final String category =
        value.toString().trim().toLowerCase();

    switch (category) {
      case 'animal_feed':
      case 'animal feed':
      case 'animal-feed':
        return 'animal_feed';

      case 'human_consumption':
      case 'human consumption':
      case 'human-consumption':
      case 'community donation':
        return 'human_consumption';

      case 'non_food_use':
      case 'non food use':
      case 'non-food-use':
      case 'non-food':
        return 'non_food_use';

      case 'unsafe':
      case 'not suitable':
      case 'not_suitable':
        return 'unsafe';

      default:
        return 'unknown';
    }
  }

  /* ======================================================================== */
  /* CATEGORY FROM DECISION                                                   */
  /* ======================================================================== */

  static String _categoryFromDecision({
    dynamic decision,
    required bool consumable,
  }) {
    final String value =
        decision
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (value.contains('animal') ||
        value.contains('feed') ||
        value.contains('cattle') ||
        value.contains('poultry') ||
        value.contains('livestock')) {
      return 'animal_feed';
    }

    if (value.contains('human') ||
        value.contains('community') ||
        value.contains('food bank')) {
      return 'human_consumption';
    }

    if (value.contains('non-food') ||
        value.contains('non food') ||
        value.contains('recycling')) {
      return 'non_food_use';
    }

    if (value.contains('unsafe') ||
        value.contains('not suitable') ||
        value.contains('reject')) {
      return 'unsafe';
    }

    /*
     * Never automatically classify a consumable
     * product as human_consumption.
     */
    if (!consumable) {
      return 'unsafe';
    }

    return 'unknown';
  }

  /* ======================================================================== */
  /* STRING LIST PARSER                                                       */
  /* ======================================================================== */

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .map(
          (dynamic item) =>
              item.toString().trim(),
        )
        .where(
          (String item) =>
              item.isNotEmpty,
        )
        .toList();
  }

  /* ======================================================================== */
  /* NULLABLE STRING                                                          */
  /* ======================================================================== */

  static String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  /* ======================================================================== */
  /* DOUBLE PARSER                                                            */
  /* ======================================================================== */

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  /* ======================================================================== */
  /* INTEGER PARSER                                                           */
  /* ======================================================================== */

  static int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final String text =
        value
            .toString()
            .replaceAll(',', '')
            .trim();

    if (text.isEmpty) {
      return null;
    }

    /*
     * SerpAPI may sometimes return review counts
     * as strings such as "1,234".
     */
    final int? integer =
        int.tryParse(text);

    if (integer != null) {
      return integer;
    }

    final double? decimal =
        double.tryParse(text);

    return decimal?.toInt();
  }

  /* ======================================================================== */
  /* LEGACY GEMINI METHOD                                                     */
  /* ======================================================================== */

  /*
   * Kept for compatibility with any other code that
   * still calls:
   *
   * DonationService.assessDonationSuitability(product)
   *
   * It now uses the combined backend.
   */

  static Future<GeminiDonationResult>
      assessDonationSuitability(
    ProductModel product,
  ) async {
    final DonationAssessmentResult result =
        await assessAndFindDonationOptions(
      product: product,
    );

    return result.donation;
  }

  /* ======================================================================== */
  /* LEGACY PLACE SEARCH METHOD                                               */
  /* ======================================================================== */

  /*
   * This method intentionally remains empty.
   *
   * SerpAPI must NOT be called directly from Flutter,
   * because your SERP_API_KEY must remain inside
   * Cloud Functions Secret Manager.
   *
   * The new flow is:
   *
   * Flutter
   *    ↓
   * findDonationPlaces
   *    ↓
   * Cloud Function
   *    ↓
   * SerpAPI
   */

  static Future<List<DonationCenter>>
      findNearbyDonationCenters({
    required String location,
    String? donationCategory,
    int maxResults = 10,
  }) async {
    return const [];
  }
}

/* ========================================================================== */
/* DONATION ASSESSMENT RESULT                                                 */
/* ========================================================================== */

class DonationAssessmentResult {
  final GeminiDonationResult donation;

  final List<DonationCenter> centers;

  const DonationAssessmentResult({
    required this.donation,
    required this.centers,
  });
}

/* ========================================================================== */
/* GEMINI DONATION RESULT                                                     */
/* ========================================================================== */

class GeminiDonationResult {
  final bool isSuitable;

  final String donationCategory;

  final String reason;

  final List<String> suggestedAnimals;

  final List<String> suggestedOrgTypes;

  final bool usedAi;

  const GeminiDonationResult({
    required this.isSuitable,
    required this.donationCategory,
    required this.reason,
    required this.suggestedAnimals,
    required this.suggestedOrgTypes,
    required this.usedAi,
  });
}

/* ========================================================================== */
/* DONATION CENTER                                                            */
/* ========================================================================== */

class DonationCenter {
  final String name;

  final String type;

  final String address;

  final String? phone;

  final double? rating;

  final int? reviewCount;

  final double? latitude;

  final double? longitude;

  final double? distanceKm;

  final String? placeId;

  final String? mapsUrl;

  const DonationCenter({
    required this.name,
    required this.type,
    required this.address,
    this.phone,
    this.rating,
    this.reviewCount,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.placeId,
    this.mapsUrl,
  });

  /* ======================================================================== */
  /* GOOGLE MAPS URL                                                           */
  /* ======================================================================== */

  String get googleMapsUrl {
    /*
     * Prefer URL supplied by Cloud Function / SerpAPI.
     */
    if (mapsUrl != null &&
        mapsUrl!.trim().isNotEmpty) {
      return mapsUrl!.trim();
    }

    /*
     * If coordinates are available, use them.
     */
    if (latitude != null &&
        longitude != null) {
      return 'https://www.google.com/maps/search/?api=1'
          '&query=$latitude,$longitude';
    }

    /*
     * Current architecture does not require
     * device GPS.
     *
     * Therefore name + address is used as a
     * Google Maps search query.
     */
    final String query =
        Uri.encodeComponent(
      '$name, $address',
    );

    return 'https://www.google.com/maps/search/?api=1'
        '&query=$query';
  }
}