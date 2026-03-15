import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      CustomToast.show(context, 'Lütfen tüm alanları doldurun');
      return;
    }

    setState(() => _loading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      if (_isSignUp) {
        await notifier.signUp(_emailController.text.trim(), _passwordController.text);
      } else {
        await notifier.signIn(_emailController.text.trim(), _passwordController.text);
      }
      if (mounted) {
        await ref.read(syncProvider.notifier).fullSync();
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) CustomToast.show(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.work_history_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'WorkTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Çalışma kayıtların tek yerde',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 48),
              MidnightInput(
                controller: _emailController,
                hintText: 'E-posta',
                prefixIcon: Icon(PhosphorIcons.envelope(), color: AppColors.textMuted, size: 20),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              MidnightInput(
                controller: _passwordController,
                hintText: 'Şifre',
                prefixIcon: Icon(PhosphorIcons.lock(), color: AppColors.textMuted, size: 20),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              MidnightButton(
                onPressed: _loading ? null : _submit,
                width: double.infinity,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isSignUp ? 'KAYIT OL' : 'GİRİŞ YAP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _isSignUp = !_isSignUp),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _isSignUp
                        ? 'Zaten hesabın var mı? Giriş yap'
                        : 'Henüz hesabın yok mu? Kayıt ol',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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
