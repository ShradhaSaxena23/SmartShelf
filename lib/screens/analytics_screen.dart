import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final products = provider.allProducts;

        if (provider.isLoading && products.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          );
        }

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        final analytics = _AnalyticsData(products);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  _buildHeader(isMobile),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // SUMMARY CARDS
                  // ------------------------------------------------

                  _buildSummaryCards(
                    analytics,
                    isMobile,
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // CHARTS
                  // ------------------------------------------------

                  if (isMobile) ...[
                    _buildChartCard(
                      title: 'Products by Category',
                      subtitle:
                          'Number of products in each category',
                      child: _buildCategoryPieChart(
                        analytics,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildChartCard(
                      title: 'Expiry Status',
                      subtitle:
                          'Current status of your inventory',
                      child: _buildExpiryPieChart(
                        analytics,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildChartCard(
                      title: 'Inventory Quantity',
                      subtitle:
                          'Quantity by product category',
                      child: _buildQuantityBarChart(
                        analytics,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildChartCard(
                      title: 'Inventory Value',
                      subtitle:
                          'Total inventory value by category',
                      child: _buildValueBarChart(
                        analytics,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildChartCard(
                      title: 'Upcoming Expiry',
                      subtitle:
                          'Products expiring over the next 30 days',
                      child: _buildExpiryLineChart(
                        analytics,
                      ),
                    ),
                  ] else ...[
                    // ----------------------------------------------
                    // DESKTOP ROW 1
                    // ----------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildChartCard(
                            title:
                                'Products by Category',
                            subtitle:
                                'Number of products in each category',
                            child:
                                _buildCategoryPieChart(
                              analytics,
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _buildChartCard(
                            title: 'Expiry Status',
                            subtitle:
                                'Current status of your inventory',
                            child:
                                _buildExpiryPieChart(
                              analytics,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ----------------------------------------------
                    // DESKTOP ROW 2
                    // ----------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildChartCard(
                            title:
                                'Inventory Quantity',
                            subtitle:
                                'Quantity by product category',
                            child:
                                _buildQuantityBarChart(
                              analytics,
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _buildChartCard(
                            title:
                                'Inventory Value',
                            subtitle:
                                'Total inventory value by category',
                            child:
                                _buildValueBarChart(
                              analytics,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ----------------------------------------------
                    // DESKTOP ROW 3
                    // ----------------------------------------------

                    _buildChartCard(
                      title: 'Upcoming Expiry',
                      subtitle:
                          'Products expiring over the next 30 days',
                      child:
                          _buildExpiryLineChart(
                        analytics,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 44 : 52,
          height: isMobile ? 44 : 52,
          decoration: BoxDecoration(
            color:
                AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.analytics_rounded,
            color: AppTheme.primaryGreen,
            size: isMobile ? 24 : 28,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your inventory performance and insights',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(
    _AnalyticsData analytics,
    bool isMobile,
  ) {
    final cards = [
      _SummaryCardData(
        title: 'Total Products',
        value: analytics.totalProducts.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppTheme.primaryGreen,
      ),
      _SummaryCardData(
        title: 'Total Quantity',
        value: analytics.totalQuantity.toString(),
        icon: Icons.layers_outlined,
        color: Colors.blue,
      ),
      _SummaryCardData(
        title: 'Inventory Value',
        value:
            '₹${analytics.totalInventoryValue.toStringAsFixed(0)}',
        icon: Icons.currency_rupee_rounded,
        color: Colors.orange,
      ),
      _SummaryCardData(
        title: 'Expired',
        value: analytics.expiredCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppTheme.expiredRed,
      ),
      _SummaryCardData(
        title: 'Expiring Soon',
        value:
            analytics.expiringSoonCount.toString(),
        icon: Icons.schedule_rounded,
        color: Colors.deepOrange,
      ),
      _SummaryCardData(
        title: 'Fresh',
        value: analytics.freshCount.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i += 2)
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    i + 2 < cards.length ? 12 : 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      cards[i],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < cards.length
                        ? _buildSummaryCard(
                            cards[i + 1],
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        return _buildSummaryCard(
          cards[index],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    _SummaryCardData data,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  data.color.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  data.value,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY PIE CHART
  // ============================================================

  Widget _buildCategoryPieChart(
    _AnalyticsData analytics,
  ) {
    final categories =
        analytics.categoryCounts;

    if (categories.isEmpty) {
      return _buildNoChartData();
    }

    final entries =
        categories.entries.toList();

    final total =
        entries.fold<int>(
      0,
      (sum, entry) =>
          sum + entry.value,
    );

    final sections =
        <PieChartSectionData>[];

    for (int i = 0;
        i < entries.length;
        i++) {
      final entry = entries[i];

      final percentage =
          total == 0
              ? 0
              : (entry.value / total) * 100;

      sections.add(
        PieChartSectionData(
          value:
              entry.value.toDouble(),
          title:
              '${percentage.toStringAsFixed(0)}%',
          radius: 65,
          titleStyle:
              const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
            color: Colors.white,
          ),
          color:
              _chartColors[i %
                  _chartColors.length],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 45,
              sectionsSpace: 3,
              borderData:
                  FlBorderData(
                show: false,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment:
              WrapAlignment.center,
          children: [
            for (int i = 0;
                i < entries.length;
                i++)
              _buildLegendItem(
                entries[i].key,
                entries[i].value
                    .toString(),
                _chartColors[
                    i %
                        _chartColors
                            .length],
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // EXPIRY PIE CHART
  // ============================================================

  Widget _buildExpiryPieChart(
    _AnalyticsData analytics,
  ) {
    final sections = [
      PieChartSectionData(
        value:
            analytics.freshCount.toDouble(),
        title: analytics.freshCount == 0
            ? ''
            : '${analytics.freshCount}',
        radius: 65,
        color: Colors.green,
        titleStyle:
            const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        value: analytics.expiringSoonCount
            .toDouble(),
        title:
            analytics.expiringSoonCount ==
                    0
                ? ''
                : '${analytics.expiringSoonCount}',
        radius: 65,
        color: Colors.orange,
        titleStyle:
            const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
      PieChartSectionData(
        value:
            analytics.expiredCount
                .toDouble(),
        title:
            analytics.expiredCount == 0
                ? ''
                : '${analytics.expiredCount}',
        radius: 65,
        color: AppTheme.expiredRed,
        titleStyle:
            const TextStyle(
          color: Colors.white,
          fontWeight:
              FontWeight.bold,
          fontSize: 12,
        ),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 45,
              sectionsSpace: 3,
              borderData:
                  FlBorderData(
                show: false,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 20,
          runSpacing: 10,
          alignment:
              WrapAlignment.center,
          children: [
            _buildLegendItem(
              'Fresh',
              analytics.freshCount
                  .toString(),
              Colors.green,
            ),
            _buildLegendItem(
              'Expiring Soon',
              analytics.expiringSoonCount
                  .toString(),
              Colors.orange,
            ),
            _buildLegendItem(
              'Expired',
              analytics.expiredCount
                  .toString(),
              AppTheme.expiredRed,
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUANTITY BAR CHART
  // ============================================================

  Widget _buildQuantityBarChart(
    _AnalyticsData analytics,
  ) {
    final categories =
        analytics.categoryQuantities;

    if (categories.isEmpty) {
      return _buildNoChartData();
    }

    final entries =
        categories.entries.toList();

    final maxValue = entries
        .map((e) => e.value)
        .fold<int>(
          0,
          (max, value) =>
              value > max ? value : max,
        );

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxValue == 0
              ? 10
              : maxValue * 1.2,
          minY: 0,

          alignment:
              BarChartAlignment.spaceAround,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                _calculateInterval(
              maxValue,
            ),
          ),

          borderData:
              FlBorderData(
            show: false,
          ),

          titlesData:
              FlTitlesData(
            topTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            rightTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            leftTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval:
                    _calculateInterval(
                  maxValue,
                ),
                getTitlesWidget:
                    (value, meta) {
                  return Text(
                    value
                        .toInt()
                        .toString(),
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          AppTheme.textMuted,
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget:
                    (value, meta) {
                  final index =
                      value.toInt();

                  if (index < 0 ||
                      index >=
                          entries.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 8,
                    ),
                    child: Text(
                      _shortenText(
                        entries[index]
                            .key,
                        10,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            AppTheme
                                .textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: [
            for (int i = 0;
                i < entries.length;
                i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY:
                        entries[i]
                            .value
                            .toDouble(),
                    width: 25,
                    borderRadius:
                        const BorderRadius
                            .vertical(
                      top:
                          Radius.circular(
                        6,
                      ),
                    ),
                    color:
                        _chartColors[
                            i %
                                _chartColors
                                    .length],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VALUE BAR CHART
  // ============================================================

  Widget _buildValueBarChart(
    _AnalyticsData analytics,
  ) {
    final categories =
        analytics.categoryValues;

    if (categories.isEmpty) {
      return _buildNoChartData();
    }

    final entries =
        categories.entries.toList();

    final maxValue = entries
        .map((e) => e.value)
        .fold<double>(
          0,
          (max, value) =>
              value > max ? value : max,
        );

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxValue == 0
              ? 100
              : maxValue * 1.2,

          minY: 0,

          alignment:
              BarChartAlignment.spaceAround,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),

          borderData:
              FlBorderData(
            show: false,
          ),

          titlesData:
              FlTitlesData(
            topTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            rightTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            leftTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget:
                    (value, meta) {
                  return Text(
                    '₹${_formatCompactNumber(value)}',
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          AppTheme.textMuted,
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget:
                    (value, meta) {
                  final index =
                      value.toInt();

                  if (index < 0 ||
                      index >=
                          entries.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 8,
                    ),
                    child: Text(
                      _shortenText(
                        entries[index]
                            .key,
                        10,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color:
                            AppTheme
                                .textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          barGroups: [
            for (int i = 0;
                i < entries.length;
                i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY:
                        entries[i]
                            .value,
                    width: 25,
                    borderRadius:
                        const BorderRadius
                            .vertical(
                      top:
                          Radius.circular(
                        6,
                      ),
                    ),
                    color:
                        _chartColors[
                            i %
                                _chartColors
                                    .length],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXPIRY LINE CHART
  // ============================================================

  Widget _buildExpiryLineChart(
    _AnalyticsData analytics,
  ) {
    final data =
        analytics.expiryTimeline;

    final maxValue = data.values.fold<int>(
      0,
      (max, value) =>
          value > max ? value : max,
    );

    final spots = <FlSpot>[];

    for (int i = 0;
        i < data.length;
        i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          data.values.elementAt(i)
              .toDouble(),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          minY: 0,

          maxY: maxValue == 0
              ? 5
              : maxValue + 2,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),

          borderData:
              FlBorderData(
            show: false,
          ),

          titlesData:
              FlTitlesData(
            topTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            rightTitles:
                const AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: false,
              ),
            ),

            leftTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget:
                    (value, meta) {
                  return Text(
                    value
                        .toInt()
                        .toString(),
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          AppTheme.textMuted,
                    ),
                  );
                },
              ),
            ),

            bottomTitles:
                AxisTitles(
              sideTitles:
                  SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval:
                    data.length > 10
                        ? 5
                        : 1,
                getTitlesWidget:
                    (value, meta) {
                  final index =
                      value.toInt();

                  if (index < 0 ||
                      index >=
                          data.length) {
                    return const SizedBox();
                  }

                  final date =
                      data.keys.elementAt(
                    index,
                  );

                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top: 8,
                    ),
                    child: Text(
                      '${date.day}/${date.month}',
                      style:
                          const TextStyle(
                        fontSize: 9,
                        color:
                            AppTheme
                                .textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          lineTouchData:
              LineTouchData(
            enabled: true,
            touchTooltipData:
                LineTouchTooltipData(
              getTooltipItems:
                  (spots) {
                return spots.map(
                  (spot) {
                    final index =
                        spot.x.toInt();

                    if (index < 0 ||
                        index >=
                            data.length) {
                      return null;
                    }

                    final date =
                        data.keys.elementAt(
                      index,
                    );

                    return LineTooltipItem(
                      '${date.day}/${date.month}\n'
                      '${spot.y.toInt()} product(s)',
                      const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData:
                  FlDotData(
                show: true,
              ),
              belowBarData:
                  BarAreaData(
                show: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegendItem(
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 6),

        Text(
          '$label ($value)',
          style: const TextStyle(
            fontSize: 11,
            color:
                AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY CHART
  // ============================================================

  Widget _buildNoChartData() {
    return SizedBox(
      height: 230,
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: AppTheme.textMuted
                  .withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'No data available',
              style: TextStyle(
                color:
                    AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 44,
                color:
                    AppTheme.primaryGreen,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Analytics Data',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add some products to your inventory to see analytics and charts here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _calculateInterval(
    int maxValue,
  ) {
    if (maxValue <= 10) return 2;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    if (maxValue <= 500) return 100;
    return (maxValue / 5).ceilToDouble();
  }

  String _shortenText(
    String text,
    int maxLength,
  ) {
    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength - 2)}..';
  }

  String _formatCompactNumber(
    double value,
  ) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toInt().toString();
  }
}

// ================================================================
// ANALYTICS DATA MODEL
// ================================================================

class _AnalyticsData {
  final List<ProductModel> products;

  _AnalyticsData(this.products);

  // ------------------------------------------------------------
  // BASIC TOTALS
  // ------------------------------------------------------------

  int get totalProducts {
    return products.length;
  }

  int get totalQuantity {
    return products.fold<int>(
      0,
      (sum, product) =>
          sum + product.quantity,
    );
  }

  double get totalInventoryValue {
    return products.fold<double>(
      0,
      (sum, product) =>
          sum +
          (product.originalPrice *
              product.quantity),
    );
  }

  // ------------------------------------------------------------
  // EXPIRY STATUS
  // ------------------------------------------------------------

  int get expiredCount {
    return products
        .where(
          (product) =>
              product.isExpired,
        )
        .length;
  }

  int get expiringSoonCount {
    return products
        .where(
          (product) =>
              !product.isExpired &&
              product.isExpiringSoon,
        )
        .length;
  }

  int get freshCount {
    return products
        .where(
          (product) =>
              !product.isExpired &&
              !product.isExpiringSoon,
        )
        .length;
  }

  // ------------------------------------------------------------
  // CATEGORY PRODUCT COUNT
  // ------------------------------------------------------------

  Map<String, int> get categoryCounts {
    final result =
        <String, int>{};

    for (final product in products) {
      final category =
          product.category.trim().isEmpty
              ? 'Other'
              : product.category.trim();

      result[category] =
          (result[category] ?? 0) + 1;
    }

    return _sortDescending(result);
  }

  // ------------------------------------------------------------
  // CATEGORY QUANTITY
  // ------------------------------------------------------------

  Map<String, int>
      get categoryQuantities {
    final result =
        <String, int>{};

    for (final product in products) {
      final category =
          product.category.trim().isEmpty
              ? 'Other'
              : product.category.trim();

      result[category] =
          (result[category] ?? 0) +
              product.quantity;
    }

    return _sortDescending(result);
  }

  // ------------------------------------------------------------
  // CATEGORY VALUE
  // ------------------------------------------------------------

  Map<String, double>
      get categoryValues {
    final result =
        <String, double>{};

    for (final product in products) {
      final category =
          product.category.trim().isEmpty
              ? 'Other'
              : product.category.trim();

      final value =
          product.originalPrice *
              product.quantity;

      result[category] =
          (result[category] ?? 0) +
              value;
    }

    final entries =
        result.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(
              a.value,
            ),
          );

    return Map.fromEntries(entries);
  }

  // ------------------------------------------------------------
  // EXPIRY TIMELINE
  // ------------------------------------------------------------

  Map<DateTime, int>
      get expiryTimeline {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final result =
        <DateTime, int>{};

    // Create 30 days of data.
    for (int i = 0; i <= 30; i++) {
      final date =
          today.add(
        Duration(days: i),
      );

      result[date] = 0;
    }

    for (final product in products) {
      final expiry = DateTime(
        product.expiryDate.year,
        product.expiryDate.month,
        product.expiryDate.day,
      );

      final difference =
          expiry.difference(today).inDays;

      if (difference >= 0 &&
          difference <= 30) {
        result[expiry] =
            (result[expiry] ?? 0) + 1;
      }
    }

    return result;
  }

  // ------------------------------------------------------------
  // SORT MAP BY VALUE
  // ------------------------------------------------------------

  Map<String, T> _sortDescending<T extends num>(
    Map<String, T> input,
  ) {
    final entries =
        input.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(
              a.value,
            ),
          );

    return Map.fromEntries(entries);
  }
}

// ================================================================
// SUMMARY CARD DATA
// ================================================================

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// ================================================================
// CHART COLORS
// ================================================================

const List<Color> _chartColors = [
  AppTheme.primaryGreen,
  Colors.blue,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.amber,
  Colors.cyan,
  Colors.brown,
];