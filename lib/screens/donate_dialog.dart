
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../services/donation_service.dart';

class DonateDialog extends StatefulWidget {
  final ProductModel product;

  const DonateDialog({
    super.key,
    required this.product,
  });

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog>
    with SingleTickerProviderStateMixin {
  /* ======================================================================== */
  /* STATE                                                                    */
  /* ======================================================================== */

  _Phase _phase = _Phase.initial;

  GeminiDonationResult? _aiResult;

  List<DonationCenter> _centers = [];

  String? _errorMessage;

  late AnimationController _pulseController;

  late Animation<double> _pulseAnim;

  /* ======================================================================== */
  /* LIFECYCLE                                                                */
  /* ======================================================================== */

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    );

    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /* ======================================================================== */
  /* FIND DONATION OPTIONS                                                    */
  /* ======================================================================== */

  Future<void> _onFindShelters() async {
    setState(() {
      _phase = _Phase.locating;
      _errorMessage = null;
      _centers = [];
      _aiResult = null;
    });

    _pulseController.repeat(
      reverse: true,
    );

    try {
      /*
       * IMPORTANT:
       *
       * We do NOT request device/browser location.
       *
       * The backend gets:
       *
       * Firebase Auth UID
       *       ↓
       * Firestore users/{uid}
       *       ↓
       * location: "Lucknow"
       */

      await Future<void>.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phase = _Phase.analyzing;
      });

      final result =
          await DonationService.assessAndFindDonationOptions(
        product: widget.product,
      );

      if (!mounted) {
        return;
      }

      _pulseController.stop();

      setState(() {
        _aiResult = result.donation;
        _centers = result.centers;
        _phase = _Phase.results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _pulseController.stop();

      setState(() {
        _phase = _Phase.error;

        _errorMessage = error
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /* ======================================================================== */
  /* OPEN GOOGLE MAPS                                                         */
  /* ======================================================================== */

  Future<void> _openMaps(
    DonationCenter center,
  ) async {
    final url = center.googleMapsUrl;

    if (url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open Google Maps.',
          ),
        ),
      );
    }
  }

  /* ======================================================================== */
  /* CALL PHONE                                                               */
  /* ======================================================================== */

  Future<void> _callPhone(
    String phone,
  ) async {
    final cleaned = phone.trim();

    if (cleaned.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: cleaned,
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not make the call.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not make the call.',
          ),
        ),
      );
    }
  }

  /* ======================================================================== */
  /* DATE FORMATTING                                                          */
  /* ======================================================================== */

  String _formattedExpiryDate() {
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(
        widget.product.expiryDate,
      );
    } catch (_) {
      return widget.product.expiryDate.toString();
    }
  }

  /* ======================================================================== */
  /* DONATION CATEGORY TITLE                                                  */
  /* ======================================================================== */

  String _categoryTitle(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return 'Potentially suitable as animal feed';

      case 'human_consumption':
        return 'Potentially suitable for community donation';

      case 'non_food_use':
        return 'Potential non-food donation use';

      case 'unsafe':
        return 'Unsafe for donation';

      case 'unknown':
      default:
        return 'Caution — Verify before donating';
    }
  }

  /* ======================================================================== */
  /* DONATION CATEGORY ICON                                                   */
  /* ======================================================================== */

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return Icons.pets_outlined;

      case 'human_consumption':
        return Icons.volunteer_activism_outlined;

      case 'non_food_use':
        return Icons.recycling_outlined;

      case 'unsafe':
        return Icons.warning_amber_rounded;

      case 'unknown':
      default:
        return Icons.help_outline_rounded;
    }
  }

  /* ======================================================================== */
  /* CATEGORY COLOR                                                           */
  /* ======================================================================== */

  Color _categoryColor(
    String category,
  ) {
    switch (category) {
      case 'animal_feed':
        return Colors.green;

      case 'human_consumption':
        return Colors.teal;

      case 'non_food_use':
        return Colors.blue;

      case 'unsafe':
        return Colors.red;

      case 'unknown':
      default:
        return Colors.orange;
    }
  }

  /* ======================================================================== */
  /* TYPE ICON                                                                */
  /* ======================================================================== */

  IconData _typeIcon(
    String type,
  ) {
    final value = type.toLowerCase();

    if (value.contains('gaushala')) {
      return Icons.agriculture_outlined;
    }

    if (value.contains('cattle')) {
      return Icons.agriculture_outlined;
    }

    if (value.contains('animal')) {
      return Icons.pets_outlined;
    }

    if (value.contains('dairy')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('poultry')) {
      return Icons.egg_alt_outlined;
    }

    if (value.contains('food bank')) {
      return Icons.inventory_2_outlined;
    }

    if (value.contains('community kitchen')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('ngo')) {
      return Icons.volunteer_activism_outlined;
    }

    return Icons.location_on_outlined;
  }

  /* ======================================================================== */
  /* BUILD                                                                    */
  /* ======================================================================== */

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 760,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ),
              blurRadius: 30,
              offset: const Offset(
                0,
                12,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    16,
                  ),
                  child: _buildContent(),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /* ======================================================================== */
  /* HEADER                                                                   */
  /* ======================================================================== */

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        18,
        22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16A34A),
            Color(0xFF15803D),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donate Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Find suitable donation options with AI',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.88,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* CONTENT                                                                  */
  /* ======================================================================== */

  Widget _buildContent() {
    switch (_phase) {
      case _Phase.initial:
        return _buildInitial();

      case _Phase.locating:
        return _buildLoading(
          title: 'Getting your saved location...',
          subtitle:
              'Checking your saved city to find nearby donation options.',
        );

      case _Phase.analyzing:
        return _buildLoading(
          title: 'Gemini is analyzing donation suitability...',
          subtitle:
              'We are checking whether this item can be safely donated and finding relevant organizations.',
        );

      case _Phase.results:
        return _buildResults();

      case _Phase.error:
        return _buildError();
    }
  }

  /* ======================================================================== */
  /* PRODUCT CARD                                                             */
  /* ======================================================================== */

  Widget _buildProductCard() {
    final product = widget.product;

    final isExpired = product.isExpired;

    final isExpiringSoon = product.isExpiringSoon;

    /*
     * ProductModel.brand is String?, so always safely convert
     * null into an empty string before using trim().
     */
    final brand = (product.brand ?? '').trim();

    Color statusColor;

    String statusText;

    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.error_outline;
    } else if (isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expiring Soon';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.green;
      statusText = 'Fresh';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),

                /*
                 * FIX:
                 *
                 * product.brand is nullable.
                 * We use the safe local `brand` variable.
                 */
                if (brand.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    brand,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 15,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Expiry: ${_formattedExpiryDate()}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* INITIAL                                                                  */
  /* ======================================================================== */

  Widget _buildInitial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF16A34A),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI-powered donation check',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gemini will analyze this product for donation suitability. We will then use your saved city to find relevant nearby donation organizations.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: const Color(0xFF166534).withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onFindShelters,
            icon: const Icon(
              Icons.search_rounded,
            ),
            label: const Text(
              'Find Donation Options',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* LOADING                                                                  */
  /* ======================================================================== */

  Widget _buildLoading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),
        const SizedBox(height: 26),
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (
              context,
              child,
            ) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF16A34A),
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF16A34A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* RESULTS                                                                  */
  /* ======================================================================== */

  Widget _buildResults() {
    final result = _aiResult;

    if (result == null) {
      return _buildError(
        customMessage:
            'Donation analysis could not be loaded.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductCard(),

        const SizedBox(height: 18),

        _buildAiResultCard(result),

        if (result.suggestedAnimals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAnimalsSection(result),
        ],

        if (result.suggestedOrgTypes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildOrganizationTypesSection(result),
        ],

        const SizedBox(height: 22),

        _buildNearbyCentersHeader(),

        const SizedBox(height: 10),

        if (_centers.isEmpty)
          _buildNoCenters()
        else
          ..._centers.map(
            (center) => Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: _DonationCenterTile(
                center: center,
                typeIcon: _typeIcon(center.type),
                onDirections: () => _openMaps(center),
                onCall: center.phone != null &&
                        center.phone!.trim().isNotEmpty
                    ? () => _callPhone(
                          center.phone!,
                        )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /* ======================================================================== */
  /* AI RESULT CARD                                                           */
  /* ======================================================================== */

  Widget _buildAiResultCard(
    GeminiDonationResult result,
  ) {
    final category = result.donationCategory;

    final color = _categoryColor(category);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryTitle(category),
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.usedAi
                            ? 'AI Analysis'
                            : 'Analysis Unavailable',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Recommendation',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            result.reason,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* ANIMALS                                                                  */
  /* ======================================================================== */

  Widget _buildAnimalsSection(
    GeminiDonationResult result,
  ) {
    return _sectionCard(
      title: 'Potentially suitable for',
      icon: Icons.pets_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.suggestedAnimals
            .map(
              (animal) => _chip(
                animal,
                Icons.pets_outlined,
              ),
            )
            .toList(),
      ),
    );
  }

  /* ======================================================================== */
  /* ORGANIZATION TYPES                                                       */
  /* ======================================================================== */

  Widget _buildOrganizationTypesSection(
    GeminiDonationResult result,
  ) {
    return _sectionCard(
      title: 'Recommended organization types',
      icon: Icons.business_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: result.suggestedOrgTypes
            .map(
              (type) => _chip(
                type,
                _typeIcon(type),
              ),
            )
            .toList(),
      ),
    );
  }

  /* ======================================================================== */
  /* NEARBY CENTERS HEADER                                                    */
  /* ======================================================================== */

  Widget _buildNearbyCentersHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Nearby Donation Centers',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_done_outlined,
                size: 13,
                color: Color(0xFF15803D),
              ),
              SizedBox(width: 4),
              Text(
                'Live',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* NO CENTERS                                                               */
  /* ======================================================================== */

  Widget _buildNoCenters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No nearby donation centers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'The item may still be suitable for donation. Try again later or check local organizations manually.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* ERROR                                                                    */
  /* ======================================================================== */

  Widget _buildError({
    String? customMessage,
  }) {
    final message = customMessage ??
        _errorMessage ??
        'Something went wrong while analyzing the product.';

    return Column(
      children: [
        _buildProductCard(),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to find donation options',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFF7F1D1D),
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onFindShelters,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(
                      color: Color(0xFFFCA5A5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* ======================================================================== */
  /* SECTION CARD                                                             */
  /* ======================================================================== */

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* CHIP                                                                     */
  /* ======================================================================== */

  Widget _chip(
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF16A34A),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* FOOTER                                                                   */
  /* ======================================================================== */

  Widget _buildFooter() {
    final canProceed = _phase == _Phase.results &&
        _aiResult != null &&
        _aiResult!.isSuitable &&
        _centers.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(
                  color: Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Close',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed
                  ? _proceedToDonate
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFE2E8F0),
                disabledForegroundColor:
                    const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Proceed to Donate',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ======================================================================== */
  /* PROCEED                                                                  */
  /* ======================================================================== */

  void _proceedToDonate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Donation option selected. Please contact the organization before donating.',
        ),
      ),
    );
  }
}

/* ========================================================================== */
/* DONATION CENTER TILE                                                       */
/* ========================================================================== */

class _DonationCenterTile extends StatelessWidget {
  final DonationCenter center;

  final IconData typeIcon;

  final VoidCallback onDirections;

  final VoidCallback? onCall;

  const _DonationCenterTile({
    required this.center,
    required this.typeIcon,
    required this.onDirections,
    required this.onCall,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  typeIcon,
                  color: const Color(0xFF16A34A),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        center.type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (center.address.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    center.address,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 11),

          Row(
            children: [
              if (center.rating != null) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 3),
                Text(
                  center.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                if (center.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${center.reviewCount})',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],

              /*
               * Distance is intentionally optional because your
               * backend currently searches using the saved CITY,
               * not the user's GPS coordinates.
               */
              if (center.distanceKm != null &&
                  center.distanceKm! > 0) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.near_me_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 3),
                Text(
                  '${center.distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(
                    Icons.directions_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Directions',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF15803D),
                    side: const BorderSide(
                      color: Color(0xFFBBF7D0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),

              if (onCall != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(
                      Icons.phone_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Call',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF15803D),
                      side: const BorderSide(
                        color: Color(0xFFBBF7D0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/* HELPER TYPES                                                               */
/* ========================================================================== */

enum _Phase {
  initial,
  locating,
  analyzing,
  results,
  error,
}