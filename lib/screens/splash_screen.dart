import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const SplashScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/logo.png',
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'FreshTrack',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track. Save. Sell. Donate.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Reduce waste. Increase value.\nCreate impact.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _FeaturePill(icon: Icons.timer_outlined, label: 'Track Expiry'),
                      _FeaturePill(icon: Icons.sell_outlined, label: 'Smart Price'),
                      _FeaturePill(icon: Icons.volunteer_activism_outlined, label: 'Donate'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: onGetStarted,
            child: const Text('Get Started'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 60),
                    const SizedBox(width: 16),
                    const Text(
                      'FreshTrack',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Track. Save. Sell. Donate.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Smart inventory management to reduce\nfood waste and build a better tomorrow.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: const [
                    _DesktopValueCard(
                      icon: Icons.timer_sharp,
                      title: 'Track Expiry',
                      desc: 'Stay on top of expiry dates',
                    ),
                    _DesktopValueCard(
                      icon: Icons.auto_graph_rounded,
                      title: 'Smart Pricing',
                      desc: 'Suggested prices to sell faster',
                    ),
                    _DesktopValueCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Reduce Waste',
                      desc: 'Minimize waste and increase profits',
                    ),
                    _DesktopValueCard(
                      icon: Icons.favorite_outline,
                      title: 'Give Back',
                      desc: 'Donate and create a positive impact',
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 260,
                  child: ElevatedButton(
                    onPressed: onGetStarted,
                    child: const Text('Go to Login'),
                  ),
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFFE8F3ED),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset('assets/images/logo.png', height: 350, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.backgroundMint,
          radius: 22,
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _DesktopValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _DesktopValueCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
