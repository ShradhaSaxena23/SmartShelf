import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final VoidCallback onSignUpSuccess;

  const SignUpScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onSignUpSuccess,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the Terms of Service & Privacy Policy')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        widget.onSignUpSuccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDesktop ? Colors.white : AppTheme.backgroundMint,
      body: SafeArea(
        child: isDesktop ? _buildWebSignUpLayout(context) : _buildMobileSignUpLayout(context),
      ),
    );
  }

  Widget _buildMobileSignUpLayout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 22),
                  onPressed: widget.onNavigateToLogin,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Image.asset('assets/images/logo.png', height: 42),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join SmartShelf to manage inventory smarter',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),

            if (authProvider.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(authProvider.errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            const Text('Full Name / Business Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.business_outlined, size: 20, color: AppTheme.textMuted),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 18),

            const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.textMuted),
              ),
              validator: (val) => (val == null || !val.contains('@')) ? 'Please enter valid email' : null,
            ),
            const SizedBox(height: 18),

            const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppTheme.textMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppTheme.textMuted),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) => (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 18),

            const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                hintText: 'Confirm your password',
                prefixIcon: Icon(Icons.lock_reset_outlined, size: 20, color: AppTheme.textMuted),
              ),
              validator: (val) => (val != _passwordController.text) ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeToTerms,
                    activeColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 28),

            authProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: AppTheme.textSecondary)),
                GestureDetector(
                  onTap: widget.onNavigateToLogin,
                  child: const Text('Sign In', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebSignUpLayout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 38),
                  const SizedBox(width: 10),
                  const Text(
                    'SmartShelf',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Already registered? ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  OutlinedButton(
                    onPressed: widget.onNavigateToLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                      minimumSize: const Size(90, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sign in', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 6),
                      const Text('Get started with SmartShelf inventory management', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 28),

                      if (authProvider.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(authProvider.errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text('Full Name / Business Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your business name',
                          prefixIcon: Icon(Icons.business_outlined, size: 20),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (val) => (val == null || !val.contains('@')) ? 'Please enter valid email' : null,
                      ),
                      const SizedBox(height: 16),

                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) => (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(text: 'Terms of Service', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                  TextSpan(text: ' and '),
                                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                          : ElevatedButton(
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
