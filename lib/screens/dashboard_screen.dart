import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'donate_dialog.dart';
import 'sale_ideas_dialog.dart';

enum DashboardFilter {
  all,
  expiringSoon,
  expired,
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  DashboardFilter _selectedFilter = DashboardFilter.all;

  // Name shown in the dashboard header.
  // Loaded from Firestore and falls back to FirebaseAuth if needed.
  String _firestoreUserName = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(
        context,
        listen: false,
      );

      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      final userId = authProvider.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        _animController.forward();
        return;
      }

      _loadUserNameFromFirestore(userId);

      productProvider.loadProducts(userId).then((_) {
        if (mounted) {
          _animController.forward();
        }
      });
    });
  }

  // ===========================================================================
  // LOAD USER NAME FROM FIRESTORE
  // ===========================================================================

  Future<void> _loadUserNameFromFirestore(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      final data = snapshot.data();

      final firestoreName =
          data?['name']?.toString().trim().isNotEmpty == true
              ? data!['name'].toString().trim()
              : data?['displayName']?.toString().trim().isNotEmpty == true
                  ? data!['displayName'].toString().trim()
                  : data?['fullName']?.toString().trim().isNotEmpty == true
                      ? data!['fullName'].toString().trim()
                      : '';

      if (firestoreName.isNotEmpty) {
        setState(() {
          _firestoreUserName = firestoreName;
        });
      }
    } catch (e) {
      debugPrint(
        'Dashboard: failed to load user name: $e',
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FILTERING
  // ===========================================================================

  List<ProductModel> _getFilteredProducts(
    ProductProvider provider,
  ) {
    List<ProductModel> list;

    switch (_selectedFilter) {
      case DashboardFilter.expiringSoon:
        list = provider.expiringSoonProducts;
        break;

      case DashboardFilter.expired:
        list = provider.expiredProducts;
        break;

      case DashboardFilter.all:
        list = provider.allProducts;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();

      return list.where((product) {
        final nameMatch =
            product.name.toLowerCase().contains(q);

        final categoryMatch =
            product.category.toLowerCase().contains(q);

        final brandMatch =
            (product.brand ?? '').toLowerCase().contains(q);

        final batchMatch =
            (product.batchNumber ?? '').toLowerCase().contains(q);

        return nameMatch ||
            categoryMatch ||
            brandMatch ||
            batchMatch;
      }).toList();
    }

    return list;
  }

  String get _sectionTitle {
    switch (_selectedFilter) {
      case DashboardFilter.expiringSoon:
        return 'Expiring Soon';

      case DashboardFilter.expired:
        return 'Expired Items';

      case DashboardFilter.all:
        return 'All Items';
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final user = authProvider.currentUser;

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    if (productProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32.0 : 16.0,
          vertical: isDesktop ? 20.0 : 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(
              _firestoreUserName.isNotEmpty
                  ? _firestoreUserName
                  : (user?.displayName ?? 'User'),
              isDesktop,
            ),

            SizedBox(
              height: isDesktop ? 20 : 14,
            ),

            _buildSearchBar(),

            SizedBox(
              height: isDesktop ? 24 : 18,
            ),

            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 14),

            _buildOverviewCards(
              productProvider,
              isDesktop,
            ),

            SizedBox(
              height: isDesktop ? 28 : 22,
            ),

            _buildProductsSection(
              productProvider,
              isDesktop,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO BANNER
  // ===========================================================================

  Widget _buildHeroBanner(
    String name,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,

      // IMPORTANT:
      // Desktop stays large.
      // Mobile is now compact.
      constraints: BoxConstraints(
        minHeight: isDesktop ? 300 : 150,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          isDesktop ? 26 : 20,
        ),
        border: Border.all(
          color: const Color(0xFFE5E9E6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isDesktop ? 24 : 14,
            offset: Offset(
              0,
              isDesktop ? 10 : 5,
            ),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Stack(
        children: [
          // -------------------------------------------------------------------
          // BACKGROUND GREEN SHAPE
          // -------------------------------------------------------------------

          Positioned(
            right: isDesktop ? -70 : -90,
            bottom: isDesktop ? -115 : -85,
            child: Container(
              width: isDesktop ? 430 : 230,
              height: isDesktop ? 280 : 170,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4E7),
                borderRadius: BorderRadius.circular(180),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // DECORATIVE DOTS
          // -------------------------------------------------------------------

          Positioned(
            right: isDesktop ? 34 : 14,
            top: isDesktop ? 28 : 18,
            child: Wrap(
              spacing: isDesktop ? 13 : 10,
              runSpacing: isDesktop ? 12 : 10,
              children: List.generate(
                isDesktop ? 12 : 8,
                (_) => Container(
                  width: isDesktop ? 5 : 4,
                  height: isDesktop ? 5 : 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB9D9A9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // CONTENT
          // -------------------------------------------------------------------

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 44 : 18,
              vertical: isDesktop ? 34 : 17,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildHeroContent(
                          name,
                          isDesktop: true,
                        ),
                      ),

                      const SizedBox(width: 24),

                      Expanded(
                        flex: 4,
                        child: _buildHeroLogo(
                          isDesktop: true,
                        ),
                      ),
                    ],
                  )

                // ----------------------------------------------------------------
                // MOBILE / SMALL SCREEN
                // ----------------------------------------------------------------
                : Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildHeroContent(
                          name,
                          isDesktop: false,
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        width: 78,
                        height: 78,
                        child: _buildHeroLogo(
                          isDesktop: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HERO CONTENT
  // ===========================================================================

  Widget _buildHeroContent(
    String name, {
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Greeting
        Text(
          'Good to see you, $name! 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17633B),
          ),
        ),

        SizedBox(
          height: isDesktop ? 14 : 7,
        ),

        // Green underline
        Container(
          width: isDesktop ? 68 : 42,
          height: isDesktop ? 4 : 3,
          decoration: BoxDecoration(
            color: const Color(0xFF5EAA4F),
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        SizedBox(
          height: isDesktop ? 18 : 8,
        ),

        // Main heading
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: isDesktop ? 46 : 26,
              fontWeight: FontWeight.w800,
              height: isDesktop ? 1.04 : 1.02,
              color: const Color(0xFF18252A),
            ),
            children: const [
              TextSpan(
                text: 'Stay organized,\n',
              ),
              TextSpan(
                text: 'waste less.',
                style: TextStyle(
                  color: Color(0xFF4AA447),
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: isDesktop ? 12 : 7,
        ),

        // Subtitle
        Text(
          'Track what matters. Save more.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isDesktop ? 17 : 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF596269),
          ),
        ),

        // Desktop only features
        if (isDesktop) ...[
          const SizedBox(height: 24),

          Wrap(
            spacing: 26,
            runSpacing: 12,
            children: const [
              _HeroFeature(
                icon: Icons.analytics_outlined,
                title: 'Track',
                subtitle: 'Monitor expiry',
              ),
              _HeroFeature(
                icon: Icons.eco_outlined,
                title: 'Reduce',
                subtitle: 'Cut waste',
              ),
              _HeroFeature(
                icon: Icons.volunteer_activism_outlined,
                title: 'Donate',
                subtitle: 'Donate & help',
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // HERO LOGO
  // ===========================================================================

  Widget _buildHeroLogo({
    required bool isDesktop,
  }) {
    final logoSize = isDesktop ? 190.0 : 70.0;

    return Center(
      child: Container(
        width: logoSize,
        height: logoSize,
        padding: EdgeInsets.all(
          isDesktop ? 18 : 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFDCE9D8),
            width: isDesktop ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4AA447).withOpacity(0.10),
              blurRadius: isDesktop ? 20 : 10,
              spreadRadius: isDesktop ? 2 : 1,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(
              Icons.inventory_2_outlined,
              size: isDesktop ? 72 : 30,
              color: AppTheme.primaryGreen,
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText:
              'Search items, categories, batch number...',
          hintStyle: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.textMuted,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OVERVIEW CARDS
  // ===========================================================================

  Widget _buildOverviewCards(
    ProductProvider provider,
    bool isDesktop,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  title: 'Expiring Soon',
                  count: provider.expiringSoonCount,
                  color:
                      AppTheme.expiringSoonYellow,
                  bgColor:
                      const Color(0xFFFFF8E1),
                  icon: Icons.schedule,
                  isSelected:
                      _selectedFilter ==
                          DashboardFilter.expiringSoon,
                  onTap: () {
                    setState(() {
                      _selectedFilter =
                          _selectedFilter ==
                                  DashboardFilter.expiringSoon
                              ? DashboardFilter.all
                              : DashboardFilter.expiringSoon;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _OverviewCard(
                  title: 'Expired',
                  count: provider.expiredCount,
                  color: AppTheme.expiredRed,
                  bgColor:
                      const Color(0xFFFEE2E2),
                  icon:
                      Icons.warning_amber_rounded,
                  isSelected:
                      _selectedFilter ==
                          DashboardFilter.expired,
                  onTap: () {
                    setState(() {
                      _selectedFilter =
                          _selectedFilter ==
                                  DashboardFilter.expired
                              ? DashboardFilter.all
                              : DashboardFilter.expired;
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _OverviewCard(
                  title: 'All Items',
                  count: provider.allItemsCount,
                  color: AppTheme.primaryGreen,
                  bgColor:
                      const Color(0xFFECFDF5),
                  icon:
                      Icons.inventory_2_outlined,
                  isSelected:
                      _selectedFilter ==
                          DashboardFilter.all,
                  onTap: () {
                    setState(() {
                      _selectedFilter =
                          DashboardFilter.all;
                    });
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _OverviewCard(
                    title: 'Expiring Soon',
                    count:
                        provider.expiringSoonCount,
                    color:
                        AppTheme.expiringSoonYellow,
                    bgColor:
                        const Color(0xFFFFF8E1),
                    icon: Icons.schedule,
                    isSelected:
                        _selectedFilter ==
                            DashboardFilter.expiringSoon,
                    onTap: () {
                      setState(() {
                        _selectedFilter =
                            _selectedFilter ==
                                    DashboardFilter.expiringSoon
                                ? DashboardFilter.all
                                : DashboardFilter.expiringSoon;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _OverviewCard(
                    title: 'Expired',
                    count: provider.expiredCount,
                    color:
                        AppTheme.expiredRed,
                    bgColor:
                        const Color(0xFFFEE2E2),
                    icon: Icons.warning_amber_rounded,
                    isSelected:
                        _selectedFilter ==
                            DashboardFilter.expired,
                    onTap: () {
                      setState(() {
                        _selectedFilter =
                            _selectedFilter ==
                                    DashboardFilter.expired
                                ? DashboardFilter.all
                                : DashboardFilter.expired;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _OverviewCard(
              title: 'All Items',
              count: provider.allItemsCount,
              color: AppTheme.primaryGreen,
              bgColor:
                  const Color(0xFFECFDF5),
              icon:
                  Icons.inventory_2_outlined,
              isSelected:
                  _selectedFilter ==
                      DashboardFilter.all,
              onTap: () {
                setState(() {
                  _selectedFilter =
                      DashboardFilter.all;
                });
              },
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // PRODUCTS SECTION
  // ===========================================================================

  Widget _buildProductsSection(
    ProductProvider provider,
    bool isDesktop,
  ) {
    final items =
        _getFilteredProducts(provider);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _sectionTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            TextButton(
              onPressed: () {},
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.cardBorder,
              ),
            ),
            child: const Center(
              child: Text(
                'No products available in this view.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      AppTheme.textSecondary,
                ),
              ),
            ),
          )
        else if (isDesktop)
          _buildProductsTable(items)
        else
          _buildProductsCards(items),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP PRODUCT TABLE
  // ===========================================================================

  Widget _buildProductsTable(
    List<ProductModel> items,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            return SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(
                  minWidth:
                      constraints.maxWidth,
                ),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(
                    AppTheme.backgroundMint,
                  ),
                  dataRowMaxHeight: 72,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Batch No.',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Item',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Category',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Quantity',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Expiration Date',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Days Left',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Price',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Discount',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  rows: items.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            product.batchNumber
                                        ?.isNotEmpty ==
                                    true
                                ? product
                                    .batchNumber!
                                : '-',
                            style:
                                const TextStyle(
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            product.name,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            product.category,
                            style:
                                const TextStyle(
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ),

                        DataCell(
                          _QuantityControl(
                            product: product,
                          ),
                        ),

                        DataCell(
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(
                                product.expiryDate),
                            style:
                                const TextStyle(
                              color: AppTheme
                                  .textSecondary,
                            ),
                          ),
                        ),

                        DataCell(
                          _DaysLeftBadge(
                            days:
                                product.daysRemaining,
                          ),
                        ),

                        DataCell(
                          _PriceColumn(
                            product: product,
                          ),
                        ),

                        DataCell(
                          _DiscountBadge(
                            percentage:
                                product
                                    .discountPercentage,
                          ),
                        ),

                        DataCell(
                          _StatusBadge(
                            label:
                                product.statusLabel,
                          ),
                        ),

                        DataCell(
                          _ProductActionMenu(
                            product: product,
                            onSaleIdeas: () {
                              showSaleIdeasDialog(
                                context,
                                product,
                              );
                            },
                            onDonate: () {
                              _showDonateDialog(
                                context,
                                product,
                              );
                            },
                            onDelete: () {
                              _confirmDeleteProduct(
                                context,
                                product,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE PRODUCT CARDS
  // ===========================================================================

  Widget _buildProductsCards(
    List<ProductModel> items,
  ) {
    return Column(
      children: items.map((product) {
        return _MobileProductCard(
          product: product,
          onSaleIdeas: () {
            showSaleIdeasDialog(
              context,
              product,
            );
          },
          onDonate: () {
            _showDonateDialog(
              context,
              product,
            );
          },
          onDelete: () {
            _confirmDeleteProduct(
              context,
              product,
            );
          },
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // EXPIRING SOON TABLE
  // ===========================================================================

  Widget _buildExpiringSoonTable(
    List<ProductModel> items,
  ) {
    return _buildProductsTable(items);
  }

  // ===========================================================================
  // EXPIRING SOON CARDS
  // ===========================================================================

  Widget _buildExpiringSoonCards(
    List<ProductModel> items,
  ) {
    return _buildProductsCards(items);
  }

  // ===========================================================================
  // EXPIRED TABLE
  // ===========================================================================

  Widget _buildExpiredTable(
    List<ProductModel> items,
  ) {
    return _buildProductsTable(items);
  }

  // ===========================================================================
  // EXPIRED CARDS
  // ===========================================================================

  Widget _buildExpiredCards(
    List<ProductModel> items,
  ) {
    return _buildProductsCards(items);
  }

  // ===========================================================================
  // SALE OPPORTUNITIES
  // ===========================================================================

  void _showSaleOpportunities(
    BuildContext context,
    ProductModel product,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SaleOpportunitiesSheet(
          product: product,
        );
      },
    );
  }

  // ===========================================================================
  // DONATE DIALOG
  // ===========================================================================

  void _showDonateDialog(
    BuildContext context,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: DonateDialog(
            product: product,
          ),
        );
      },
    );
  }

  // ===========================================================================
  // DELETE PRODUCT
  // ===========================================================================

  void _confirmDeleteProduct(
    BuildContext context,
    ProductModel product,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline,
                color:
                    AppTheme.expiredRed,
              ),
              SizedBox(width: 10),
              Text(
                'Delete Item',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove "${product.name}" from the dashboard table?',
            style: const TextStyle(
              fontSize: 14,
              color:
                  AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      AppTheme.textSecondary,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Provider.of<
                    ProductProvider>(
                  context,
                  listen: false,
                ).deleteProduct(
                    product.id);

                Navigator.pop(
                    dialogContext);

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${product.name} removed from dashboard',
                    ),
                    backgroundColor:
                        AppTheme.expiredRed,
                    behavior:
                        SnackBarBehavior
                            .floating,
                    duration:
                        const Duration(
                            seconds: 2),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(10),
                    ),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppTheme.expiredRed,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          10),
                ),
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // CATEGORY HELPERS
  // ===========================================================================

  Color _getCategoryColor(
    String category,
  ) {
    switch (category) {
      case 'Dairy':
        return AppTheme.donateBlue;

      case 'Bakery':
        return AppTheme.warningOrange;

      case 'Beverages':
        return AppTheme.accentGreen;

      case 'Snacks':
        return AppTheme.discountPurple;

      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Dairy':
        return Icons.water_drop_outlined;

      case 'Bakery':
        return Icons.bakery_dining_outlined;

      case 'Beverages':
        return Icons.local_cafe_outlined;

      case 'Snacks':
        return Icons.cookie_outlined;

      default:
        return Icons.shopping_bag_outlined;
    }
  }
}

// =============================================================================
// HERO FEATURE
// =============================================================================

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF0F7ED),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color:
                const Color(0xFF4AA447),
          ),
        ),

        const SizedBox(width: 9),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF20282C),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF697277),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// MOBILE PRODUCT CARD
// =============================================================================

class _MobileProductCard
    extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onSaleIdeas;
  final VoidCallback onDonate;
  final VoidCallback onDelete;

  const _MobileProductCard({
    required this.product,
    required this.onSaleIdeas,
    required this.onDonate,
    required this.onDelete,
  });

  @override
  Widget build(
      BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: product.isExpired
              ? const Color(
                  0xFFFECACA)
              : AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: product.isExpired
                ? AppTheme.expiredRed
                    .withOpacity(0.04)
                : Colors.black
                    .withOpacity(0.025),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ROW 1
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppTheme.textPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _StatusBadge(
                label:
                    product.statusLabel,
              ),

              const SizedBox(width: 2),

              _ProductActionMenu(
                product: product,
                onSaleIdeas:
                    onSaleIdeas,
                onDonate: onDonate,
                onDelete: onDelete,
              ),
            ],
          ),

          const SizedBox(height: 9),

          // ROW 2
          Row(
            children: [
              Flexible(
                child:
                    _MobileInfoItem(
                  icon:
                      _getCategoryIcon(
                    product.category,
                  ),
                  label:
                      product.category,
                ),
              ),

              const SizedBox(width: 14),

              Flexible(
                child:
                    _MobileInfoItem(
                  icon: Icons
                      .calendar_today_outlined,
                  label: DateFormat(
                    'MMM dd, yyyy',
                  ).format(
                      product.expiryDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ROW 3
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              _DaysLeftBadge(
                days:
                    product.daysRemaining,
              ),

              _PriceColumn(
                product: product,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ROW 4
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              _DiscountBadge(
                percentage:
                    product
                        .discountPercentage,
              ),

              _QuantityControl(
                product: product,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Dairy':
        return Icons
            .water_drop_outlined;

      case 'Bakery':
        return Icons
            .bakery_dining_outlined;

      case 'Beverages':
        return Icons
            .local_cafe_outlined;

      case 'Snacks':
        return Icons
            .cookie_outlined;

      case 'Personal Care':
        return Icons
            .health_and_safety_outlined;

      default:
        return Icons
            .category_outlined;
    }
  }
}

// =============================================================================
// MOBILE INFO ITEM
// =============================================================================

class _MobileInfoItem
    extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MobileInfoItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
      BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color:
              AppTheme.textMuted,
        ),

        const SizedBox(width: 5),

        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textSecondary,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// THREE DOT PRODUCT ACTION MENU
// =============================================================================

class _ProductActionMenu extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onSaleIdeas;
  final VoidCallback onDonate;
  final VoidCallback onDelete;

  const _ProductActionMenu({
    required this.product,
    required this.onSaleIdeas,
    required this.onDonate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      padding: EdgeInsets.zero,
      iconSize: 22,
      icon: const Icon(
        Icons.more_vert,
        color: AppTheme.textSecondary,
      ),

      onSelected: (value) {
        switch (value) {
          case 'donate':
            onDonate();
            break;

          case 'sale_ideas':
            onSaleIdeas();
            break;

          case 'delete':
            onDelete();
            break;
        }
      },

      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        // ============================================================
        // DONATE
        // ============================================================
        //
        // Donate is available for:
        // 1. Fresh products
        // 2. Expiring soon products
        // 3. Expired products
        //
        items.add(
          const PopupMenuItem<String>(
            value: 'donate',
            child: Row(
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  size: 19,
                  color: AppTheme.donateBlue,
                ),
                SizedBox(width: 12),
                Text(
                  'Donate',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

        // ============================================================
        // SALE IDEAS
        // ============================================================
        //
        // Sale Ideas is available ONLY when the product is NOT expired.
        //
        // Therefore:
        // Fresh          -> Sale Ideas
        // Expiring Soon  -> Sale Ideas
        // Expired        -> NO Sale Ideas
        //
        if (!product.isExpired) {
          items.add(
            const PopupMenuItem<String>(
              value: 'sale_ideas',
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 19,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sale Ideas',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ============================================================
        // DELETE
        // ============================================================
        //
        // Delete is available for every product.
        //
        items.add(
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 19,
                  color: AppTheme.expiredRed,
                ),
                SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.expiredRed,
                  ),
                ),
              ],
            ),
          ),
        );

        return items;
      },
    );
  }
}

// =============================================================================
// QUANTITY CONTROL
// =============================================================================

class _QuantityControl
    extends StatelessWidget {
  final ProductModel product;

  const _QuantityControl({
    required this.product,
  });

  @override
  Widget build(
      BuildContext context) {
    final provider =
        Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    return Container(
      height: 32,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 2,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF3F4F6),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color:
              AppTheme.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          InkWell(
            onTap:
                product.quantity > 0
                    ? () {
                        provider
                            .updateQuantity(
                          product.id,
                          product.quantity -
                              1,
                        );
                      }
                    : null,
            borderRadius:
                BorderRadius.circular(6),
            child: Padding(
              padding:
                  const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 14,
                color: product
                            .quantity >
                        0
                    ? AppTheme
                        .textPrimary
                    : Colors.grey,
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
            ),
            child: Text(
              '${product.quantity}',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 13,
                color:
                    AppTheme.textPrimary,
              ),
            ),
          ),

          InkWell(
            onTap: () {
              provider.updateQuantity(
                product.id,
                product.quantity + 1,
              );
            },
            borderRadius:
                BorderRadius.circular(6),
            child: const Padding(
              padding:
                  EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 14,
                color:
                    AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// OVERVIEW CARD
// =============================================================================

class _OverviewCard
    extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.title,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        padding:
            const EdgeInsets.all(18),
        decoration:
            BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : color.withOpacity(0.2),
            width:
                isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  color.withOpacity(
                isSelected
                    ? 0.15
                    : 0.06,
              ),
              blurRadius:
                  isSelected ? 16 : 12,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(8),
                  decoration:
                      BoxDecoration(
                    color: color
                        .withOpacity(0.15),
                    borderRadius:
                        BorderRadius
                            .circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),

                Icon(
                  Icons
                      .arrow_forward_ios,
                  color: color,
                  size: 14,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),

                const SizedBox(width: 4),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Text(
                    'items',
                    style: TextStyle(
                      fontSize: 13,
                      color: color
                          .withOpacity(0.7),
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DAYS LEFT BADGE
// =============================================================================

class _DaysLeftBadge
    extends StatelessWidget {
  final int days;

  const _DaysLeftBadge({
    required this.days,
  });

  @override
  Widget build(
      BuildContext context) {
    Color badgeColor;
    String label;

    if (days < 0) {
      badgeColor =
          AppTheme.expiredRed;
      label =
          '${days.abs()}d ago';
    } else if (days <= 3) {
      badgeColor =
          AppTheme.expiredRed;
      label = '$days days';
    } else if (days <= 5) {
      badgeColor =
          AppTheme.warningOrange;
      label = '$days days';
    } else if (days <= 7) {
      badgeColor =
          AppTheme.expiringSoonYellow;
      label = '$days days';
    } else {
      badgeColor =
          AppTheme.freshGreen;
      label = '$days days';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            badgeColor.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              badgeColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color: badgeColor,
        ),
      ),
    );
  }
}

// =============================================================================
// PRICE
// =============================================================================

class _PriceColumn
    extends StatelessWidget {
  final ProductModel product;

  const _PriceColumn({
    required this.product,
  });

  @override
  Widget build(
      BuildContext context) {
    if (product.discountPercentage ==
        0) {
      return Text(
        '\$${product.originalPrice.toStringAsFixed(2)}',
        style:
            const TextStyle(
          fontWeight:
              FontWeight.w600,
          fontSize: 14,
          color:
              AppTheme.textPrimary,
        ),
      );
    }

    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.originalPrice.toStringAsFixed(2)}',
          style:
              const TextStyle(
            fontSize: 11,
            color:
                AppTheme.textMuted,
            decoration:
                TextDecoration
                    .lineThrough,
          ),
        ),

        Text(
          '\$${product.discountedPrice.toStringAsFixed(2)}',
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
            color:
                AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DISCOUNT BADGE
// =============================================================================

class _DiscountBadge
    extends StatelessWidget {
  final double percentage;

  const _DiscountBadge({
    required this.percentage,
  });

  @override
  Widget build(
      BuildContext context) {
    if (percentage == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color: AppTheme
            .discountPurple
            .withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme
              .discountPurple
              .withOpacity(0.3),
        ),
      ),
      child: Text(
        '${percentage.toInt()}% OFF',
        style:
            const TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
          color:
              AppTheme.discountPurple,
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS BADGE
// =============================================================================

class _StatusBadge
    extends StatelessWidget {
  final String label;

  const _StatusBadge({
    required this.label,
  });

  @override
  Widget build(
      BuildContext context) {
    Color color;

    switch (label) {
      case 'Expired':
        color =
            AppTheme.expiredRed;
        break;

      case 'Expiring Soon':
        color =
            AppTheme.expiringSoonYellow;
        break;

      default:
        color =
            AppTheme.freshGreen;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// INFO CHIP
// =============================================================================

class _InfoChip
    extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
      BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color:
              AppTheme.textMuted,
        ),

        const SizedBox(width: 4),

        Flexible(
          child: Text(
            label,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SALE OPPORTUNITIES SHEET
// =============================================================================

class _SaleOpportunitiesSheet
    extends StatelessWidget {
  final ProductModel product;

  const _SaleOpportunitiesSheet({
    required this.product,
  });

  @override
  Widget build(
      BuildContext context) {
    final suggestions =
        _generateSuggestions(product);

    return Container(
      constraints:
          BoxConstraints(
        maxHeight:
            MediaQuery.of(context)
                    .size
                    .height *
                0.75,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          Container(
            width: 40,
            height: 4,
            decoration:
                BoxDecoration(
              color:
                  AppTheme.cardBorder,
              borderRadius:
                  BorderRadius.circular(
                2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient:
                        const LinearGradient(
                      colors: [
                        AppTheme
                            .primaryGreen,
                        AppTheme
                            .accentGreen,
                      ],
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(12),
                  ),
                  child:
                      const Icon(
                    Icons.auto_awesome,
                    color:
                        Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'AI Sale Opportunities',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: AppTheme
                              .textPrimary,
                        ),
                      ),

                      Text(
                        'Smart suggestions for ${product.name}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color: AppTheme
                              .textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      Navigator.pop(
                          context),
                  icon:
                      const Icon(
                    Icons.close,
                    color:
                        AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Container(
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.backgroundMint,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          product.name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(
                            height: 4),

                        Text(
                          '${product.category}  •  ${product.daysRemaining} days left  •  \$${product.originalPrice.toStringAsFixed(2)}',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (product
                          .discountPercentage >
                      0)
                    _DiscountBadge(
                      percentage:
                          product
                              .discountPercentage,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Flexible(
            child:
                ListView.separated(
              shrinkWrap: true,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
              ),
              itemCount:
                  suggestions.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                height: 10,
              ),
              itemBuilder:
                  (context, index) {
                final suggestion =
                    suggestions[index];

                return Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(14),
                    border:
                        Border.all(
                      color: AppTheme
                          .cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .black
                            .withOpacity(
                                0.02),
                        blurRadius: 6,
                        offset:
                            const Offset(
                          0,
                          2,
                        ),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .all(10),
                        decoration:
                            BoxDecoration(
                          color:
                              suggestion[
                                  'color'] as Color,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            Icon(
                          suggestion[
                                  'icon']
                              as IconData,
                          color:
                              Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(
                          width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              suggestion[
                                      'title']
                                  as String,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              suggestion[
                                      'description']
                                  as String,
                              style:
                                  const TextStyle(
                                fontSize: 12,
                                color: AppTheme
                                    .textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Map<String, dynamic>>
      _generateSuggestions(
    ProductModel product,
  ) {
    return [
      {
        'icon':
            Icons.card_giftcard,
        'color':
            AppTheme.warningOrange,
        'title':
            '🎁 Bundle Offer',
        'description':
            'Create a "${product.name} + complementary item" bundle at ${(product.discountPercentage + 5).toInt()}% off. Bundles can help move products faster near expiry.',
      },
      {
        'icon':
            Icons.flash_on,
        'color':
            AppTheme.expiredRed,
        'title':
            '⚡ Flash Sale — 2 Hour Window',
        'description':
            'Launch a time-limited flash sale for ${product.name} at \$${product.discountedPrice.toStringAsFixed(2)} to create urgency.',
      },
      {
        'icon':
            Icons.campaign,
        'color':
            AppTheme.discountPurple,
        'title':
            '📢 Social Media Promo',
        'description':
            'Post a "Last Chance Deal" on your store\'s social channels for ${product.name}. Include the remaining ${product.daysRemaining} days.',
      },
      {
        'icon':
            Icons.location_on,
        'color':
            AppTheme.primaryGreen,
        'title':
            '📍 Local Event Opportunity',
        'description':
            'Promote ${product.category} items at a nearby local event or market using a special limited-time price.',
      },
      {
        'icon':
            Icons.people,
        'color':
            AppTheme.donateBlue,
        'title':
            '🤝 B2B Quick Sale',
        'description':
            'Offer ${product.name} in bulk to nearby restaurants or cafes at wholesale pricing to clear inventory faster.',
      },
    ];
  }
}