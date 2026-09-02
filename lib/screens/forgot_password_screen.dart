import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const ForgotPasswordScreen({super.key, required this.onBackToLogin});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendPasswordResetEmail(_emailController.text);
      if (success && mounted) {
        setState(() => _submitted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _submitted ? _buildSuccessView() : _buildFormView(authProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: widget.onBackToLogin,
          ),
          const SizedBox(height: 12),
          Center(child: Image.asset('assets/images/logo.png', height: 75)),
          const SizedBox(height: 24),
          const Text(
            'Forgot Password?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter your registered email address and we'll send you instructions to reset your password.",
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 28),

          if (authProvider.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(authProvider.errorMessage!, style: const TextStyle(color: AppTheme.errorRed)),
            ),
            const SizedBox(height: 16),
          ],

          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'name@business.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) => (val == null || !val.contains('@')) ? 'Please enter a valid email address' : null,
          ),
          const SizedBox(height: 24),

          authProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
              : ElevatedButton(
                  onPressed: _handleReset,
                  child: const Text('Send Reset Link'),
                ),
          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: widget.onBackToLogin,
              child: const Text('Back to Login', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.mark_email_read_outlined, size: 40, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 24),
        const Text(
          'Reset Link Sent!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: widget.onBackToLogin,
          child: const Text('Return to Sign In'),
        ),
      ],
    );
  }
}
