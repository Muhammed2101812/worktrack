import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/payments_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/client.dart';
import '../../core/constants.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';
import '../../services/iap_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentUser = ref.watch(authNotifierProvider);
    final syncAsync = ref.watch(syncProvider);
    final unsyncedEntriesAsync = ref.watch(unsyncedEntriesProvider);
    final unsyncedPaymentsAsync = ref.watch(unsyncedPaymentsProvider);
    final syncEnabled = ref.watch(syncEnabledProvider).valueOrNull ?? true;
    final isWide = MediaQuery.of(context).size.width >= 768;

    Widget content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: isWide ? 40 : 100),
            children: [
              _buildPremiumSection(context),
              _buildThemeSection(context),
              _buildDataSyncSection(context, syncAsync, unsyncedEntriesAsync, unsyncedPaymentsAsync, syncEnabled, currentUser),
              _buildAccountSection(context, currentUser),
              _buildFinanceSection(context),
              _buildAboutSection(context),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }

  // ── PREMIUM ──────────────────────────────────────────────────────────────
  Widget _buildPremiumSection(BuildContext context) {
    final c = AppColors.of(context);
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;

    if (isPremium) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: MidnightCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.emerald.withValues(alpha: 0.3)),
                ),
                child: Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill), color: c.emerald, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Premium Aktif',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: c.textMain)),
                    const SizedBox(height: 2),
                    Text('Reklamlar kaldırıldı. Teşekkürler!',
                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: MidnightCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(PhosphorIcons.crown(), color: c.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reklamları Kaldır',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17, color: c.textMain)),
                      const SizedBox(height: 2),
                      Text('Tek seferlik ödeme ile reklamsız kullanım',
                          style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle, color: c.emerald, size: 16),
                const SizedBox(width: 8),
                Text('Tüm reklamlar kaldırılır', style: TextStyle(fontSize: 13, color: c.textMain)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: c.emerald, size: 16),
                const SizedBox(width: 8),
                Text('Tüm cihazlarda geçerli', style: TextStyle(fontSize: 13, color: c.textMain)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: c.emerald, size: 16),
                const SizedBox(width: 8),
                Text('Ömür boyu (tek seferlik)', style: TextStyle(fontSize: 13, color: c.textMain)),
              ],
            ),
            const SizedBox(height: 20),
            MidnightButton(
              onPressed: () => _showPaywallDialog(context),
              width: double.infinity,
              child: Text('ŞİMDİ YÜKSELTT',
                  style: TextStyle(fontWeight: FontWeight.bold, color: c.onPrimary)),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(iapServiceProvider).restorePurchases();
                    if (context.mounted) {
                      CustomToast.show(context, 'Satın almalar geri yüklendi');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CustomToast.show(context, 'Geri yükleme başarısız: $e');
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Satın almayı geri yükle',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textMuted,
                          decoration: TextDecoration.underline)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaywallDialog(BuildContext context) async {
    final iap = ref.read(iapServiceProvider);
    final product = iap.removeAdsProduct;
    final price = product?.price ?? 'Fiyat bilgisi yükleniyor...';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.navBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dc.cardBorder, width: 1),
          ),
          title: Row(
            children: [
              Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill), color: dc.primary),
              const SizedBox(width: 10),
              Text('Premium\'a Yükselt', style: TextStyle(color: dc.textMain)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tüm reklamları kalıcı olarak kaldır.',
                  style: TextStyle(color: dc.textMuted)),
              const SizedBox(height: 16),
              Text(price,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: dc.primary)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Vazgeç', style: TextStyle(color: dc.textMuted)),
            ),
            MidnightButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Satın Al',
                  style: TextStyle(fontWeight: FontWeight.bold, color: dc.onPrimary)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    CustomToast.show(context, 'Satın alma başlatılıyor...');
    final result = await iap.buyRemoveAds();
    if (!mounted) return;
    switch (result) {
      case IapResult.success:
        CustomToast.show(context, 'Premium etkinleştirildi! Reklamlar kaldırıldı.');
        break;
      case IapResult.cancelled:
        // User cancelled — no toast needed.
        break;
      case IapResult.error:
        CustomToast.show(context, 'Satın alma başarısız. Tekrar deneyin.');
        break;
      case IapResult.notAvailable:
        CustomToast.show(context, 'Mağaza kullanılamıyor (yalnızca mobil cihazlarda).');
        break;
    }
  }

  // ── GÖRÜNÜM (Tema) ──────────────────────────────────────────────────────
  Widget _buildThemeSection(BuildContext context) {
    final c = AppColors.of(context);
    final themeMode = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'GÖRÜNÜM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: c.textMuted,
            ),
          ),
        ),
        MidnightCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(PhosphorIcons.palette(), color: c.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Tema',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    Expanded(child: _buildThemeOption(context, 'Sistem', ThemeMode.system, PhosphorIcons.monitor(), themeMode)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildThemeOption(context, 'Açık', ThemeMode.light, PhosphorIcons.sun(), themeMode)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildThemeOption(context, 'Koyu', ThemeMode.dark, PhosphorIcons.moon(), themeMode)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, ThemeMode mode, IconData icon, ThemeMode current) {
    final c = AppColors.of(context);
    final isSelected = mode == current;
    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withValues(alpha: 0.12) : c.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? c.primary : c.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? c.primary : c.textMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? c.primary : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSyncSection(
    BuildContext context,
    AsyncValue syncAsync,
    AsyncValue unsyncedEntriesAsync,
    AsyncValue unsyncedPaymentsAsync,
    bool syncEnabled,
    dynamic currentUser,
  ) {
    final c = AppColors.of(context);
    final isLoggedIn = currentUser != null;
    final unsyncedCount = (unsyncedEntriesAsync.valueOrNull?.length ?? 0) +
        (unsyncedPaymentsAsync.valueOrNull?.length ?? 0);
    final isSyncing = syncAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'VERİ & SENKRONİZASYON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: c.textMuted,
            ),
          ),
        ),
        MidnightCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.cloudArrowUp(),
                title: 'Bulut Senkronizasyonu',
                iconColor: c.primary,
                hasToggle: true,
                toggleValue: isLoggedIn && syncEnabled,
                onTap: () {
                  if (!isLoggedIn) {
                    CustomToast.show(context, 'Bulut senkronizasyonu için lütfen giriş yapın.');
                  } else {
                    ref.read(syncEnabledProvider.notifier).toggle();
                  }
                },
              ),
              _divider(),
              if (isSyncing)
                _buildSettingsItem(
                  context: context,
                  icon: PhosphorIcons.spinner(),
                  title: 'Senkronize ediliyor...',
                  iconColor: c.primary,
                  onTap: null,
                  trailingIcon: null,
                )
              else if (unsyncedCount > 0)
                _buildSettingsItem(
                  context: context,
                  icon: PhosphorIcons.arrowsClockwise(),
                  title: '$unsyncedCount kayıt senkronize edilmedi',
                  iconColor: c.orange,
                  onTap: !isLoggedIn
                      ? null
                      : () async {
                          try {
                            await ref.read(syncProvider.notifier).fullSync();
                            if (context.mounted) {
                              CustomToast.show(context, 'Senkronizasyon tamamlandı');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CustomToast.show(context, 'Senkronizasyon başarısız: $e');
                            }
                          }
                        },
                  trailingIcon: PhosphorIcons.caretRight(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.emerald.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.cloudCheck(), color: c.emerald, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Senkronize',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: c.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Tüm veriler senkronize',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              _divider(),
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.fileXls(),
                title: 'Verileri Dışa Aktar (Excel)',
                iconColor: c.emerald,
                onTap: () async {
                  final entriesVal = ref.read(entriesProvider);
                  final clientsVal = ref.read(clientsProvider);
                  if (entriesVal.value != null && clientsVal.value != null) {
                    try {
                      await ExportService.exportToExcel(
                        entriesVal.value!,
                        clientsVal.value!,
                      );
                      if (context.mounted) {
                        CustomToast.show(context, 'Excel dosyası hazır');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CustomToast.show(context, 'Dışa aktarma sırasında bir hata oluştu.');
                      }
                    }
                  } else {
                    if (context.mounted) {
                      CustomToast.show(context, 'Henüz veriler hazır değil.');
                    }
                  }
                },
                trailingIcon: PhosphorIcons.downloadSimple(),
              ),
              _divider(),
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.uploadSimple(),
                title: 'Verileri İçe Aktar (Excel)',
                iconColor: c.orange,
                onTap: () => _showImportModal(context),
                trailingIcon: PhosphorIcons.caretRight(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, dynamic currentUser) {
    final c = AppColors.of(context);
    final isLoggedIn = currentUser != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'HESAP YÖNETİMİ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: c.textMuted,
            ),
          ),
        ),
        MidnightCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.users(),
                title: 'Müşterileri Yönet',
                iconColor: c.orange,
                onTap: () => _showClientManagementSheet(context),
                trailingIcon: PhosphorIcons.caretRight(),
              ),
              _divider(),
              if (isLoggedIn)
                _buildSettingsItem(
                  context: context,
                  icon: PhosphorIcons.signOut(),
                  title: 'Çıkış Yap (${currentUser.email})',
                  iconColor: c.error,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) {
                        final dc = AppColors.of(ctx);
                        return AlertDialog(
                          backgroundColor: dc.navBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: dc.cardBorder, width: 1),
                          ),
                          title: Text('Çıkış Yap', style: TextStyle(color: dc.textMain)),
                          content: Text('Çıkış yapmak istediğinize emin misiniz?',
                              style: TextStyle(color: dc.textMuted)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('İptal', style: TextStyle(color: dc.primary)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: dc.error),
                              child: const Text('Çıkış Yap'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed == true && context.mounted) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                )
              else
                _buildSettingsItem(
                  context: context,
                  icon: PhosphorIcons.signIn(),
                  title: 'Giriş Yap / Kayıt Ol',
                  iconColor: c.primary,
                  onTap: () {
                    context.go('/login');
                  },
                  trailingIcon: PhosphorIcons.caretRight(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceSection(BuildContext context) {
    final c = AppColors.of(context);
    final defaultRateAsync = ref.watch(defaultHourlyRateProvider);
    final defaultRate = defaultRateAsync.valueOrNull ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'FİNANS VE ÜCRETLENDİRME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: c.textMuted,
            ),
          ),
        ),
        MidnightCard(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.currencyCircleDollar(),
                title: 'Varsayılan Saatlik Ücret: ${defaultRate.toStringAsFixed(1)} TL',
                iconColor: c.emerald,
                onTap: () => _showHourlyRateDialog(context, defaultRate),
                trailingIcon: PhosphorIcons.pencilSimple(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showHourlyRateDialog(BuildContext context, double currentRate) async {
    final controller = TextEditingController(text: currentRate > 0 ? currentRate.toStringAsFixed(1) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.navBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dc.cardBorder, width: 1),
          ),
          title: Text('Varsayılan Saatlik Ücret', style: TextStyle(color: dc.textMain)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yeni kayıtlar oluşturulurken kullanılacak varsayılan saatlik ücret tutarını girin.',
                style: TextStyle(fontSize: 13, color: dc.textMuted),
              ),
              const SizedBox(height: 16),
              MidnightInput(
                controller: controller,
                hintText: 'Saatlik Ücret (TL)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icon(PhosphorIcons.currencyCircleDollar(), color: dc.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: TextStyle(color: dc.textMuted)),
            ),
            TextButton(
              onPressed: () {
                final val = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
                Navigator.pop(ctx, val);
              },
              style: TextButton.styleFrom(foregroundColor: dc.primary),
              child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await ref.read(defaultHourlyRateProvider.notifier).updateRate(result);
      if (mounted) {
        CustomToast.show(context, 'Varsayılan saatlik ücret güncellendi');
      }
    }
  }

  Widget _buildAboutSection(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'HAKKINDA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: c.textMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Column(
              children: [
                Text(
                  'WORKTRACK v1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.textMain,
                  ),
                ),
                Text(
                  'Günlük iş kayıt uygulaması',
                  style: TextStyle(color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    final c = AppColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 1),
        Container(
          height: 1,
          color: c.cardBorder,
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        const SizedBox(height: 1),
      ],
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
    VoidCallback? onTap,
    IconData? trailingIcon,
    bool hasToggle = false,
    bool toggleValue = false,
  }) {
    final c = AppColors.of(context);
    final accent = iconColor ?? c.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.textMain,
                ),
              ),
            ),
            if (hasToggle)
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: toggleValue
                        ? c.primary
                        : c.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: toggleValue ? 21 : 1,
                        top: 1,
                        bottom: 1,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: c.navBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (trailingIcon != null && !hasToggle)
              Icon(trailingIcon, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Müşteri Yönetim Bottom Sheet ─────────────────────────────────────────

  void _showClientManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ClientManagementSheet(
        onAddOrEdit: (client) => _showAddOrEditClientDialog(context, client: client),
        onDelete: (client) => _showDeleteClientDialog(context, client),
      ),
    );
  }

  Future<void> _showDeleteClientDialog(BuildContext context, Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: dc.navBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dc.cardBorder, width: 1),
          ),
          title: Text('Müşteriyi Sil', style: TextStyle(color: dc.textMain)),
          content: Text('"${client.name}" silinsin mi?', style: TextStyle(color: dc.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('İptal', style: TextStyle(color: dc.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: dc.error),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      await ref.read(clientsProvider.notifier).deleteClient(client.id);
    }
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _showAddOrEditClientDialog(BuildContext context,
      {Client? client}) async {
    final nameController =
        TextEditingController(text: client?.name ?? '');
    String selectedColor =
        client?.color ?? AppConstants.clientColors.first;
    final isEditing = client != null;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final dc = AppColors.of(context);
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dc.navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dc.cardBorder, width: 1),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  final sc = AppColors.of(context);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Müşteriyi Düzenle' : 'Yeni Müşteri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sc.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MidnightInput(
                        controller: nameController,
                        hintText: 'Müşteri Adı',
                        prefixIcon: Icon(PhosphorIcons.buildings(), color: sc.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'RENK SEÇ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sc.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children:
                            AppConstants.clientColors.map((color) {
                          final colorVal = _parseColor(color, sc.primary);
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setDialogState(
                                () => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? sc.textMain
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorVal
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: MidnightButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text('İptal', style: TextStyle(color: sc.onPrimary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MidnightButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) {
                                  return;
                                }
                                Navigator.pop(context, true);
                              },
                              child: Text(
                                isEditing ? 'Kaydet' : 'Ekle',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sc.onPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (result == true && context.mounted) {
      if (isEditing) {
        final updated = client.copyWith(
          name: nameController.text.trim(),
          color: selectedColor,
        );
        await ref.read(clientsProvider.notifier).updateClient(updated);
      } else {
        final newClient = Client(
          name: nameController.text.trim(),
          color: selectedColor,
        );
        await ref.read(clientsProvider.notifier).addClient(newClient);
      }
    }
    nameController.dispose();
  }

  // ── Import Modal ──────────────────────────────────────────────────────────

  void _showImportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImportSheet(),
    );
  }
}

// ── Client Management Bottom Sheet Widget ────────────────────────────────────

class _ClientManagementSheet extends ConsumerWidget {
  final void Function(Client? client) onAddOrEdit;
  final void Function(Client client) onDelete;

  const _ClientManagementSheet({
    required this.onAddOrEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final clientsAsync = ref.watch(clientsProvider);

    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Müşteriler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.textMain,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: c.textMuted),
                ),
              ],
            ),
          ),
          clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 48,
                          color: c.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz müşteri yok',
                        style: TextStyle(color: c.textMuted),
                      ),
                    ],
                  ),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clients.length,
                  itemBuilder: (_, i) {
                    final client = clients[i];
                    final color = _parseColor(client.color, c.primary);
                    return MidnightCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              client.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: c.textMain,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onAddOrEdit(client);
                            },
                            child: Icon(Icons.edit_outlined,
                                color: c.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onDelete(client);
                            },
                            child: Icon(Icons.delete_outline,
                                color: c.error, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: c.primary),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Yüklenirken hata oluştu', style: TextStyle(color: c.textMain)),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: MidnightButton(
              onPressed: () {
                Navigator.pop(context);
                onAddOrEdit(null);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: c.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Yeni Müşteri Ekle',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: c.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }
}

// ── Import Sheet Widget ───────────────────────────────────────────────────────

class _ImportSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  bool _isLoading = false;
  String? _resultMessage;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verileri İçe Aktar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: c.textMain,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İş Kayıtları sayfası — sütunlar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.textMain,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _formatRow(context, 'Tarih', 'dd.MM.yyyy (örn: 15.03.2026)'),
                _formatRow(context, 'Müşteri', 'Müşteri adı'),
                _formatRow(context, 'Başlangıç', 'HH:mm (örn: 09:00)'),
                _formatRow(context, 'Bitiş', 'HH:mm (örn: 17:00)'),
                _formatRow(context, 'İş Türü', 'İsteğe bağlı (boşsa "Diğer" atanır)'),
                _formatRow(context, 'Proje', 'Proje adı (boşsa "Genel")'),
                _formatRow(context, 'Notlar', 'İsteğe bağlı notlar'),
                _formatRow(context, 'Ücret Tipi', '"Saatlik" veya "Sabit"'),
                _formatRow(context, 'Ücret', 'Saatlik ücret veya sabit tutar'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MidnightButton(
            onPressed: () async {
              if (context.mounted) {
                CustomToast.show(context, 'Örnek dosya oluşturuluyor...');
              }
              try {
                await ExportService.generateSampleExcel();
                if (context.mounted) {
                  CustomToast.show(context, 'Örnek dosya hazır');
                }
              } catch (e) {
                debugPrint('Sample Excel export error: $e');
                if (context.mounted) {
                  CustomToast.show(context, 'Hata: $e');
                }
              }
            },
            color: c.primary.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined, color: c.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Örnek Dosyayı İndir',
                  style: TextStyle(color: c.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_resultMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.emerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(color: c.emerald, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          MidnightButton(
            onPressed: _isLoading ? null : () => _pickAndImport(context),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: c.onPrimary, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file_outlined, color: c.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Excel Dosyası Seç',
                        style: TextStyle(fontWeight: FontWeight.bold, color: c.onPrimary),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(BuildContext context, String col, String desc) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(col,
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
              child: Text(desc, style: TextStyle(color: c.textMuted, fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _pickAndImport(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });
    try {
      final count = await ImportService.pickAndImport(ref);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resultMessage = count >= 0
              ? '$count kayıt başarıyla içe aktarıldı'
              : 'Dosya seçilmedi';
        });
        if (count > 0) {
          CustomToast.show(context, '$count kayıt içe aktarıldı');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'Hata: $e';
        });
      }
    }
  }
}
