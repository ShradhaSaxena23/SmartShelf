
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../services/donation_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API: call this to show the dialog
// ─────────────────────────────────────────────────────────────────────────────

void showDonateDialog(BuildContext context, ProductModel product) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DonateDialog(product: product),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog phases
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { initial, locating, analyzing, results, error }

// ─────────────────────────────────────────────────────────────────────────────
// Main Dialog Widget
// ─────────────────────────────────────────────────────────────────────────────

class _DonateDialog extends StatefulWidget {
  final ProductModel product;
  const _DonateDialog({required this.product});

  @override
  State<_DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<_DonateDialog>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.initial;
  Position? _position;
  GeminiDonationResult? _aiResult;
  List<DonationCenter> _centers = [];
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Location logic ──────────────────────────────────────────────────────────

  Future<void> _onFindShelters() async {
    setState(() => _phase = _Phase.locating);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _phase = _Phase.error;
          _errorMessage =
              'Location permission denied. Please enable it in device settings to find nearby donation centers.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _position = pos;
    } catch (_) {
      // Use fallback coordinates if location unavailable
      _position = Position(
        latitude: 28.6139,
        longitude: 77.2090,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // ── AI Analysis ───────────────────────────────────────────────────────────
    setState(() => _phase = _Phase.analyzing);

    final aiResult = await DonationService.assessDonationSuitability(widget.product);
    _aiResult = aiResult;

    // ── Fetch nearby centers ──────────────────────────────────────────────────
    final orgTypes = aiResult.isSuitable
        ? aiResult.suggestedOrgTypes
        : ['Animal Shelter', 'Food Bank'];

    final centers = await DonationService.findNearbyDonationCenters(
      latitude: _position!.latitude,
      longitude: _position!.longitude,
      orgTypes: orgTypes,
    );

    setState(() {
      _centers = centers;
      _phase = _Phase.results;
    });
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _openMaps(DonationCenter center) async {
    final uri = Uri.parse(center.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openAllOnMap() async {
    if (_position == null) return;
    final query = Uri.encodeComponent(
        _aiResult?.suggestedOrgTypes.isNotEmpty == true
            ? _aiResult!.suggestedOrgTypes.first
            : 'animal shelter');
    final url =
        'https://www.google.com/maps/search/$query/@${_position!.latitude},${_position!.longitude},13z';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F5A36), Color(0xFF1A7A4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donate Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Find nearby donation centers with AI',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // ── Body dispatcher ─────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductCard(),
          const SizedBox(height: 16),
          if (_phase == _Phase.initial) _buildInitialPhase(),
          if (_phase == _Phase.locating) _buildLoadingPhase('Getting your location...', Icons.my_location),
          if (_phase == _Phase.analyzing) _buildLoadingPhase('AI is analyzing donation suitability...', Icons.psychology),
          if (_phase == _Phase.results) ...[
            _buildAiResultCard(),
            const SizedBox(height: 16),
            _buildNearbySection(),
          ],
          if (_phase == _Phase.error) _buildErrorCard(),
        ],
      ),
    );
  }

  // ── Product Card ─────────────────────────────────────────────────────────────

  Widget _buildProductCard() {
    final daysAgo = widget.product.daysRemaining.abs();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _categoryColor(widget.product.category).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(widget.product.category),
              color: _categoryColor(widget.product.category),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.product.category}  •  ${widget.product.quantity} units',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: AppTheme.expiredRed),
                    const SizedBox(width: 3),
                    Text(
                      'Expired $daysAgo ${daysAgo == 1 ? 'day' : 'days'} ago  •  ${DateFormat('MMM d, yyyy').format(widget.product.expiryDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.expiredRed,
                        fontWeight: FontWeight.w500,
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

  // ── Phase 1 — Initial ─────────────────────────────────────────────────────────

  Widget _buildInitialPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTheme.donateBlue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Our AI will analyze the product and find nearby donation centers like Gaushalas, animal shelters, and dairy farms that can accept this item.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF0369A1),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundMint,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap below to share your location and find nearby centers.',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onFindShelters,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Find Donation Centers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading Phase ─────────────────────────────────────────────────────────────

  Widget _buildLoadingPhase(String label, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This may take a few seconds...',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppTheme.cardBorder,
                color: AppTheme.primaryGreen,
                minHeight: 3,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Result Card ────────────────────────────────────────────────────────────

  Widget _buildAiResultCard() {
    final result = _aiResult!;
    final isSuitable = result.isSuitable;
    final bgColor = isSuitable ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final borderColor = isSuitable ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final iconColor = isSuitable ? AppTheme.freshGreen : AppTheme.expiringSoonYellow;
    final icon = isSuitable ? Icons.check_circle : Icons.warning_amber_rounded;
    final title = isSuitable ? 'Good news! This item is safe to donate.' : 'Caution — Verify before donating.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.reason,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: result.usedAi
                      ? AppTheme.donateBlue.withValues(alpha: 0.12)
                      : AppTheme.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      result.usedAi ? Icons.auto_awesome : Icons.data_object,
                      size: 11,
                      color: result.usedAi ? AppTheme.donateBlue : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      result.usedAi ? 'Verified by AI (Gemini)' : 'Smart Rule-Based Analysis',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: result.usedAi ? AppTheme.donateBlue : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Nearby Centers Section ────────────────────────────────────────────────────

  Widget _buildNearbySection() {
    final usedPlaces = _kGooglePlacesApiKeyIsSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Find Donation Centers Near You',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (!usedPlaces)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin_drop_outlined, size: 11, color: AppTheme.textMuted),
                    SizedBox(width: 3),
                    Text(
                      'Demo Data',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          usedPlaces
              ? 'We found donation centers near your location.'
              : 'Showing sample centers. Add Google Places API key for live results.',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ..._centers.map((c) => _DonationCenterTile(
              center: c,
              onNavigate: () => _openMaps(c),
              onCall: c.phone != null ? () => _callPhone(c.phone!) : null,
            )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openAllOnMap,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new, size: 14, color: AppTheme.donateBlue),
              SizedBox(width: 5),
              Text(
                'View more centers on map',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.donateBlue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error Card ────────────────────────────────────────────────────────────────

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off, color: AppTheme.expiredRed, size: 36),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => setState(() => _phase = _Phase.initial),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen),
              minimumSize: const Size(120, 38),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _phase == _Phase.results
                  ? () {
                      // Select first center if available
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.volunteer_activism, size: 17),
              label: const Text('Proceed to Donate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.cardBorder,
                disabledForegroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 44),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  // Returns true once a real Google Places API key is set in donation_service.dart
  bool _kGooglePlacesApiKeyIsSet() => false;

  Color _categoryColor(String category) {
    switch (category) {
      case 'Dairy':
        return AppTheme.donateBlue;
      case 'Bakery':
        return AppTheme.warningOrange;
      case 'Produce':
        return AppTheme.freshGreen;
      case 'Meat':
        return AppTheme.expiredRed;
      case 'Beverages':
        return AppTheme.accentGreen;
      case 'Snacks':
        return AppTheme.discountPurple;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Dairy':
        return Icons.water_drop_outlined;
      case 'Bakery':
        return Icons.bakery_dining_outlined;
      case 'Produce':
        return Icons.eco_outlined;
      case 'Meat':
        return Icons.kebab_dining_outlined;
      case 'Beverages':
        return Icons.local_cafe_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donation Center Tile
// ─────────────────────────────────────────────────────────────────────────────

class _DonationCenterTile extends StatelessWidget {
  final DonationCenter center;
  final VoidCallback onNavigate;
  final VoidCallback? onCall;

  const _DonationCenterTile({
    required this.center,
    required this.onNavigate,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _typeColor(center.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(center.type), color: _typeColor(center.type), size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        center.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _DistanceBadge(km: center.distanceKm),
                  ],
                ),
                const SizedBox(height: 3),
                // Type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeColor(center.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    center.type,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: _typeColor(center.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Rating
                if (center.rating != null)
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final filled = i < center.rating!.floor();
                        final half = !filled && i < center.rating!;
                        return Icon(
                          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
                          size: 13,
                          color: const Color(0xFFF59E0B),
                        );
                      }),
                      const SizedBox(width: 5),
                      Text(
                        '${center.rating!.toStringAsFixed(1)} (${center.reviewCount ?? 0})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        center.address,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          Column(
            children: [
              _ActionBtn(
                icon: Icons.directions,
                color: AppTheme.primaryGreen,
                tooltip: 'Get Directions',
                onTap: onNavigate,
              ),
              if (onCall != null) ...[
                const SizedBox(height: 6),
                _ActionBtn(
                  icon: Icons.phone_outlined,
                  color: AppTheme.donateBlue,
                  tooltip: 'Call',
                  onTap: onCall!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'gaushala':
      case 'cattle shelter':
        return const Color(0xFF8B5CF6);
      case 'dairy farm':
        return AppTheme.donateBlue;
      case 'animal shelter':
        return AppTheme.warningOrange;
      case 'food bank':
      case 'community kitchen':
        return AppTheme.freshGreen;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'gaushala':
      case 'cattle shelter':
        return Icons.pets;
      case 'dairy farm':
        return Icons.water_drop_outlined;
      case 'animal shelter':
        return Icons.cruelty_free;
      case 'food bank':
      case 'community kitchen':
        return Icons.restaurant_outlined;
      default:
        return Icons.volunteer_activism;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DistanceBadge extends StatelessWidget {
  final double km;
  const _DistanceBadge({required this.km});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        '${km.toStringAsFixed(1)} km',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
