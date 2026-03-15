import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/client.dart';
import '../../core/constants.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import '../../services/export_service.dart';
import '../../services/import_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider);
    final syncAsync = ref.watch(syncProvider);
    final unsyncedAsync = ref.watch(unsyncedEntriesProvider);
    final syncEnabled = ref.watch(syncEnabledProvider).valueOrNull ?? true;

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
                    child: Icon(PhosphorIcons.x(),
                        color: MidnightColors.textMain, size: 24),
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
                  _buildDataSyncSection(context, syncAsync, unsyncedAsync, syncEnabled),
                  _buildAccountSection(context, currentUser),
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
    AsyncValue syncAsync,
    AsyncValue unsyncedAsync,
    bool syncEnabled,
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
                toggleValue: syncEnabled,
                onTap: () => ref.read(syncEnabledProvider.notifier).toggle(),
              ),
              _divider(),
              _buildSettingsItem(
                context: context,
                icon: PhosphorIcons.fileXls(),
                title: 'Verileri Dışa Aktar (Excel)',
                iconColor: MidnightColors.emerald,
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
                        CustomToast.show(context, 'Excel dosyası indiriliyor...');
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
                iconColor: MidnightColors.orange,
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
                onTap: () => _showClientManagementSheet(context),
                trailingIcon: PhosphorIcons.caretRight(),
              ),
              _divider(),
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
                      title: const Text('Çıkış Yap',
                          style: TextStyle(color: MidnightColors.textMain)),
                      content: const Text(
                          'Çıkış yapmak istediğinize emin misiniz?',
                          style: TextStyle(color: MidnightColors.textMuted)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('İptal',
                              style:
                                  TextStyle(color: MidnightColors.primary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                              foregroundColor: MidnightColors.error),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ],
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
                const Text(
                  'WORKTRACK v1.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MidnightColors.textMain,
                  ),
                ),
                Text(
                  'Günlük iş kayıt uygulaması',
                  style: TextStyle(color: MidnightColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Column(
      children: [
        const SizedBox(height: 1),
        Container(
          height: 1,
          color: MidnightColors.cardBorder,
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
                color: (iconColor ?? MidnightColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (iconColor ?? MidnightColors.primary)
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon,
                  color: iconColor ?? MidnightColors.primary, size: 20),
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
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 24,
                  decoration: BoxDecoration(
                    color: toggleValue
                        ? MidnightColors.primary
                        : MidnightColors.textMuted.withValues(alpha: 0.3),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (trailingIcon != null && !hasToggle)
              Icon(trailingIcon, color: MidnightColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Müşteri Yönetim Bottom Sheet ─────────────────────────────────────────

  void _showClientManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
      builder: (ctx) => AlertDialog(
        backgroundColor: MidnightColors.navBg,
        title: const Text('Müşteriyi Sil',
            style: TextStyle(color: MidnightColors.textMain)),
        content: Text('"${client.name}" silinsin mi?',
            style: const TextStyle(color: MidnightColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: MidnightColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: MidnightColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(clientsProvider.notifier).deleteClient(client.id);
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
                border:
                    Border.all(color: MidnightColors.cardBorder, width: 1),
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
                        prefixIcon: Icon(PhosphorIcons.buildings(),
                            color: MidnightColors.primary),
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
                        children:
                            AppConstants.clientColors.map((color) {
                          final colorVal = Color(int.parse(
                              color.replaceAll('#', '0xFF')));
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
                                      ? MidnightColors.textMain
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
                              child: const Text('İptal',
                                  style: TextStyle(color: Colors.white)),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
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
    final clientsAsync = ref.watch(clientsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: MidnightColors.cardBorder,
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
                    color: MidnightColors.textMain,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      Icon(Icons.close, color: MidnightColors.textMuted),
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
                          color: MidnightColors.textMuted
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'Henüz müşteri yok',
                        style: TextStyle(color: MidnightColors.textMuted),
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
                    final color = Color(int.parse(
                        client.color.replaceAll('#', '0xFF')));
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: MidnightColors.textMain,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onAddOrEdit(client);
                            },
                            child: Icon(Icons.edit_outlined,
                                color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              onDelete(client);
                            },
                            child: Icon(Icons.delete_outline,
                                color: MidnightColors.error, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                  color: MidnightColors.primary),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Yüklenirken hata oluştu',
                  style: TextStyle(color: MidnightColors.textMain)),
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
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Yeni Müşteri Ekle',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: MidnightColors.textMain,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: MidnightColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MidnightColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: MidnightColors.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Örnek dosya formatı:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MidnightColors.textMain,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _formatRow('Tarih', 'dd.MM.yyyy (örn: 15.03.2026)'),
                _formatRow('Müşteri', 'Müşteri adı'),
                _formatRow('Başlangıç', 'HH:mm (örn: 09:00)'),
                _formatRow('Bitiş', 'HH:mm (örn: 17:00)'),
                _formatRow('İş Türü', 'Yapılan işin türü'),
                _formatRow('Notlar', 'İsteğe bağlı notlar'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MidnightButton(
            onPressed: () async {
              try {
                await ExportService.generateSampleExcel();
                if (context.mounted) {
                  CustomToast.show(context, 'Örnek dosya indirildi');
                }
              } catch (e) {
                if (context.mounted) {
                  CustomToast.show(context, 'İndirme sırasında hata oluştu');
                }
              }
            },
            color: MidnightColors.primary.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined,
                    color: MidnightColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Örnek Dosyayı İndir',
                  style: TextStyle(
                      color: MidnightColors.primary,
                      fontWeight: FontWeight.bold),
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
                  color: MidnightColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: MidnightColors.emerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                      color: MidnightColors.emerald,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          MidnightButton(
            onPressed: _isLoading ? null : () => _pickAndImport(context),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Excel Dosyası Seç',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(String col, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(col,
                style: TextStyle(
                    color: MidnightColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          Expanded(
              child: Text(desc,
                  style: TextStyle(
                      color: MidnightColors.textMuted, fontSize: 12))),
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
