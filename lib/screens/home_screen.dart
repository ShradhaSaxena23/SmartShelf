import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const HomeScreen({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 36),
            const SizedBox(width: 10),
            const Text(
              'SmartShelf',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppTheme.backgroundMint,
              child: Text(
                user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(context, user?.displayName, user?.email),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40.0 : 20.0,
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Welcome Card (Multi-Tenant Isolated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryDarkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, ${user?.displayName ?? 'Business Owner'}! 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tenant Account: ${user?.email ?? ''} (ID: ${user?.uid ?? 'N/A'})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Sign Out',
                          onPressed: () async {
                            await authProvider.signOut();
                            onSignOut();
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Isolated Tenant Data Active',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Metrics Row
              const Text(
                'Shelf Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.5 : 1.3,
                  children: const [
                    _MetricCard(
                      title: 'Total Items',
                      value: '128',
                      subtext: 'In Stock',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primaryGreen,
                    ),
                    _MetricCard(
                      title: 'Expiring Soon',
                      value: '23',
                      subtext: 'Next 7 Days',
                      icon: Icons.timer_outlined,
                      color: AppTheme.warningOrange,
                    ),
                    _MetricCard(
                      title: 'Discounted',
                      value: '12',
                      subtext: 'On Sale',
                      icon: Icons.sell_outlined,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      title: 'Donated',
                      value: '45',
                      subtext: 'This Month',
                      icon: Icons.volunteer_activism_outlined,
                      color: AppTheme.accentGreen,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 28),

              // Action Options section matching app proposition: Track, Sell, Donate
              const Text(
                'Intelligent Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              const _ActionCard(
                title: 'Automated Expiry Alerts',
                description: 'Scan barcodes to track items reaching expiration date automatically.',
                icon: Icons.qr_code_scanner,
                buttonText: 'Scan Product',
              ),
              const SizedBox(height: 12),
              const _ActionCard(
                title: 'Smart Dynamic Discounting',
                description: 'Generate optimal markdown pricing to clear expiring stock rapidly.',
                icon: Icons.auto_graph_sharp,
                buttonText: 'Apply Discounts',
              ),
              const SizedBox(height: 12),
              const _ActionCard(
                title: 'Food Bank & NGO Donation',
                description: 'Donate unsold products seamlessly before expiry and earn tax write-offs.',
                icon: Icons.favorite,
                buttonText: 'Schedule Donation',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String? name, String? email) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            accountName: Text(name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                name?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_outlined),
            title: const Text('Inventory'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Discount Deals'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.volunteer_activism_outlined),
            title: const Text('Donations'),
            onTap: () {},
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed)),
            onTap: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              onSignOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(subtext, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String buttonText;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.backgroundMint,
            radius: 24,
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(110, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
