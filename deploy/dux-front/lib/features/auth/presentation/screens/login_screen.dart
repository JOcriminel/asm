import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dux_front/core/theme/app_sizes.dart';
import 'package:dux_front/core/widgets/primary_button.dart';
import 'package:dux_front/core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authControllerProvider.notifier).login(
            _usernameController.text,
            _passwordController.text,
            _rememberMe,
          );
      if (!mounted) return;
      if (!success) {
        final authState = ref.read(authControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage ?? 'Authentication failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    // Responsive design widths
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SizedBox(
              width: isDesktop ? 420 : double.infinity,
              child: Card(
                elevation: isDesktop ? 4 : 0,
                color: isDesktop ? theme.cardTheme.color : Colors.transparent,
                shape: isDesktop ? null : const RoundedRectangleBorder(side: BorderSide.none),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? AppSpacing.xxl : 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                              AppSpacing.gapL,
                              Text(
                                'Welcome to AW-Dux',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.gapS,
                              Text(
                                'Sign in to access your dashboard',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapXxl,

                        if (authState.errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.1),
                              borderRadius: AppBorderRadius.roundedM,
                              border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: theme.colorScheme.error),
                                AppSpacing.gapM,
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.gapL,
                        ],

                        // Username Field
                        AppTextField(
                          controller: _usernameController,
                          labelText: 'Username or Email',
                          hintText: 'Enter your username',
                          prefixIcon: Icons.person_outline,
                          enabled: !authState.isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapL,

                        // Password Field
                        AppTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          enabled: !authState.isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        AppSpacing.gapM,

                        // Remember Me row
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: authState.isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                              activeColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Remember me',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapL,

                        // Login Button
                        PrimaryButton(
                          text: 'Sign In',
                          isLoading: authState.isLoading,
                          onPressed: _onLoginPressed,
                        ),
                      ],
                    ),
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
