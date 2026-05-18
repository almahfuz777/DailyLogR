// lib/widgets/auth_sheet.dart
import 'package:dailylogr/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showAuthSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _AuthSheetContent(),
  );
}

class _AuthSheetContent extends StatefulWidget {
  const _AuthSheetContent();

  @override
  State<_AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<_AuthSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isEmailLoading = true;
      _errorMessage = null; // Clear previous error
    });

    try {
      if (_isLogin) {
        await FirebaseAuthService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await FirebaseAuthService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context); // Close sheet on success
      
      // Success snackbar is fine here because the sheet is now closed!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin ? 'Successfully logged in.' : 'Account created.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String msg = e.message ?? 'Authentication failed';
      
      // Handle specific edge cases to improve UX
      if (e.code == 'email-already-in-use' && !_isLogin) {
        msg = 'An account already exists for this email. Please sign in instead.';
        setState(() => _isLogin = true);
      } else if (e.code == 'user-not-found' && _isLogin) {
        msg = 'No account found for this email. Please sign up instead.';
        setState(() => _isLogin = false);
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
         msg = 'Incorrect email or password.';
      } else if (e.code == 'weak-password') {
         msg = 'The password provided is too weak.';
      }

      setState(() => _errorMessage = msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pop(context); // Close sheet on success
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed in with Google.')),
      );
    } catch (e) {
      if (!mounted) return;
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') || errorStr.contains('aborted')) {
        return; // Silently ignore cancellation
      }
      
      setState(() => _errorMessage = 'Google Sign-In failed: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We add padding for the keyboard
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final color = Theme.of(context).colorScheme;
    final isAnyLoading = _isEmailLoading || _isGoogleLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + keyboardSpace,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text(
              _isLogin ? 'Welcome Back' : 'Create Account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _isLogin
                  ? 'Sign in to securely sync your journal across devices.'
                  : 'Sign up to securely backup your entries across devices.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: color.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: color.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: color.outlineVariant,
                  ),
                ),
                filled: true,
                fillColor: color.surfaceContainerHighest.withOpacity(0.3),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: color.outlineVariant,
                  ),
                ),
                filled: true,
                fillColor: color.surfaceContainerHighest.withOpacity(0.3),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isAnyLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isEmailLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isLogin ? 'Sign In' : 'Sign Up'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: isAnyLoading
                  ? null
                  : () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? 'Don\'t have an account? Sign Up'
                    : 'Already have an account? Sign In',
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isAnyLoading ? null : _submitGoogle,
              icon: _isGoogleLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.asset(
                      'assets/icons/google_logo.svg',
                      height: 24,
                      width: 24,
                    ), 
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
      ), 
    );
  }
}
