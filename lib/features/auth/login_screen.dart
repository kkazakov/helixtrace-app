import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:helixtrace/core/constants/app_constants.dart';
import 'package:helixtrace/core/storage/storage_service.dart';
import 'package:helixtrace/core/utils/validators.dart';
import 'package:helixtrace/core/widgets/sleek_button.dart';
import 'package:helixtrace/core/widgets/sleek_text_field.dart';
import 'package:helixtrace/features/auth/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _obscurePassword = true;
  bool _apiUrlSet = false;

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    _apiUrlSet = storage.getApiKey() != null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider.notifier);
    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted && ref.read(authProvider).user != null) {
      context.go(AppConstants.routeHome);
    }
  }

  void _showApiUrlDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final storage = StorageService();
    final currentUrl = storage.getApiKey() ?? '';
    controller.text = currentUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Set API URL',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              validator: Validators.urlValidator,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://trace-api.meshcore.bg/',
                prefixIcon: Icon(Icons.link_outlined, size: 20),
              ),
              keyboardType: TextInputType.url,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  storage.setApiKey(controller.text.trim());
                  setState(() {
                    _apiUrlSet = true;
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API URL saved successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF0B1120),
                    const Color(0xFF0F172A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFEFF3FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _showApiUrlDialog,
                      icon: const Icon(Icons.link_outlined),
                      tooltip: 'Set API URL',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                      icon: Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      tooltip: 'Toggle theme',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    bottom: bottomPadding + 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.gps_fixed_outlined,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'HelixTrace',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map the invisible network',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SleekTextField(
                              label: 'Email',
                              hintText: 'Enter your email',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              validator: Validators.emailValidator,
                              obsecureTextState: false,
                              enabled: _apiUrlSet,
                            ),
                            SleekTextField(
                              label: 'Password',
                              hintText: 'Enter your password',
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              validator: Validators.passwordValidator,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              obsecureTextState: _obscurePassword,
                              enabled: _apiUrlSet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SleekButton(
                        text: 'Login',
                        onPressed: _apiUrlSet ? _handleLogin : null,
                        isLoading: authState.isLoading,
                      ),
                      if (!_apiUrlSet)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            'Set the API URL (top-right) to enable login',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (!authState.isLoading && authState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              authState.error!,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_apiUrlSet) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(AppConstants.routeRegister),
                              child: const Text('Register'),
                            ),
                          ],
                        ),
                      ],
                    ],
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