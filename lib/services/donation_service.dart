
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