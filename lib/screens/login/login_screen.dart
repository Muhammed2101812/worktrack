import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/dimens.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';

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
      if (mounted) CustomToast.show(context, friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.signInWithGoogle();
      if (mounted) {
        await ref.read(syncProvider.notifier).fullSync();
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) CustomToast.show(context, friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomToast.show(context, 'Lütfen önce e-posta adresinizi girin');
      return;
    }
    try {
      await AuthService().resetPassword(email);
      if (mounted) {
        CustomToast.show(context, 'Şifre sıfırlama bağlantısı e-postanıza gönderildi');
      }
    } catch (e) {
      if (mounted) CustomToast.show(context, friendlyAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.s24, vertical: Spacing.s32),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Icon(
                  Icons.work_history_rounded,
                  size: 36,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'WorkTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: c.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Çalışma kayıtların tek yerde',
                style: TextStyle(
                  fontSize: 15,
                  color: c.textMuted,
                ),
              ),
              const SizedBox(height: 48),
              MidnightInput(
                controller: _emailController,
                hintText: 'E-posta',
                prefixIcon: Icon(PhosphorIcons.envelope(), color: c.textMuted, size: 20),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              MidnightInput(
                controller: _passwordController,
                hintText: 'Şifre',
                prefixIcon: Icon(PhosphorIcons.lock(), color: c.textMuted, size: 20),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _loading ? null : _resetPassword,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Text(
                      'Şifremi unuttum?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                variant: ButtonVariant.solid,
                onPressed: _loading ? null : _submit,
                width: double.infinity,
                height: 50,
                child: _loading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary),
                      )
                    : Text(
                        _isSignUp ? 'KAYIT OL' : 'GİRİŞ YAP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: c.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: c.cardBorder.withValues(alpha: 0.5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('veya', style: TextStyle(color: c.textMuted, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: c.cardBorder.withValues(alpha: 0.5))),
                ],
              ),
              const SizedBox(height: 16),
              AppButton(
                variant: ButtonVariant.outline,
                onPressed: _loading ? null : _signInWithGoogle,
                width: double.infinity,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 20,
                      width: 20,
                    ),
                    const SizedBox(width: Spacing.s12),
                    Text(
                      'Google ile Giriş Yap',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Giriş Yapmadan Devam Et',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
