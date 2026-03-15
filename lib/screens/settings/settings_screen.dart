import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/sync_provider.dart';
import '../../models/client.dart';
import '../../core/constants.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../../services/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authNotifierProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final syncAsync = ref.watch(syncProvider);
    final unsyncedAsync = ref.watch(unsyncedEntriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Icon(PhosphorIcons.x(), color: MidnightColors.textMain, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MidnightColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  _buildDataSyncSection(context, ref, syncAsync, unsyncedAsync),
                  _buildAccountSection(context, ref, currentUser),
                  _buildClientsSection(context, ref, clientsAsync),
                  _buildAboutSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSyncSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue syncAsync,
    AsyncValue unsyncedAsync,
  ) {
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
              color: MidnightColors.textMuted,
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
                iconColor: MidnightColors.primary,
                hasToggle: true,
                toggleValue: true,
              ),
              const SizedBox(height: 1),
              Container(
                height: 1,
                color: MidnightColors.cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 1),
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.fileCsv(),
                title: 'Verileri Dışa Aktar (CSV)',
                iconColor: MidnightColors.emerald,
                onTap: () async {
                  final entriesProviderValue = ref.read(entriesProvider);
                  final clientsProviderValue = ref.read(clientsProvider);

                  if (entriesProviderValue.value != null && clientsProviderValue.value != null) {
                    try {
                      await ExportService.exportToCSV(
                        entriesProviderValue.value!, 
                        clientsProviderValue.value!
                      );
                      if (context.mounted) {
                        CustomToast.show(context, 'CSV dosyası indiriliyor...');
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    dynamic currentUser,
  ) {
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
              color: MidnightColors.textMuted,
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
                iconColor: MidnightColors.orange,
                onTap: () => _showAddOrEditClientDialog(context, ref),
                trailingIcon: PhosphorIcons.caretRight(),
              ),
              const SizedBox(height: 1),
              Container(
                height: 1,
                color: MidnightColors.cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 1),
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.signOut(),
                title: 'Çıkış Yap',
                iconColor: MidnightColors.error,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: MidnightColors.navBg,
                      title: const Text('Çıkış Yap', style: TextStyle(color: MidnightColors.textMain)),
                      content: const Text('Çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: MidnightColors.textMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('İptal', style: TextStyle(color: MidnightColors.primary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: MidnightColors.error),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue clientsAsync,
  ) {
    return clientsAsync.when(
      data: (clients) {
        if (clients.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'MÜŞTERİLER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: MidnightColors.textMuted,
                ),
              ),
            ),
            ...clients.map((client) => MidnightCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(client.color.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w500, color: MidnightColors.textMain))),
                  GestureDetector(
                    onTap: () => _showAddOrEditClientDialog(context, ref, client: client),
                    child: Icon(PhosphorIcons.pencilSimple(), color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showDeleteClientDialog(context, ref, client),
                    child: Icon(PhosphorIcons.trash(), color: MidnightColors.error, size: 20),
                  ),
                ],
              ),
            )).toList(),
          ],
        );
      },
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(color: MidnightColors.primary),
      )),
      error: (_, __) => const Text('Yüklenirken hata oluştu', style: TextStyle(color: MidnightColors.textMain)),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
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
              color: MidnightColors.textMuted,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MidnightColors.textMain,
                  ),
                ),
                Text(
                  'Günlük iş kayıt uygulaması',
                  style: TextStyle(
                    color: MidnightColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    bool? toggleValue,
  }) {
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
                color: (iconColor ?? MidnightColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (iconColor ?? MidnightColors.primary).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor ?? MidnightColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MidnightColors.textMain,
                ),
              ),
            ),
            if (hasToggle)
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: MidnightColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: MidnightColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 1,
                      top: 1,
                      bottom: 1,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: MidnightColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteClientDialog(BuildContext context, WidgetRef ref, Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightColors.navBg,
        title: const Text('Müşteriyi Sil', style: TextStyle(color: MidnightColors.textMain)),
        content: Text('"${client.name}" silinsin mi?', style: const TextStyle(color: MidnightColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: MidnightColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: MidnightColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(clientsProvider.notifier).deleteClient(client.id);
    }
  }

  Future<void> _showAddOrEditClientDialog(BuildContext context, WidgetRef ref, {Client? client}) async {
    final nameController = TextEditingController(text: client?.name ?? '');
    String selectedColor = client?.color ?? AppConstants.clientColors.first;
    final isEditing = client != null;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MidnightColors.navBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: MidnightColors.cardBorder, width: 1),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Müşteriyi Düzenle' : 'Yeni Müşteri',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MidnightColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MidnightInput(
                        controller: nameController,
                        hintText: 'Müşteri Adı',
                        prefixIcon: Icon(PhosphorIcons.buildings(), color: MidnightColors.primary),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'RENK SEÇ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MidnightColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: AppConstants.clientColors.map((color) {
                          final colorVal = Color(int.parse(color.replaceAll('#', '0xFF')));
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? MidnightColors.textMain : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: colorVal.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ] : [],
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
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MidnightButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) return;
                                Navigator.pop(context, true);
                              },
                              child: Text(isEditing ? 'Kaydet' : 'Ekle', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        final updatedClient = client.copyWith(
          name: nameController.text.trim(),
          color: selectedColor,
        );
        await ref.read(clientsProvider.notifier).updateClient(updatedClient);
      } else {
        final newClient = Client(
          name: nameController.text.trim(),
          color: selectedColor,
        );
        await ref.read(clientsProvider.notifier).addClient(newClient);
      }
    }
  }
}
