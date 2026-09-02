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
