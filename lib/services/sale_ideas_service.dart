// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/product_model.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // API Key Placeholders — replace with actual keys if available
// // ─────────────────────────────────────────────────────────────────────────────
// const String _kGeminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
// const String _kGooglePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY_HERE';

// // ─────────────────────────────────────────────────────────────────────────────
// // Models
// // ─────────────────────────────────────────────────────────────────────────────

// class SaleEvent {
//   final String id;
//   final String name;
//   final String category; // e.g. "Expo • Food & Beverage", "Festival • Community"
//   final DateTime startDate;
//   final DateTime endDate;
//   final String venue;
//   final String city;
//   final double distanceKm;
//   final String? phone;
//   final String description;
//   final double lat;
//   final double lng;
//   final String? imageUrl;

//   const SaleEvent({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.startDate,
//     required this.endDate,
//     required this.venue,
//     required this.city,
//     required this.distanceKm,
//     this.phone,
//     required this.description,
//     required this.lat,
//     required this.lng,
//     this.imageUrl,
//   });

//   /// Duration of event in days
//   int get durationInDays => endDate.difference(startDate).inDays + 1;

//   /// Check if event matches selection criteria:
//   /// - Lasting 7 days or less
//   /// - Ends before product expiry date
//   bool isValidForProduct(DateTime productExpiry) {
//     if (durationInDays > 7) return false;
//     // Ends before product expiry
//     if (endDate.isAfter(productExpiry)) return false;
//     return true;
//   }

//   String get dateRangeFormatted {
//     final startStr = _formatShortDate(startDate);
//     final endStr = _formatShortDate(endDate);
//     if (startDate.month == endDate.month) {
//       return '${startDate.day} – ${endDate.day}, ${endDate.year}';
//     }
//     return '$startStr – $endStr, ${endDate.year}';
//   }

//   static String _formatShortDate(DateTime d) {
//     final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return '${months[d.month - 1]} ${d.day}';
//   }

//   String get googleMapsUrl =>
//       'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name $venue $city')}&center=$lat,$lng';
// }

// class FoodBankOrg {
//   final String id;
//   final String name;
//   final String category; // "NGO", "Midday Meal Program", "Food Bank", "Shelter Home", "Animal Shelter"
//   final String address;
//   final double distanceKm;
//   final String? phone;
//   final String? operatingHours;
//   final double lat;
//   final double lng;
//   final String? placeId;

//   const FoodBankOrg({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.address,
//     required this.distanceKm,
//     this.phone,
//     this.operatingHours,
//     required this.lat,
//     required this.lng,
//     this.placeId,
//   });

//   String get googleMapsUrl =>
//       'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&query_place_id=${placeId ?? ''}&center=$lat,$lng';
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Service
// // ─────────────────────────────────────────────────────────────────────────────

// class SaleIdeasService {
//   static const Duration _timeout = Duration(seconds: 10);

//   // ── 1. Fetch Nearby Events (Gemini API with Fallback) ──────────────────────

//   static Future<List<SaleEvent>> fetchNearbyEvents({
//     required ProductModel product,
//     required double latitude,
//     required double longitude,
//     String cityName = 'Bengaluru',
//   }) async {
//     if (_kGeminiApiKey != 'YOUR_GEMINI_API_KEY_HERE') {
//       try {
//         final prompt = '''
// You are an event discovery engine for local vendors.
// Find short-term local events, fairs, community markets, food festivals, or exhibitions in or near $cityName, $latitude, $longitude.

// Product to sell: ${product.name} (Category: ${product.category})
// Product Expiry Date: ${product.expiryDate.toIso8601String().substring(0, 10)}

// Rules for events:
// 1. Event duration must be 7 days or less.
// 2. Event must be currently ongoing or starting within the next few days.
// 3. Event MUST END before ${product.expiryDate.toIso8601String().substring(0, 10)}.
// 4. Exclude events longer than 7 days or already ended.

// Return ONLY a JSON list of up to 4 events matching this exact format:
// [
//   {
//     "id": "event_1",
//     "name": "Event Name",
//     "category": "Expo • Food & Beverage",
//     "startDate": "YYYY-MM-DD",
//     "endDate": "YYYY-MM-DD",
//     "venue": "Venue Name",
//     "city": "$cityName",
//     "distanceKm": 2.3,
//     "phone": "+91 9876543210",
//     "description": "Brief 1-line description",
//     "lat": $latitude,
//     "lng": $longitude
//   }
// ]
// ''';

//         final url = Uri.parse(
//           'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_kGeminiApiKey',
//         );

//         final response = await http
//             .post(
//               url,
//               headers: {'Content-Type': 'application/json'},
//               body: jsonEncode({
//                 'contents': [
//                   {
//                     'parts': [
//                       {'text': prompt}
//                     ]
//                   }
//                 ],
//                 'generationConfig': {
//                   'temperature': 0.3,
//                   'maxOutputTokens': 1024,
//                 },
//               }),
//             )
//             .timeout(_timeout);

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body) as Map<String, dynamic>;
//           final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
//           final cleaned = text.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();
//           final List<dynamic> jsonList = jsonDecode(cleaned);

//           final events = jsonList.map((item) {
//             final m = item as Map<String, dynamic>;
//             return SaleEvent(
//               id: m['id'] ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
//               name: m['name'] as String,
//               category: m['category'] as String? ?? 'Fair & Market',
//               startDate: DateTime.parse(m['startDate'] as String),
//               endDate: DateTime.parse(m['endDate'] as String),
//               venue: m['venue'] as String,
//               city: m['city'] as String? ?? cityName,
//               distanceKm: (m['distanceKm'] as num).toDouble(),
//               phone: m['phone'] as String?,
//               description: m['description'] as String? ?? 'Ideal event for selling quick stock.',
//               lat: (m['lat'] as num).toDouble(),
//               lng: (m['lng'] as num).toDouble(),
//             );
//           }).where((e) => e.isValidForProduct(product.expiryDate)).toList();

//           if (events.isNotEmpty) return events;
//         }
//       } catch (_) {
//         // Fall through to fallback engine
//       }
//     }

//     // Fallback Events Engine (Mocked realistic events meeting business rules)
//     return _getFallbackEvents(product, latitude, longitude, cityName);
//   }

//   static List<SaleEvent> _getFallbackEvents(
//     ProductModel product,
//     double lat,
//     double lng,
//     String city,
//   ) {
//     final now = DateTime.now();
//     // Ensure event ends BEFORE product expiry date and duration <= 7 days
//     final daysToExpiry = product.daysRemaining > 0 ? product.daysRemaining : 3;

//     final event1Start = now.add(const Duration(days: 1));
//     final event1End = event1Start.add(Duration(days: (daysToExpiry > 3 ? 2 : 1)));

//     final event2Start = now.add(const Duration(days: 2));
//     final event2End = event2Start.add(Duration(days: (daysToExpiry > 4 ? 2 : 1)));

//     final event3Start = now.add(const Duration(days: 1));
//     final event3End = event3Start.add(Duration(days: (daysToExpiry > 5 ? 3 : 1)));

//     return [
//       SaleEvent(
//         id: 'evt_1',
//         name: 'Healthy Food Expo 2025',
//         category: 'Expo • Food & Beverage',
//         startDate: event1Start,
//         endDate: event1End.isBefore(product.expiryDate) ? event1End : product.expiryDate.subtract(const Duration(days: 1)),
//         venue: 'International Exhibition Centre',
//         city: city,
//         distanceKm: 2.3,
//         phone: '+91 98765 12345',
//         description: 'Perfect place to promote discounted food & grocery items to health-conscious crowds.',
//         lat: lat + 0.015,
//         lng: lng + 0.012,
//         imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=150',
//       ),
//       SaleEvent(
//         id: 'evt_2',
//         name: 'Green Living & Organic Conference',
//         category: 'Conference • Sustainability',
//         startDate: event2Start,
//         endDate: event2End.isBefore(product.expiryDate) ? event2End : product.expiryDate.subtract(const Duration(days: 1)),
//         venue: 'The Lalit Ashok',
//         city: city,
//         distanceKm: 3.7,
//         phone: '+91 91234 88990',
//         description: '3-day eco-friendly market featuring sustainable products and zero-waste vendors.',
//         lat: lat - 0.020,
//         lng: lng + 0.018,
//         imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=150',
//       ),
//       SaleEvent(
//         id: 'evt_3',
//         name: 'Community Weekend Food Festival',
//         category: 'Festival • Community',
//         startDate: event3Start,
//         endDate: event3End.isBefore(product.expiryDate) ? event3End : product.expiryDate.subtract(const Duration(days: 1)),
//         venue: 'Freedom Park',
//         city: city,
//         distanceKm: 4.1,
//         phone: '+91 80000 33445',
//         description: 'High footfall weekend fair connecting local sellers directly with neighborhood buyers.',
//         lat: lat + 0.025,
//         lng: lng - 0.022,
//         imageUrl: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=150',
//       ),
//     ].where((e) => e.durationInDays <= 7 && e.endDate.isBefore(product.expiryDate)).toList();
//   }

//   // ── 2. Fetch Food Banks & Shelter Homes (Gemini / Google Places API) ────────

//   static Future<List<FoodBankOrg>> fetchFoodBanksOrgs({
//     required ProductModel product,
//     required double latitude,
//     required double longitude,
//     String selectedFilter = 'All',
//   }) async {
//     if (_kGeminiApiKey != 'YOUR_GEMINI_API_KEY_HERE' || _kGooglePlacesApiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
//       try {
//         final prompt = '''
// Find nearby Food Banks, NGOs, Shelter Homes, Midday Meal Programs, Community Kitchens, and Orphanages near lat: $latitude, lng: $longitude.
// Product to donate/distribute: ${product.name} (${product.category}).

// Filter category requested: $selectedFilter

// Return ONLY a JSON list of up to 5 organizations:
// [
//   {
//     "id": "org_1",
//     "name": "Akshaya Patra Foundation",
//     "category": "NGO • Fights hunger & provides meals",
//     "address": "12 Sector Rd, City",
//     "distanceKm": 1.8,
//     "phone": "+91 9876543210",
//     "operatingHours": "8:00 AM - 7:00 PM",
//     "lat": $latitude,
//     "lng": $longitude
//   }
// ]
// ''';

//         final url = Uri.parse(
//           'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_kGeminiApiKey',
//         );

//         final response = await http
//             .post(
//               url,
//               headers: {'Content-Type': 'application/json'},
//               body: jsonEncode({
//                 'contents': [
//                   {
//                     'parts': [
//                       {'text': prompt}
//                     ]
//                   }
//                 ],
//                 'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 1024},
//               }),
//             )
//             .timeout(_timeout);

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body) as Map<String, dynamic>;
//           final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
//           final cleaned = text.replaceAll(RegExp(r'```json\s*|```\s*'), '').trim();
//           final List<dynamic> jsonList = jsonDecode(cleaned);

//           return jsonList.map((item) {
//             final m = item as Map<String, dynamic>;
//             return FoodBankOrg(
//               id: m['id'] ?? 'org_${DateTime.now().millisecondsSinceEpoch}',
//               name: m['name'] as String,
//               category: m['category'] as String? ?? 'NGO',
//               address: m['address'] as String,
//               distanceKm: (m['distanceKm'] as num).toDouble(),
//               phone: m['phone'] as String?,
//               operatingHours: m['operatingHours'] as String? ?? '9:00 AM - 6:00 PM',
//               lat: (m['lat'] as num).toDouble(),
//               lng: (m['lng'] as num).toDouble(),
//             );
//           }).toList();
//         }
//       } catch (_) {
//         // Fallback
//       }
//     }

//     return _getFallbackOrgs(latitude, longitude, selectedFilter);
//   }

//   static List<FoodBankOrg> _getFallbackOrgs(double lat, double lng, String filter) {
//     final allOrgs = [
//       FoodBankOrg(
//         id: 'org_1',
//         name: 'Akshaya Patra Foundation',
//         category: 'NGO • Fights hunger & provides meals',
//         address: '8th Block, Rajajinagar Industrial Area',
//         distanceKm: 1.8,
//         phone: '+91 80 2337 1945',
//         operatingHours: '7:00 AM - 6:00 PM',
//         lat: lat + 0.008,
//         lng: lng + 0.006,
//         placeId: 'mock_akshaya',
//       ),
//       FoodBankOrg(
//         id: 'org_2',
//         name: 'Robin Hood Army',
//         category: 'NGO • Food distribution to the needy',
//         address: 'Indiranagar 100ft Road, Sector 3',
//         distanceKm: 2.6,
//         phone: '+91 99000 11223',
//         operatingHours: '9:00 AM - 8:00 PM',
//         lat: lat - 0.012,
//         lng: lng + 0.014,
//         placeId: 'mock_robinhood',
//       ),
//       FoodBankOrg(
//         id: 'org_3',
//         name: 'Food For Life Initiative',
//         category: 'Midday Meal • Reducing hunger & waste',
//         address: '4th Main Road, Malleshwaram',
//         distanceKm: 3.2,
//         phone: '+91 80 4123 5678',
//         operatingHours: '8:30 AM - 5:30 PM',
//         lat: lat + 0.019,
//         lng: lng - 0.010,
//         placeId: 'mock_foodforlife',
//       ),
//       FoodBankOrg(
//         id: 'org_4',
//         name: 'City Hope Shelter & Food Bank',
//         category: 'Food Bank • Community Kitchen',
//         address: 'Plot 88, Civil Station Colony',
//         distanceKm: 4.5,
//         phone: '+91 98450 67890',
//         operatingHours: '24/7 Service',
//         lat: lat - 0.024,
//         lng: lng - 0.018,
//         placeId: 'mock_cityhope',
//       ),
//       FoodBankOrg(
//         id: 'org_5',
//         name: 'Karuna Animal & Livestock Shelter',
//         category: 'Animal Shelter • Organic surplus feed',
//         address: 'Veterinary College Campus, Hebbal',
//         distanceKm: 5.1,
//         phone: '+91 80 2341 2233',
//         operatingHours: '8:00 AM - 5:00 PM',
//         lat: lat + 0.030,
//         lng: lng + 0.025,
//         placeId: 'mock_karuna',
//       ),
//     ];

//     if (filter == 'NGOs') {
//       return allOrgs.where((o) => o.category.contains('NGO')).toList();
//     } else if (filter == 'Midday Meal') {
//       return allOrgs.where((o) => o.category.contains('Midday Meal') || o.name.contains('Akshaya')).toList();
//     } else if (filter == 'Animal Shelters') {
//       return allOrgs.where((o) => o.category.contains('Animal Shelter')).toList();
//     } else if (filter == 'Food Banks') {
//       return allOrgs.where((o) => o.category.contains('Food Bank')).toList();
//     }

//     return allOrgs;
//   }
// }

// version 2 

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

// ============================================================================
// Firebase Cloud Function
// ============================================================================

class SaleIdeasService {
  SaleIdeasService._();

  static const String _functionUrl =
      'https://asia-south2-smartshelf-4b145.cloudfunctions.net/searchSerp';

  static const Duration _timeout = Duration(seconds: 55);

  // ==========================================================================
  // Get Firebase ID Token
  // ==========================================================================

  static Future<String> _getAuthToken() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Please log in to view local sale opportunities.',
      );
    }

    final String? token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw Exception(
        'Unable to authenticate with Firebase.',
      );
    }

    return token;
  }

  // ==========================================================================
  // Fetch all Sale Ideas in ONE request
  //
  // Cloud Function returns:
  //
  // {
  //   success: true,
  //   location: "...",
  //   events: [...],
  //   organizations: [...]
  // }
  // ==========================================================================

  static Future<SaleIdeasResult> fetchSaleIdeas({
    required ProductModel product,
  }) async {
    final token = await _getAuthToken();

    try {
      final response = await http
          .get(
            Uri.parse(_functionUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        throw Exception(
          'Invalid response received from the server.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          data['error'] ??
              'Your session has expired. Please log in again.',
        );
      }

      if (response.statusCode == 404) {
        throw Exception(
          data['error'] ??
              'User profile was not found.',
        );
      }

      if (response.statusCode == 400) {
        throw Exception(
          data['error'] ??
              'Please add your location first.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          data['error'] ??
              'Unable to find local opportunities.',
        );
      }

      if (data['success'] != true) {
        throw Exception(
          data['error'] ??
              'Unable to find local opportunities.',
        );
      }

      final List<dynamic> eventData =
          data['events'] is List
              ? data['events'] as List<dynamic>
              : <dynamic>[];

      final List<dynamic> organizationData =
          data['organizations'] is List
              ? data['organizations'] as List<dynamic>
              : <dynamic>[];

      final events = eventData
          .whereType<Map<String, dynamic>>()
          .map(SaleEvent.fromJson)
          .toList();

      final organizations = organizationData
          .whereType<Map<String, dynamic>>()
          .map(FoodBankOrg.fromJson)
          .toList();

      return SaleIdeasResult(
        location:
            data['location']?.toString() ??
            'Current Location',
        events: events,
        organizations: organizations,
      );
    } on http.ClientException {
      throw Exception(
        'Unable to connect to the Sale Ideas service.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Something went wrong while loading Sale Ideas.',
      );
    }
  }

  // ==========================================================================
  // Compatibility method for existing UI
  //
  // This means your dialog can continue using:
  //
  // SaleIdeasService.fetchNearbyEvents(...)
  //
  // without changing the UI architecture.
  // ==========================================================================

  static Future<List<SaleEvent>> fetchNearbyEvents({
    required ProductModel product,
  }) async {
    final result = await fetchSaleIdeas(
      product: product,
    );

    return result.events
        .where(
          (event) => event.isRelevantForProduct(
            product,
          ),
        )
        .toList();
  }

  // ==========================================================================
  // Compatibility method for existing UI
  // ==========================================================================

  static Future<List<FoodBankOrg>> fetchFoodBanksOrgs({
    required ProductModel product,
    String selectedFilter = 'NGOs',
  }) async {
    final result = await fetchSaleIdeas(
      product: product,
    );

    return _filterOrganizations(
      result.organizations,
      selectedFilter,
    );
  }

  // ==========================================================================
  // Filter organizations locally
  // ==========================================================================

  static List<FoodBankOrg> _filterOrganizations(
    List<FoodBankOrg> organizations,
    String filter,
  ) {
    if (filter == 'All') {
      return organizations;
    }

    final normalizedFilter = filter.toLowerCase();

    return organizations.where((org) {
      final value =
          '${org.name} ${org.category}'.toLowerCase();

      switch (normalizedFilter) {
        case 'ngos':
          return value.contains('ngo') ||
              value.contains('foundation') ||
              value.contains('trust') ||
              value.contains('charity');

        case 'midday meal':
          return value.contains('midday') ||
              value.contains('meal') ||
              value.contains('community kitchen');

        case 'animal shelters':
          return value.contains('animal') ||
              value.contains('shelter') ||
              value.contains('livestock');

        case 'food banks':
          return value.contains('food bank') ||
              value.contains('foodbank') ||
              value.contains('food donation') ||
              value.contains('community kitchen');

        default:
          return true;
      }
    }).toList();
  }
}

// ============================================================================
// Combined API Result
// ============================================================================

class SaleIdeasResult {
  final String location;
  final List<SaleEvent> events;
  final List<FoodBankOrg> organizations;

  const SaleIdeasResult({
    required this.location,
    required this.events,
    required this.organizations,
  });
}

// ============================================================================
// Sale Event
// ============================================================================

class SaleEvent {
  final String id;
  final String name;
  final String category;
  final String dateText;
  final String venue;
  final String address;
  final String description;
  final String link;
  final String? imageUrl;

  const SaleEvent({
    required this.id,
    required this.name,
    required this.category,
    required this.dateText,
    required this.venue,
    required this.address,
    required this.description,
    required this.link,
    this.imageUrl,
  });

  factory SaleEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    return SaleEvent(
      id: _stringValue(
        json['id'],
        fallback: 'event',
      ),
      name: _stringValue(
        json['name'],
        fallback: 'Local Event',
      ),
      category: _stringValue(
        json['category'],
        fallback: 'Event',
      ),
      dateText: _stringValue(
        json['dateText'],
        fallback: 'Date not available',
      ),
      venue: _stringValue(
        json['venue'],
        fallback: 'Venue not available',
      ),
      address: _stringValue(
        json['address'],
        fallback: '',
      ),
      description: _stringValue(
        json['description'],
        fallback:
            'Local event that may provide a sales opportunity.',
      ),
      link: _stringValue(
        json['link'],
        fallback: '',
      ),
      imageUrl: _nullableString(
        json['imageUrl'],
      ),
    );
  }

  // ==========================================================================
  // Event validity
  //
  // We intentionally do NOT attempt to parse SerpAPI's natural-language
  // event dates into DateTime because formats such as:
  //
  // "Aug 20"
  // "Aug 20 – Aug 22"
  // "Tomorrow"
  //
  // are not reliable enough to convert blindly.
  //
  // The Cloud Function searches upcoming events, and this method removes
  // obviously empty/invalid results.
  // ==========================================================================

  bool isRelevantForProduct(
    ProductModel product,
  ) {
    if (name.trim().isEmpty) {
      return false;
    }

    if (dateText.trim().isEmpty) {
      return false;
    }

    return true;
  }

  String get dateRangeFormatted => dateText;

  String get googleMapsUrl {
    final query = [
      name,
      venue,
      address,
    ]
        .where(
          (value) => value.trim().isNotEmpty,
        )
        .join(' ');

    return 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent(query)}';
  }

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}

// ============================================================================
// Food Bank / Organization
// ============================================================================

class FoodBankOrg {
  final String id;
  final String name;
  final String category;
  final String address;
  final String? phone;
  final String? operatingHours;
  final double? rating;
  final int? reviews;
  final String description;
  final String mapsUrl;
  final String? website;
  final String? thumbnail;

  const FoodBankOrg({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.phone,
    this.operatingHours,
    this.rating,
    this.reviews,
    required this.description,
    required this.mapsUrl,
    this.website,
    this.thumbnail,
  });

  factory FoodBankOrg.fromJson(
    Map<String, dynamic> json,
  ) {
    return FoodBankOrg(
      id: _stringValue(
        json['id'],
        fallback: 'organization',
      ),
      name: _stringValue(
        json['name'],
        fallback: 'Local Organization',
      ),
      category: _stringValue(
        json['category'],
        fallback: 'NGO / Food Support',
      ),
      address: _stringValue(
        json['address'],
        fallback: 'Address not available',
      ),
      phone: _nullableString(
        json['phone'],
      ),
      operatingHours: _nullableString(
        json['operatingHours'],
      ),
      rating: _doubleValue(
        json['rating'],
      ),
      reviews: _intValue(
        json['reviews'],
      ),
      description: _stringValue(
        json['description'],
        fallback: '',
      ),
      mapsUrl: _stringValue(
        json['mapsUrl'],
        fallback: '',
      ),
      website: _nullableString(
        json['website'],
      ),
      thumbnail: _nullableString(
        json['thumbnail'],
      ),
    );
  }

  String get googleMapsUrl {
    if (mapsUrl.trim().isNotEmpty) {
      return mapsUrl;
    }

    return 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent(name)}';
  }

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static double? _doubleValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int? _intValue(
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

    return int.tryParse(
      value.toString(),
    );
  }
}
