import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/app_components.dart';
import '../services/api_client.dart';
import '../theme/app_tokens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.token});

  final String? token;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  InvitationRecord? _invitation;
  String? _error;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'This invitation link is missing its token.';
        _isLoading = false;
      });
      return;
    }
    try {
      final invitation = await ApiClient.instance.validateInvitation(token);
      if (!mounted) return;
      setState(() {
        _invitation = invitation;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This invitation link is invalid or has expired.';
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false) ||
        _invitation == null ||
        widget.token == null) {
      return;
    }
    final auth = Firebase.apps.isEmpty ? null : FirebaseAuth.instance;
    if (auth == null) {
      _showMessage('Firebase is not configured for registration.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: _invitation!.email,
        password: _passwordController.text,
      );
      final idToken = await credential.user?.getIdToken(true);
      if (idToken == null) {
        throw const FormatException('Firebase did not return an ID token.');
      }
      await ApiClient.instance.registerFromInvitation(
        token: widget.token!,
        idToken: idToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      await ApiClient.instance.createBackendSession(idToken);
      if (mounted) context.go('/projects');
    } on FirebaseAuthException catch (error) {
      _showMessage(_formatFirebaseError(error));
    } catch (_) {
      _showMessage('Registration could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this invitation email.';
      case 'weak-password':
        return 'Choose a stronger password.';
      default:
        return error.message ?? 'Registration failed.';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ErrorState(message: _error!)
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Create your workspace account',
                                    style: theme.textTheme.headlineSmall),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'You were invited as ${_invitation!.role}.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(_invitation!.email,
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        decoration: const InputDecoration(
                                            labelText: 'First name'),
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        decoration: const InputDecoration(
                                            labelText: 'Last name'),
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.length < 6
                                          ? 'Use at least 6 characters'
                                          : null,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                AppButton(
                                  label: 'Create account',
                                  onPressed: _isSubmitting ? null : _register,
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.link_off_outlined, size: 48),
        const SizedBox(height: AppSpacing.md),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
