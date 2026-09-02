import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'donate_dialog.dart';
import 'sale_ideas_dialog.dart';

enum DashboardFilter { all, expiringSoon, expired }

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid ?? '';
      productProvider.loadProducts(userId).then((_) {
        _animController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _getFilteredTop5(ProductProvider provider) {
    switch (_selectedFilter) {
      case DashboardFilter.expiringSoon:
        return provider.expiringSoonProducts.take(5).toList();
      case DashboardFilter.expired:
        return provider.expiredProducts.take(5).toList();
      case DashboardFilter.all:
      default:
        return provider.top5Products;
    }
  }

  String get _top5Title {
    switch (_selectedFilter) {
      case DashboardFilter.expiringSoon:
        return 'Top 5 Expiring Soon Items';
      case DashboardFilter.expired:
        return 'Top 5 Expired Items';
      case DashboardFilter.all:
      default:
        return 'Top 5 Items (All Items)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final user = authProvider.currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    if (productProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    return FadeTransition(
      opacity: _fadeIn,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32.0 : 16.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Welcome Banner ──
            _buildHeroBanner(user?.displayName ?? 'User', isDesktop),
            const SizedBox(height: 20),

            // ── Search Bar ──
            _buildSearchBar(),
            const SizedBox(height: 24),

            // ── Overview Section ──
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Overview Cards (Clickable Filter Cards) ──
            _buildOverviewCards(productProvider, isDesktop),
            const SizedBox(height: 28),

            // ── All Products Section (Single Table matching reference) ──
            _buildProductsSection(productProvider, isDesktop),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(String name, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28.0 : 20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5A36), Color(0xFF1A7A4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good to see you, $name! 👋',
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay organized,\nwaste less.',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Track what matters. Save more.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_basket,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
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
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search items, categories, batch number...',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 20),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(ProductProvider provider, bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      if (isWide) {
        return Row(
          children: [
            Expanded(
              child: _OverviewCard(
                title: 'Expiring Soon',
                count: provider.expiringSoonCount,
                color: AppTheme.expiringSoonYellow,
                bgColor: const Color(0xFFFFF8E1),
                icon: Icons.schedule,
                isSelected: _selectedFilter == DashboardFilter.expiringSoon,
                onTap: () => setState(() {
                  _selectedFilter = _selectedFilter == DashboardFilter.expiringSoon
                      ? DashboardFilter.all
                      : DashboardFilter.expiringSoon;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _OverviewCard(
                title: 'Expired',
                count: provider.expiredCount,
                color: AppTheme.expiredRed,
                bgColor: const Color(0xFFFEE2E2),
                icon: Icons.warning_amber_rounded,
                isSelected: _selectedFilter == DashboardFilter.expired,
                onTap: () => setState(() {
                  _selectedFilter = _selectedFilter == DashboardFilter.expired
                      ? DashboardFilter.all
                      : DashboardFilter.expired;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _OverviewCard(
                title: 'All Items',
                count: provider.allItemsCount,
                color: AppTheme.primaryGreen,
                bgColor: const Color(0xFFECFDF5),
                icon: Icons.inventory_2_outlined,
                isSelected: _selectedFilter == DashboardFilter.all,
                onTap: () => setState(() => _selectedFilter = DashboardFilter.all),
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
                  count: provider.expiringSoonCount,
                  color: AppTheme.expiringSoonYellow,
                  bgColor: const Color(0xFFFFF8E1),
                  icon: Icons.schedule,
                  isSelected: _selectedFilter == DashboardFilter.expiringSoon,
                  onTap: () => setState(() {
                    _selectedFilter = _selectedFilter == DashboardFilter.expiringSoon
                        ? DashboardFilter.all
                        : DashboardFilter.expiringSoon;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewCard(
                  title: 'Expired',
                  count: provider.expiredCount,
                  color: AppTheme.expiredRed,
                  bgColor: const Color(0xFFFEE2E2),
                  icon: Icons.warning_amber_rounded,
                  isSelected: _selectedFilter == DashboardFilter.expired,
                  onTap: () => setState(() {
                    _selectedFilter = _selectedFilter == DashboardFilter.expired
                        ? DashboardFilter.all
                        : DashboardFilter.expired;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OverviewCard(
            title: 'All Items',
            count: provider.allItemsCount,
            color: AppTheme.primaryGreen,
            bgColor: const Color(0xFFECFDF5),
            icon: Icons.inventory_2_outlined,
            isSelected: _selectedFilter == DashboardFilter.all,
            onTap: () => setState(() => _selectedFilter = DashboardFilter.all),
          ),
        ],
      );
    });
  }

  List<ProductModel> _getFilteredProducts(ProductProvider provider) {
    List<ProductModel> list;
    switch (_selectedFilter) {
      case DashboardFilter.expiringSoon:
        list = provider.expiringSoonProducts;
        break;
      case DashboardFilter.expired:
        list = provider.expiredProducts;
        break;
      case DashboardFilter.all:
      default:
        list = provider.allProducts;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      return list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final categoryMatch = p.category.toLowerCase().contains(q);
        final brandMatch = (p.brand ?? '').toLowerCase().contains(q);
        final batchMatch = (p.batchNumber ?? '').toLowerCase().contains(q);
        return nameMatch || categoryMatch || brandMatch || batchMatch;
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
      default:
        return 'All Items';
    }
  }

  Widget _buildProductsSection(ProductProvider provider, bool isDesktop) {
    final items = _getFilteredProducts(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Center(
              child: Text(
                'No products available in this view.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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

  Widget _buildProductsTable(List<ProductModel> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.backgroundMint),
                  dataRowMaxHeight: 72,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Batch No.', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Expiration Date', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Days Left', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                  ],
                  rows: items.map((product) {
                    return DataRow(cells: [
                      DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(product.category, style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(product.batchNumber?.isNotEmpty == true ? product.batchNumber! : '-', style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(_QuantityControl(product: product)),
                      DataCell(Text(DateFormat('MMM dd, yyyy').format(product.expiryDate), style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(_DaysLeftBadge(days: product.daysRemaining)),
                      DataCell(_PriceColumn(product: product)),
                      DataCell(_DiscountBadge(percentage: product.discountPercentage)),
                      DataCell(_StatusBadge(label: product.statusLabel)),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                          tooltip: 'Actions',
                          onSelected: (value) {
                            if (value == 'sale_ideas') {
                              showSaleIdeasDialog(context, product);
                            } else if (value == 'donate') {
                              _showDonateDialog(context, product);
                            } else if (value == 'delete') {
                              _confirmDeleteProduct(context, product);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            final List<PopupMenuEntry<String>> items = [];
                            // Rule: Sale Ideas for Fresh and Expiring Soon products (NOT for Expired)
                            if (!product.isExpired) {
                              items.add(
                                const PopupMenuItem<String>(
                                  value: 'sale_ideas',
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryGreen),
                                      SizedBox(width: 10),
                                      Text('Sale Ideas', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Rule: Donate for Expiring Soon and Expired products
                            if (product.isExpiringSoon || product.isExpired) {
                              items.add(
                                const PopupMenuItem<String>(
                                  value: 'donate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.volunteer_activism, size: 18, color: AppTheme.donateBlue),
                                      SizedBox(width: 10),
                                      Text('Donate', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: AppTheme.expiredRed),
                                    SizedBox(width: 10),
                                    Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.expiredRed)),
                                  ],
                                ),
                              ),
                            );
                            return items;
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductsCards(List<ProductModel> items) {
    return Column(
      children: items.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(label: product.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: product.category,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM dd, yyyy').format(product.expiryDate),
                  ),
                  const Spacer(),
                  _QuantityControl(product: product),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DaysLeftBadge(days: product.daysRemaining),
                  _PriceColumn(product: product),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DiscountBadge(percentage: product.discountPercentage),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (product.isExpiringSoon || product.isExpired)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ElevatedButton.icon(
                            onPressed: () => _showDonateDialog(context, product),
                            icon: const Icon(Icons.volunteer_activism, size: 13),
                            label: const Text('Donate', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.donateBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      if (!product.isExpired)
                        TextButton.icon(
                          onPressed: () => showSaleIdeasDialog(context, product),
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: const Text('Sale Ideas', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Full-width desktop tables using SizedBox(width: double.infinity) & LayoutBuilder
  Widget _buildExpiringSoonTable(List<ProductModel> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.backgroundMint),
                  dataRowMaxHeight: 72,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Batch No.', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Expiration Date', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Days Left', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                  ],
                  rows: items.map((product) {
                    return DataRow(cells: [
                      DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(product.category, style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(product.batchNumber?.isNotEmpty == true ? product.batchNumber! : '-', style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(_QuantityControl(product: product)),
                      DataCell(Text(DateFormat('MMM dd, yyyy').format(product.expiryDate), style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(_DaysLeftBadge(days: product.daysRemaining)),
                      DataCell(_PriceColumn(product: product)),
                      DataCell(_DiscountBadge(percentage: product.discountPercentage)),
                      DataCell(_StatusBadge(label: product.statusLabel)),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                          tooltip: 'Actions',
                          onSelected: (value) {
                            if (value == 'sale_ideas') {
                              showSaleIdeasDialog(context, product);
                            } else if (value == 'donate') {
                              _showDonateDialog(context, product);
                            } else if (value == 'delete') {
                              _confirmDeleteProduct(context, product);
                            }
                          },
                          itemBuilder: (BuildContext context) => const [
                            PopupMenuItem<String>(
                              value: 'sale_ideas',
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryGreen),
                                  SizedBox(width: 10),
                                  Text('Sale Ideas', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'donate',
                              child: Row(
                                children: [
                                  Icon(Icons.volunteer_activism, size: 18, color: AppTheme.donateBlue),
                                  SizedBox(width: 10),
                                  Text('Donate', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppTheme.expiredRed),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.expiredRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpiringSoonCards(List<ProductModel> items) {
    return Column(
      children: items.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(label: product.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: product.category,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM dd, yyyy').format(product.expiryDate),
                  ),
                  const Spacer(),
                  _QuantityControl(product: product),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DaysLeftBadge(days: product.daysRemaining),
                  _PriceColumn(product: product),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DiscountBadge(percentage: product.discountPercentage),
                  TextButton.icon(
                    onPressed: () => _showSaleOpportunities(context, product),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('More Sale Opportunities', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpiredTable(List<ProductModel> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFFEF2F2)),
                  dataRowMaxHeight: 72,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Batch No.', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Expired On', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Days Ago', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13))),
                  ],
                  rows: items.map((product) {
                    return DataRow(cells: [
                      DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(product.category, style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text(product.batchNumber?.isNotEmpty == true ? product.batchNumber! : '-', style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(_QuantityControl(product: product)),
                      DataCell(Text(DateFormat('MMM dd, yyyy').format(product.expiryDate), style: const TextStyle(color: AppTheme.textSecondary))),
                      DataCell(Text('${product.daysRemaining.abs()} days ago', style: const TextStyle(color: AppTheme.expiredRed, fontWeight: FontWeight.w600))),
                      DataCell(_StatusBadge(label: product.statusLabel)),
                      DataCell(
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                          tooltip: 'Actions',
                          onSelected: (value) {
                            if (value == 'donate') {
                              _showDonateDialog(context, product);
                            } else if (value == 'delete') {
                              _confirmDeleteProduct(context, product);
                            }
                          },
                          itemBuilder: (BuildContext context) => const [
                            PopupMenuItem<String>(
                              value: 'donate',
                              child: Row(
                                children: [
                                  Icon(Icons.volunteer_activism, size: 18, color: AppTheme.donateBlue),
                                  SizedBox(width: 10),
                                  Text('Donate', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppTheme.expiredRed),
                                  SizedBox(width: 10),
                                  Text('Delete', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.expiredRed)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpiredCards(List<ProductModel> items) {
    return Column(
      children: items.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.expiredRed.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category}  •  ${product.quantity} pcs  •  Expired ${product.daysRemaining.abs()} days ago',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showDonateDialog(context, product),
                icon: const Icon(Icons.volunteer_activism, size: 16),
                label: const Text('Donate', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.donateBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }



  void _showSaleOpportunities(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaleOpportunitiesSheet(product: product),
    );
  }

  void _showDonateDialog(BuildContext context, ProductModel product) {
    showDonateDialog(context, product);
  }

  void _confirmDeleteProduct(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.expiredRed),
            SizedBox(width: 10),
            Text('Delete Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${product.name}" from the dashboard table?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} removed from dashboard'),
                  backgroundColor: AppTheme.expiredRed,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expiredRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
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

  IconData _getCategoryIcon(String category) {
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

class _QuantityControl extends StatelessWidget {
  final ProductModel product;
  const _QuantityControl({required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: product.quantity > 0
                ? () => provider.updateQuantity(product.id, product.quantity - 1)
                : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.remove,
                size: 14,
                color: product.quantity > 0 ? AppTheme.textPrimary : Colors.grey,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: Text(
              '${product.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () => provider.updateQuantity(product.id, product.quantity + 1),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.add,
                size: 14,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.15 : 0.06),
              blurRadius: isSelected ? 16 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'items',
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
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

class _DaysLeftBadge extends StatelessWidget {
  final int days;
  const _DaysLeftBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;

    if (days < 0) {
      badgeColor = AppTheme.expiredRed;
      label = '${days.abs()}d ago';
    } else if (days <= 3) {
      badgeColor = AppTheme.expiredRed;
      label = '$days days';
    } else if (days <= 5) {
      badgeColor = AppTheme.warningOrange;
      label = '$days days';
    } else if (days <= 7) {
      badgeColor = AppTheme.expiringSoonYellow;
      label = '$days days';
    } else {
      badgeColor = AppTheme.freshGreen;
      label = '$days days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: badgeColor,
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final ProductModel product;
  const _PriceColumn({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.discountPercentage == 0) {
      return Text(
        '\$${product.originalPrice.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${product.originalPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Text(
          '\$${product.discountedPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final double percentage;
  const _DiscountBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    if (percentage == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.discountPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.discountPurple.withOpacity(0.3)),
      ),
      child: Text(
        '${percentage.toInt()}% OFF',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.discountPurple,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (label) {
      case 'Expired':
        color = AppTheme.expiredRed;
        break;
      case 'Expiring Soon':
        color = AppTheme.expiringSoonYellow;
        break;
      default:
        color = AppTheme.freshGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _SaleOpportunitiesSheet extends StatelessWidget {
  final ProductModel product;
  const _SaleOpportunitiesSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final suggestions = _generateSuggestions(product);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Sale Opportunities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Smart suggestions for ${product.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.backgroundMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${product.category}  •  ${product.daysRemaining} days left  •  \$${product.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (product.discountPercentage > 0) _DiscountBadge(percentage: product.discountPercentage),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return Container(
                  padding: const EdgeInsets.all(16),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: s['color'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s['icon'] as IconData, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['description'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
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

  List<Map<String, dynamic>> _generateSuggestions(ProductModel product) {
    return [
      {
        'icon': Icons.card_giftcard,
        'color': AppTheme.warningOrange,
        'title': '🎁 Bundle Offer',
        'description':
            'Create a "${product.name} + complementary item" bundle at ${(product.discountPercentage + 5).toInt()}% off. Bundles sell 3x faster than individual items near expiry.',
      },
      {
        'icon': Icons.flash_on,
        'color': AppTheme.expiredRed,
        'title': '⚡ Flash Sale — 2 Hour Window',
        'description':
            'Launch a time-limited flash sale for ${product.name} at \$${product.discountedPrice.toStringAsFixed(2)}. Urgency drives 40% more conversions. Best between 11 AM – 1 PM.',
      },
      {
        'icon': Icons.campaign,
        'color': AppTheme.discountPurple,
        'title': '📢 Social Media Promo',
        'description':
            'Post a "Last Chance Deal" on your store\'s social channels for ${product.name}. Include a countdown timer showing ${product.daysRemaining} days remaining.',
      },
      {
        'icon': Icons.location_on,
        'color': AppTheme.primaryGreen,
        'title': '📍 Local Event Opportunity',
        'description':
            'The Weekend Farmers Market is happening nearby. Set up a quick stall for ${product.category} items — perfect for moving stock at discounted prices.',
      },
      {
        'icon': Icons.people,
        'color': AppTheme.donateBlue,
        'title': '🤝 B2B Quick Sale',
        'description':
            'Offer ${product.name} in bulk to nearby restaurants or cafes at wholesale pricing. B2B channels can clear 50+ units in a single transaction.',
      },
    ];
  }
}
