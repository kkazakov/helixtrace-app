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
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Set API URL',
            style: TextStyle(fontWeight: FontWeight.w600),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.dark
                ? [
                    const Color(0xFF0A0A12),
                    const Color(0xFF12121F),
                    const Color(0xFF0A0A12),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFEEEEF5),
                    const Color(0xFFF8F9FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        const Color(0xFF00D9FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.gps_fixed_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'HelixTrace',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    background: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          const Color(0xFF00D9FF),
                        ],
                      ).createShader(
                        const Rect.fromLTWH(0, 0, 200, 60),
                      ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Map the invisible network',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SleekTextField(
                        label: 'Email',
                        hintText: 'Enter your email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        validator: Validators.emailValidator,
                        obsecureTextState: false,
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
                      ),
                    ],
                  ),
                ),
                SleekButton(
                  text: 'Login',
                  onPressed: _apiUrlSet ? _handleLogin : null,
                  isLoading: authState.isLoading,
                ),
                if (!authState.isLoading && authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                SleekButton(
                  text: 'Set API URL',
                  onPressed: _showApiUrlDialog,
                  isOutlined: true,
                ),
                if (!_apiUrlSet)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Please set the API URL to enable login',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push(AppConstants.routeRegister),
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
