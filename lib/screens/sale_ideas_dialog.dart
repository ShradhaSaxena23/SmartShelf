
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../services/sale_ideas_service.dart';
import '../theme/app_theme.dart';

void showSaleIdeasDialog(
  BuildContext context,
  ProductModel product,
) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: SaleIdeasDialog(
        product: product,
      ),
    ),
  );
}

class SaleIdeasDialog extends StatefulWidget {
  final ProductModel product;

  const SaleIdeasDialog({
    super.key,
    required this.product,
  });

  @override
  State<SaleIdeasDialog> createState() =>
      _SaleIdeasDialogState();
}

class _SaleIdeasDialogState
    extends State<SaleIdeasDialog> {
  bool _isLoading = true;
  bool _isLoadingMore = false;

  String? _errorMessage;

  String _location = 'Current Location';

  String _selectedOrgFilter = 'NGOs';

  List<SaleEvent> _events = [];
  List<FoodBankOrg> _foodBanks = [];

  // ==========================================================================
  // FIXED PRICE
  // ==========================================================================
  //
  // Sale Ideas must NEVER change the product price.
  //
  // The product entered price is stored in originalPrice.
  //
  // If product.price is valid, use it.
  // If product.price is 0 but originalPrice exists, calculate the correct
  // current selling price from expiry.
  //
  // ==========================================================================

  double get _displayPrice {
    final originalPrice = widget.product.originalPrice;

    // No valid original price.
    if (originalPrice <= 0) {
      return 0.0;
    }

    final daysRemaining = widget.product.daysRemaining;

    // Expired.
    if (daysRemaining < 0) {
      return 0.0;
    }

    // If the ProductModel already contains a valid current price,
    // preserve it.
    if (widget.product.price > 0) {
      return widget.product.price;
    }

    // ------------------------------------------------------------------------
    // Fallback calculation.
    //
    // This is reached for your current problem:
    //
    // originalPrice = ₹49
    // price = ₹0
    // daysRemaining = 71
    //
    // Result = ₹49
    // ------------------------------------------------------------------------

    if (daysRemaining <= 3) {
      return originalPrice * 0.75;
    }

    if (daysRemaining <= 5) {
      return originalPrice * 0.90;
    }

    if (daysRemaining <= 7) {
      return originalPrice * 0.95;
    }

    // Fresh product.
    return originalPrice;
  }

  // ==========================================================================
  // ORIGINAL PRICE
  // ==========================================================================

  double get _displayOriginalPrice {
    return widget.product.originalPrice;
  }

  // ==========================================================================
  // SHOULD SHOW ORIGINAL PRICE
  // ==========================================================================

  bool get _showOriginalPrice {
    return _displayOriginalPrice > _displayPrice &&
        _displayPrice > 0;
  }

  @override
  void initState() {
    super.initState();

    _fetchData();
  }

  // ==========================================================================
  // FETCH
  // ==========================================================================

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await SaleIdeasService.fetchSaleIdeas(
        product: widget.product,
      );

      if (!mounted) return;

      setState(() {
        _location = result.location;

        _events = result.events
            .where(
              (event) => event.isRelevantForProduct(
                widget.product,
              ),
            )
            .toList();

        _foodBanks = _filterOrganizations(
          result.organizations,
          _selectedOrgFilter,
        );

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ==========================================================================
  // ORGANIZATION FILTER
  // ==========================================================================

  List<FoodBankOrg> _filterOrganizations(
    List<FoodBankOrg> organizations,
    String filter,
  ) {
    if (filter == 'All') {
      return organizations;
    }

    final normalized =
        filter.toLowerCase();

    return organizations.where((org) {
      final text =
          '${org.name} ${org.category}'
              .toLowerCase();

      switch (normalized) {
        case 'ngos':
          return text.contains('ngo') ||
              text.contains('foundation') ||
              text.contains('trust') ||
              text.contains('charity');

        case 'midday meal':
          return text.contains('midday') ||
              text.contains('meal') ||
              text.contains('kitchen');

        case 'animal shelters':
          return text.contains('animal') ||
              text.contains('livestock') ||
              text.contains('shelter');

        case 'food banks':
          return text.contains('food bank') ||
              text.contains('foodbank') ||
              text.contains('food donation') ||
              text.contains('community kitchen');

        default:
          return true;
      }
    }).toList();
  }

  // ==========================================================================
  // URL
  // ==========================================================================

  Future<void> _launchUrl(
    String url,
  ) async {
    if (url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri == null) return;

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  String _formatExpiryDate(
    DateTime date,
  ) {
    return DateFormat(
      'dd MMM yyyy',
    ).format(date);
  }

  Color _daysRemainingColor() {
    final days =
        widget.product.daysRemaining;

    if (days <= 0) {
      return Colors.red;
    }

    if (days <= 3) {
      return Colors.orange;
    }

    if (days <= 7) {
      return Colors.amber.shade800;
    }

    return Colors.green;
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final dialogWidth =
        width > 900 ? 680.0 : width * 0.94;

    return Container(
      width: dialogWidth,
      constraints: const BoxConstraints(
        maxHeight: 850,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _buildBody(),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        16,
        20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.16),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Sale Ideas & Opportunities ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Find nearby opportunities for your inventory',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () =>
                Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child:
                    CircularProgressIndicator(),
              ),
              SizedBox(height: 20),
              Text(
                'Finding local sale opportunities...',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Searching events and organizations near your saved location.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20,
        ),
        children: [
          _buildProductSummary(),

          const SizedBox(height: 14),

          _buildTipBanner(),

          const SizedBox(height: 22),

          _buildEventsSection(),

          const SizedBox(height: 28),

          _buildOrganizationsSection(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color:
                    Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color: Colors.red,
                size: 30,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to find local opportunities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PRODUCT SUMMARY
  // ==========================================================================

  Widget _buildProductSummary() {
    final days =
        widget.product.daysRemaining;

    final daysColor =
        _daysRemainingColor();

    final currentPrice = _displayPrice;
    final originalPrice =
        _displayOriginalPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen
                  .withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color:
                  AppTheme.primaryGreen,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.product.category,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: [
                    Text(
                      'Expiry: ${_formatExpiryDate(widget.product.expiryDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    Text(
                      '$days ${days == 1 ? 'day' : 'days'} left',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
                        color: daysColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              // ================================================================
              // FIX:
              // Use calculated display price instead of widget.product.price.
              // ================================================================
              Text(
                '₹${currentPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              // Show original price only when there is actually a discount.
              if (originalPrice > currentPrice &&
                  currentPrice > 0)
                Text(
                  '₹${originalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade500,
                    decoration:
                        TextDecoration
                            .lineThrough,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TIP
  // ==========================================================================

  Widget _buildTipBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            Colors.amber.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.amber.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Colors.amber.shade800,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Tip: Nearby fairs, community events and food organizations can help you move products before they expire.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color:
                    Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EVENTS SECTION
  // ==========================================================================

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Local Events & Conferences Near You',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Perfect places to promote your discounted items.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            _buildPoweredBadge(
              'Google Events',
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildLocationCard(),

        const SizedBox(height: 14),

        if (_events.isEmpty)
          _buildEmptyEvents()
        else
          ..._events.map(
            _buildEventCard,
          ),
      ],
    );
  }

  // ==========================================================================
  // LOCATION CARD
  // ==========================================================================

  Widget _buildLocationCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen
            .withOpacity(0.06),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20,
            color:
                AppTheme.primaryGreen,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Searching near',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _location,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoadingMore
                    ? null
                    : _fetchData,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EMPTY EVENTS
  // ==========================================================================

  Widget _buildEmptyEvents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 35,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 9),

          Text(
            'No upcoming local events found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Try again later as event listings are updated regularly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color:
                  Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              final url =
                  'https://www.google.com/search?q='
                  '${Uri.encodeComponent('events near $_location')}';

              _launchUrl(url);
            },
            icon: const Icon(
              Icons.search_rounded,
              size: 17,
            ),
            label:
                const Text('Search Events'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // EVENT CARD
  // ==========================================================================

  Widget _buildEventCard(
    SaleEvent event,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildEventImage(event),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  _buildSmallTag(
                    event.category,
                    Icons.category_outlined,
                  ),

                  const SizedBox(height: 7),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 14,
                        color:
                            Colors.grey.shade600,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          event.dateRangeFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .location_on_outlined,
                        size: 14,
                        color:
                            Colors.grey.shade600,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          event.venue.isNotEmpty
                              ? event.venue
                              : event.address,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (event.description
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 7),

                    Text(
                      event.description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              event.link
                                      .isNotEmpty
                                  ? () =>
                                      _launchUrl(
                                        event.link,
                                      )
                                  : () =>
                                      _launchUrl(
                                        event
                                            .googleMapsUrl,
                                      ),
                          icon: const Icon(
                            Icons
                                .open_in_new_rounded,
                            size: 15,
                          ),
                          label:
                              const Text(
                            'View Event',
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 9,
                            ),
                            textStyle:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        tooltip:
                            'Open location',
                        onPressed: () =>
                            _launchUrl(
                          event.googleMapsUrl,
                        ),
                        icon: const Icon(
                          Icons
                              .directions_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // EVENT IMAGE
  // ==========================================================================

  Widget _buildEventImage(
    SaleEvent event,
  ) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: SizedBox(
        width: 82,
        height: 82,
        child: event.imageUrl != null
            ? Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        _eventPlaceholder(),
              )
            : _eventPlaceholder(),
      ),
    );
  }

  Widget _eventPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.event_outlined,
        size: 30,
        color: Colors.grey.shade400,
      ),
    );
  }

  // ==========================================================================
  // ORGANIZATIONS
  // ==========================================================================

  Widget _buildOrganizationsSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Food Banks and Shelter Homes Nearby',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Useful organizations for donation or responsible distribution.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            _buildPoweredBadge(
              'Local Search',
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildOrganizationFilters(),

        const SizedBox(height: 13),

        if (_foodBanks.isEmpty)
          _buildEmptyOrganizations()
        else
          ..._foodBanks.map(
            _buildOrganizationCard,
          ),
      ],
    );
  }

  // ==========================================================================
  // FILTERS
  // ==========================================================================

  Widget _buildOrganizationFilters() {
    const filters = [
      'NGOs',
      'Midday Meal',
      'Animal Shelters',
      'Food Banks',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected =
              _selectedOrgFilter == filter;

          return Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedOrgFilter =
                      filter;
                });

                _reloadOrganizationFilter();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void>
      _reloadOrganizationFilter() async {
    try {
      final result =
          await SaleIdeasService.fetchSaleIdeas(
        product: widget.product,
      );

      if (!mounted) return;

      setState(() {
        _foodBanks =
            _filterOrganizations(
          result.organizations,
          _selectedOrgFilter,
        );
      });
    } catch (_) {
      // Keep currently displayed data.
    }
  }

  // ==========================================================================
  // EMPTY ORGANIZATIONS
  // ==========================================================================

  Widget _buildEmptyOrganizations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .volunteer_activism_outlined,
            size: 35,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 9),

          Text(
            'No organizations found for this category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
              color:
                  Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              _launchUrl(
                'https://www.google.com/maps/search/'
                '?api=1&query='
                '${Uri.encodeComponent('food banks near $_location')}',
              );
            },
            icon: const Icon(
              Icons.map_outlined,
              size: 17,
            ),
            label:
                const Text('Search on Maps'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ORGANIZATION CARD
  // ==========================================================================

  Widget _buildOrganizationCard(
    FoodBankOrg org,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons
                      .volunteer_activism_outlined,
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      org.category,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color:
                    Colors.grey.shade600,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  org.address,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          if (org.operatingHours != null) ...[
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color:
                      Colors.grey.shade600,
                ),

                const SizedBox(width: 6),

                Text(
                  org.operatingHours!,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],

          if (org.rating != null) ...[
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber,
                ),

                const SizedBox(width: 4),

                Text(
                  org.rating!
                      .toStringAsFixed(1),
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                if (org.reviews != null)
                  Text(
                    ' (${org.reviews} reviews)',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () =>
                      _launchUrl(
                    org.googleMapsUrl,
                  ),
                  icon: const Icon(
                    Icons
                        .directions_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Get Directions',
                  ),
                  style:
                      OutlinedButton
                          .styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 9,
                    ),
                    textStyle:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (org.phone != null) ...[
                const SizedBox(width: 8),

                IconButton(
                  tooltip: 'Call',
                  onPressed: () =>
                      _launchUrl(
                    'tel:${org.phone}',
                  ),
                  icon: const Icon(
                    Icons.phone_outlined,
                  ),
                ),
              ],

              if (org.website != null)
                IconButton(
                  tooltip: 'Website',
                  onPressed: () =>
                      _launchUrl(
                    org.website!,
                  ),
                  icon: const Icon(
                    Icons
                        .language_outlined,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // POWERED BADGE
  // ==========================================================================

  Widget _buildPoweredBadge(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen
            .withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
          color:
              AppTheme.primaryGreen,
        ),
      ),
    );
  }

  // ==========================================================================
  // SMALL TAG
  // ==========================================================================

  Widget _buildSmallTag(
    String text,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
                Colors.grey.shade600,
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FOOTER
  // ==========================================================================

  Widget _buildFooter() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 17,
            color:
                AppTheme.primaryGreen,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              'Suggestions are based on your saved location and current inventory.',
              style: TextStyle(
                fontSize: 10,
                color:
                    Colors.grey.shade600,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(width: 10),

          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(),
            child:
                const Text('Close'),
          ),
        ],
      ),
    );
  }
}