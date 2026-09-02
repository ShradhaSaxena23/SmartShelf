import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../services/sale_ideas_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Public helper function to launch Sale Ideas Modal Dialog
void showSaleIdeasDialog(BuildContext context, ProductModel product) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SaleIdeasDialog(product: product),
    ),
  );
}

class SaleIdeasDialog extends StatefulWidget {
  final ProductModel product;

  const SaleIdeasDialog({super.key, required this.product});

  @override
  State<SaleIdeasDialog> createState() => _SaleIdeasDialogState();
}

class _SaleIdeasDialogState extends State<SaleIdeasDialog> {
  bool _isLoading = true;
  String _selectedCity = 'Current Location';
  String _selectedOrgFilter = 'NGOs'; // Filter chips: NGOs, Midday Meal Programs, Animal Shelters, Food Banks

  List<SaleEvent> _events = [];
  List<FoodBankOrg> _foodBanks = [];
  double _userLat = 12.9716; // Bengaluru default
  double _userLng = 77.5946;

  @override
  void initState() {
    super.initState();
    _loadLocationAndData();
  }

  Future<void> _loadLocationAndData() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 5)),
        );
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      }
    } catch (_) {}

    await _fetchData();
  }

  Future<void> _fetchData() async {
    final events = await SaleIdeasService.fetchNearbyEvents(
      product: widget.product,
      latitude: _userLat,
      longitude: _userLng,
      cityName: _selectedCity == 'Current Location' ? 'Bengaluru' : _selectedCity,
    );

    final orgs = await SaleIdeasService.fetchFoodBanksOrgs(
      product: widget.product,
      latitude: _userLat,
      longitude: _userLng,
      selectedFilter: _selectedOrgFilter,
    );

    if (mounted) {
      setState(() {
        _events = events;
        _foodBanks = orgs;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Container(
      width: isDesktop ? 680 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Dialog Header ──
          _buildHeader(context),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product Summary Bar ──
                  _buildProductInfoBanner(),
                  const SizedBox(height: 16),

                  // ── Tip Highlight Banner ──
                  _buildTipBanner(),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppTheme.primaryGreen),
                            SizedBox(height: 16),
                            Text('Finding best sale opportunities with Gemini AI...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Section 1: Search Nearby Events ──
                    _buildEventsSection(),
                    const SizedBox(height: 28),

                    // ── Section 2: Food Banks & Shelter Homes ──
                    _buildFoodBanksSection(),
                    const SizedBox(height: 24),

                    // ── AI Disclaimer Footer ──
                    _buildAiBadgeFooter(),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom Action Row ──
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Sale Ideas & Opportunities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('✨', style: TextStyle(fontSize: 18)),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Smart suggestions to help you sell faster and reduce waste.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.product.category} • ${widget.product.daysRemaining} days left • Exp: ${DateFormat('MMM dd, yyyy').format(widget.product.expiryDate)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.product.discountPercentage > 0)
                Text(
                  '\$${widget.product.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, decoration: TextDecoration.lineThrough),
                ),
              Text(
                '\$${widget.product.discountedPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Soft orange container
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Color(0xFFF97316), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Combine discounts with local events or donate surplus to NGOs and midday meal programs.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFFC2410C),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Location Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '1. Local Events & Conferences Near You',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  DropdownButton<String>(
                    value: _selectedCity,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                    items: ['Current Location', 'Bengaluru', 'Delhi', 'Mumbai'].map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCity = val;
                          _fetchData();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 28),
          child: Text(
            'Perfect places to promote your discounted items.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentGreen),
            SizedBox(width: 4),
            Text(
              'Powered by Gemini Events API',
              style: TextStyle(fontSize: 11, color: AppTheme.accentGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Events List
        if (_events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Text(
              'No upcoming short-term events found ending before product expiry.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          )
        else
          Column(
            children: _events.map((event) => _buildEventCard(event)).toList(),
          ),

        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchUrl('https://www.google.com/search?q=events+in+${Uri.encodeComponent(_selectedCity)}'),
          child: const Row(
            children: [
              Text(
                'View more events on Google',
                style: TextStyle(fontSize: 12.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 13, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(SaleEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Thumbnail Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              event.imageUrl ?? 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=150',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppTheme.backgroundMint,
                child: const Icon(Icons.event, color: AppTheme.primaryGreen, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${event.distanceKm} km',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.category,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 13, color: AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      event.dateRangeFormatted,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildFoodBanksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.favorite_border, color: AppTheme.expiredRed, size: 20),
            SizedBox(width: 8),
            Text(
              '2. Food Banks and Shelter Homes Nearby',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 28),
          child: Text(
            'Donate surplus items and make a real impact.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            Icon(Icons.auto_awesome, size: 12, color: AppTheme.accentGreen),
            SizedBox(width: 4),
            Text(
              'Powered by Google Places API',
              style: TextStyle(fontSize: 11, color: AppTheme.accentGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['NGOs', 'Midday Meal Programs', 'Animal Shelters', 'Food Banks'].map((chip) {
              final isSelected = _selectedOrgFilter == chip;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(chip),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedOrgFilter = chip;
                        _fetchData();
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Food Banks / Org Cards
        if (_foodBanks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Text(
              'No nearby organization centers found for this filter.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          )
        else
          Column(
            children: _foodBanks.map((org) => _buildOrgCard(org)).toList(),
          ),

        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchUrl('https://www.google.com/maps/search/food+banks+near+me'),
          child: const Row(
            children: [
              Text(
                'View more places on Google Maps',
                style: TextStyle(fontSize: 12.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 13, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrgCard(FoodBankOrg org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Org Icon/Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volunteer_activism, color: AppTheme.accentGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  org.category,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
                if (org.operatingHours != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Hours: ${org.operatingHours}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '${org.distanceKm} km',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.location_on, size: 14, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _launchUrl(org.googleMapsUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundMint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.directions, size: 12, color: AppTheme.primaryGreen),
                      SizedBox(width: 4),
                      Text('Get Directions', style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiBadgeFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI suggestions are personalized based on your items, location & expiry. Verified by AI (Gemini).',
              style: TextStyle(fontSize: 11.5, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            child: const Text('Close', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
