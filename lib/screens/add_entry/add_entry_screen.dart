import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../providers/projects_provider.dart';
import '../../models/work_entry.dart';
import '../../models/client.dart';
import '../../models/project.dart';
import '../../core/constants.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/midnight_widgets.dart';
import '../../core/theme.dart';
import 'widgets/client_dropdown.dart';
import 'widgets/time_picker_row.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  final WorkEntry? entryToEdit;

  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  Client? _selectedClient;
  Project? _selectedProject;
  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  late String _workType;
  late String _notes;

  String _billingType = 'hourly';
  double _hourlyRate = 0.0;
  double _totalPrice = 0.0;
  final _hourlyRateController = TextEditingController();
  final _fixedPriceController = TextEditingController();

  String? _breakStart;
  String? _breakEnd;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final entry = widget.entryToEdit!;
      _selectedClient = Client(id: entry.clientId, name: entry.clientName, color: entry.clientColor);

      final dateParts = entry.date.split('.');
      if (dateParts.length == 3) {
        _selectedDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      } else {
        _selectedDate = DateTime.now();
      }

      _startTime = entry.startTime;
      _endTime = entry.endTime;
      _workType = entry.workType;
      _notes = entry.notes;
      _billingType = entry.billingType;
      _hourlyRate = entry.hourlyRate;
      _totalPrice = entry.totalPrice;
      _hourlyRateController.text = _hourlyRate > 0 ? _hourlyRate.toStringAsFixed(1) : '';
      _fixedPriceController.text = _billingType == 'fixed' && _totalPrice > 0 ? _totalPrice.toStringAsFixed(1) : '';
      _breakStart = entry.breakStart;
      _breakEnd = entry.breakEnd;

      if (entry.projectId != null && entry.projectName != null) {
        _selectedProject = Project(
          id: entry.projectId!,
          clientId: entry.clientId,
          name: entry.projectName!,
        );
      }
    } else {
      _selectedDate = DateTime.now();
      _startTime = '09:00';
      _endTime = '13:00';
      _workType = 'Diğer';
      _notes = '';
      _breakStart = null;
      _breakEnd = null;
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _fixedPriceController.dispose();
    super.dispose();
  }

  /// Safely parses a `HH:mm` time string into `[hours, minutes]`.
  /// Returns `null` on any parse / format error.
  List<int>? _safeParseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return [h, m];
    } catch (_) {
      return null;
    }
  }

  /// Safely parses a `#RRGGBB` / `0xFFRRGGBB` hex colour into a [Color].
  /// Falls back to the theme primary on any error.
  Color _parseColor(String hex, AppPalette c) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.isEmpty) return c.primary;
      final value = int.parse(clean.length == 6 ? 'FF$clean' : clean);
      return Color(value);
    } catch (_) {
      return c.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final clientsAsync = ref.watch(clientsProvider);
    final defaultRate = ref.watch(defaultHourlyRateProvider).valueOrNull ?? 0.0;
    if (widget.entryToEdit == null && _hourlyRate == 0.0 && defaultRate > 0.0 && _hourlyRateController.text.isEmpty) {
      _hourlyRate = defaultRate;
      _hourlyRateController.text = defaultRate.toStringAsFixed(1);
    }

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
                    child: Icon(PhosphorIcons.x(), color: c.textMain, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.entryToEdit == null ? 'Yeni Kayıt' : 'Kaydı Düzenle',
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
              child: clientsAsync.when(
                data: (clients) => _buildForm(clients),
                loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
                error: (error, _) => Center(child: Text('Hata: $error', style: TextStyle(color: c.textMain))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<Client> clients) {
    final c = AppColors.of(context);
    final currency = ref.watch(currencyProvider).valueOrNull ?? 'TL';
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'MÜŞTERİ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          ClientDropdown(
            clients: clients,
            selectedClient: _selectedClient,
            onClientSelected: (client) {
              setState(() {
                _selectedClient = client;
                // Müşteri değişince seçili projeyi sıfırla
                _selectedProject = null;
              });
            },
            onAddClient: () => _showAddClientDialog(),
          ),
          if (_selectedClient != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'PROJE (İSTEĞE BAĞLI)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: c.textMuted,
                ),
              ),
            ),
            _buildProjectSelector(),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'YAPILAN İŞ (İSTEĞE BAĞLI)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          MidnightInput(
            initialValue: _workType,
            hintText: 'Örn: Arayüz tasarımı',
            onChanged: (value) {
              setState(() {
                _workType = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SAAT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          TimePickerRow(
            startTime: _startTime,
            endTime: _endTime,
            onStartTimeChanged: (time) {
              setState(() {
                _startTime = time;
              });
            },
            onEndTimeChanged: (time) {
              setState(() {
                _endTime = time;
              });
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'MOLA (İSTEĞE BAĞLI)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Başlangıç',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.textMuted),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final initialMin = _safeParseTime(_breakStart ?? '12:00') ?? [12, 0];
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: initialMin[0], minute: initialMin[1]),
                        );
                        if (picked != null) {
                          setState(() {
                            _breakStart = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: MidnightCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Center(
                          child: Text(
                            _breakStart ?? '--:--',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _breakStart != null ? c.textMain : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Bitiş',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c.textMuted),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final initialMin = _safeParseTime(_breakEnd ?? '12:30') ?? [12, 30];
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: initialMin[0], minute: initialMin[1]),
                        );
                        if (picked != null) {
                          setState(() {
                            _breakEnd = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: MidnightCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Center(
                          child: Text(
                            _breakEnd ?? '--:--',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _breakEnd != null ? c.textMain : c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_breakStart != null || _breakEnd != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_breakStart != null && _breakEnd != null) ...[
                  Builder(
                    builder: (ctx) {
                      final bs = _breakStart!.split(':');
                      final be = _breakEnd!.split(':');
                      final bStartMin = int.parse(bs[0]) * 60 + int.parse(bs[1]);
                      final bEndMin = int.parse(be[0]) * 60 + int.parse(be[1]);
                      var bDiff = bEndMin - bStartMin;
                      if (bDiff < 0) bDiff += 24 * 60;
                      final breakHours = bDiff / 60.0;
                      return Text(
                        'Mola: ${breakHours.toStringAsFixed(1)} sa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      );
                    },
                  ),
                ] else
                  const SizedBox(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _breakStart = null;
                      _breakEnd = null;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Temizle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ÜCRETLENDİRME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _billingType = 'hourly';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _billingType == 'hourly'
                          ? c.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _billingType == 'hourly' ? c.primary : c.cardBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Saatlik Ücret',
                      style: TextStyle(
                        fontWeight: _billingType == 'hourly' ? FontWeight.bold : FontWeight.w600,
                        color: _billingType == 'hourly' ? c.primary : c.textMain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _billingType = 'fixed';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _billingType == 'fixed'
                          ? c.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _billingType == 'fixed' ? c.primary : c.cardBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Sabit Ücret',
                      style: TextStyle(
                        fontWeight: _billingType == 'fixed' ? FontWeight.bold : FontWeight.w600,
                        color: _billingType == 'fixed' ? c.primary : c.textMain,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_billingType == 'hourly') ...[
            Row(
              children: [
                Expanded(
                  child: MidnightInput(
                    controller: _hourlyRateController,
                    hintText: 'Saatlik Ücret ($currency)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(PhosphorIcons.currencyCircleDollar(), color: c.primary),
                    onChanged: (value) {
                      setState(() {
                        _hourlyRate = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: c.shimmer1.withValues(alpha: 0.15),
                      border: Border.all(color: c.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Toplam: ${(_calcDurationHours() * _hourlyRate).toStringAsFixed(1)} $currency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.textMain,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            MidnightInput(
              controller: _fixedPriceController,
              hintText: 'Sabit Ücret Tutarı ($currency)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icon(PhosphorIcons.wallet(), color: c.primary),
              onChanged: (value) {
                setState(() {
                  _totalPrice = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                });
              },
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'NOTLAR (İSTEĞE BAĞLI)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: c.textMuted,
              ),
            ),
          ),
          MidnightInput(
            initialValue: _notes,
            hintText: 'Geliştirme detayları...',
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _notes = value;
              });
            },
          ),
          const SizedBox(height: 40),
          MidnightButton(
            onPressed: _saveEntry,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.checkCircle(), color: c.onPrimary),
                const SizedBox(width: 12),
                Text(
                  widget.entryToEdit == null ? 'KAYDI TAMAMLA' : 'DEĞİŞİKLİKLERİ KAYDET',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: c.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector() {
    final c = AppColors.of(context);
    final projectsAsync = ref.watch(projectsProvider);
    return GestureDetector(
      onTap: () => _showProjectSelector(projectsAsync),
      child: MidnightCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(PhosphorIcons.folderSimple(), color: c.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedProject?.name ?? 'Proje Seç',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _selectedProject != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedProject != null ? c.textMain : c.textMuted,
                ),
              ),
            ),
            if (_selectedProject != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedProject = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(PhosphorIcons.x(), color: c.textMuted, size: 18),
                ),
              ),
            Icon(PhosphorIcons.caretDown(), color: c.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _showProjectSelector(AsyncValue<List<Project>> projectsAsync) {
    projectsAsync.whenData((allProjects) {
      final clientProjects =
          allProjects.where((p) => p.clientId == _selectedClient!.id).toList();

      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          final sc = AppColors.of(sheetContext);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (dsContext, scrollController) => Container(
              decoration: BoxDecoration(
                color: sc.navBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: sc.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sc.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'PROJE SEÇİN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: sc.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: clientProjects.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Bu müşteri için henüz proje yok.\nAşağıdan yeni bir proje oluşturun.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: sc.textMuted),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: clientProjects.length,
                            itemBuilder: (itemContext, index) {
                              final project = clientProjects[index];
                              final isSelected =
                                  _selectedProject?.id == project.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MidnightCard(
                                  onTap: () {
                                    Navigator.pop(dsContext);
                                    setState(() {
                                      _selectedProject = project;
                                    });
                                  },
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: sc.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: sc.primary
                                                .withValues(alpha: 0.4),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(PhosphorIcons.folderSimple(),
                                              color: sc.primary,
                                              size: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          project.name,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 15,
                                            color: sc.textMain,
                                          ),
                                        ),
                                      ),
                                      // Edit
                                      GestureDetector(
                                        onTap: () async {
                                          Navigator.pop(dsContext);
                                          final updated = await _showAddProjectDialog(project: project);
                                          if (updated != null && updated.id == _selectedProject?.id) {
                                            setState(() => _selectedProject = updated);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                          child: Icon(Icons.edit_outlined, color: sc.primary, size: 18),
                                        ),
                                      ),
                                      // Delete
                                      GestureDetector(
                                        onTap: () async {
                                          final confirmed = await _showDeleteProjectDialog(dsContext, project);
                                          if (confirmed == true) {
                                            await ref.read(projectsProvider.notifier).deleteProject(project.id);
                                            if (_selectedProject?.id == project.id) {
                                              setState(() => _selectedProject = null);
                                            }
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                          child: Icon(Icons.delete_outline, color: sc.error, size: 18),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          PhosphorIcons.checkCircle(
                                              PhosphorIconsStyle.fill),
                                          color: sc.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: MidnightButton(
                      onPressed: () {
                        Navigator.pop(dsContext);
                        _showAddProjectDialog();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(), color: sc.onPrimary, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'YENİ PROJE OLUŞTUR',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: sc.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Shows the project dialog. When [project] is null a new project is created;
  /// when provided, the project is edited (rename) and the updated Project is
  /// returned so callers can refresh their selection.
  Future<Project?> _showAddProjectDialog({Project? project}) async {
    final isEditing = project != null;
    final nameController = TextEditingController(text: project?.name ?? '');

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        final dc = AppColors.of(dialogContext);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: dc.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                          isEditing
                              ? PhosphorIcons.folderSimpleUser()
                              : PhosphorIcons.folderSimplePlus(),
                          color: dc.primary,
                          size: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEditing ? 'PROJEYİ DÜZENLE' : 'YENİ PROJE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: dc.textMain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MidnightInput(
                    controller: nameController,
                    hintText: 'Proje Adı',
                    prefixIcon: Icon(PhosphorIcons.folderSimple(),
                        color: dc.primary),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: MidnightButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          color: dc.shimmer1.withValues(alpha: 0.5),
                          child: Text('İPTAL',
                              style: TextStyle(color: dc.textMain)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MidnightButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;
                            Navigator.pop(dialogContext, nameController.text.trim());
                          },
                          child: Text(isEditing ? 'KAYDET' : 'OLUŞTUR',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: dc.onPrimary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return null;

    if (isEditing) {
      final updated = project.copyWith(
        name: result,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await ref.read(projectsProvider.notifier).updateProject(updated);
      return updated;
    } else {
      final newProject = Project(
        clientId: _selectedClient!.id,
        name: result,
      );
      await ref.read(projectsProvider.notifier).addProject(newProject);
      setState(() {
        _selectedProject = newProject;
      });
      return newProject;
    }
  }

  Future<bool?> _showDeleteProjectDialog(BuildContext context, Project project) {
    final dc = AppColors.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dc.navBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: dc.cardBorder, width: 1),
        ),
        title: Text('Projeyi Sil', style: TextStyle(color: dc.textMain)),
        content: Text('"${project.name}" projesi silinsin mi?',
            style: TextStyle(color: dc.textMuted)),
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
      ),
    );
  }

  Future<void> _showAddClientDialog() async {
    final c = AppColors.of(context);
    final nameController = TextEditingController();
    String selectedColor = AppConstants.clientColors.first;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.navBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.cardBorder, width: 1),
              ),
              child: StatefulBuilder(
                builder: (sbContext, setDialogState) {
                  final sc = AppColors.of(sbContext);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YENİ MÜŞTERİ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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
                        'RENK SEÇİN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: sc.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: AppConstants.clientColors.map((color) {
                          final colorVal = _parseColor(color, sc);
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorVal,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? sc.textMain : Colors.transparent,
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
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: Text('İPTAL', style: TextStyle(color: sc.onPrimary)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MidnightButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) return;
                                Navigator.pop(dialogContext, true);
                              },
                              child: Text('EKLE', style: TextStyle(fontWeight: FontWeight.bold, color: sc.onPrimary)),
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

    if (result == true) {
      final client = Client(
        name: nameController.text.trim(),
        color: selectedColor,
      );
      await ref.read(clientsProvider.notifier).addClient(client);
      setState(() {
        _selectedClient = client;
      });
    }
  }

  double _calcDurationHours() {
    try {
      final s = _startTime.split(':');
      final e = _endTime.split(':');
      final startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
      final endMin = int.parse(e[0]) * 60 + int.parse(e[1]);
      var diff = endMin - startMin;
      if (diff < 0) diff += 24 * 60;
      final gross = diff / 60.0;

      double breakHours = 0.0;
      if (_breakStart != null && _breakEnd != null) {
        final bs = _breakStart!.split(':');
        final be = _breakEnd!.split(':');
        final bStartMin = int.parse(bs[0]) * 60 + int.parse(bs[1]);
        final bEndMin = int.parse(be[0]) * 60 + int.parse(be[1]);
        var bDiff = bEndMin - bStartMin;
        if (bDiff < 0) bDiff += 24 * 60;
        breakHours = bDiff / 60.0;
      }

      final net = gross - breakHours;
      return net < 0 ? 0.0 : net;
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedClient == null) {
      CustomToast.show(context, 'Lütfen bir müşteri seçin');
      return;
    }

    final startParts = _safeParseTime(_startTime);
    final endParts = _safeParseTime(_endTime);

    if (startParts == null || endParts == null) {
      CustomToast.show(context, 'Geçersiz saat formatı');
      return;
    }

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];

    if (startMinutes == endMinutes) {
      CustomToast.show(context, 'Başlangıç ve bitiş aynı saat olamaz');
      return;
    }

    double finalTotalPrice = 0.0;
    if (_billingType == 'hourly') {
      finalTotalPrice = _calcDurationHours() * _hourlyRate;
    } else {
      finalTotalPrice = _totalPrice;
    }

    final entry = WorkEntry(
      id: widget.entryToEdit?.id,
      clientId: _selectedClient!.id,
      clientName: _selectedClient!.name,
      clientColor: _selectedClient!.color,
      date: DateFormat('dd.MM.yyyy').format(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      workType: _workType,
      notes: _notes,
      synced: false,
      projectId: _selectedProject?.id,
      projectName: _selectedProject?.name,
      billingType: _billingType,
      hourlyRate: _billingType == 'hourly' ? _hourlyRate : 0.0,
      totalPrice: finalTotalPrice,
      breakStart: _breakStart,
      breakEnd: _breakEnd,
      createdAt: widget.entryToEdit?.createdAt,
    );

    try {
      if (widget.entryToEdit == null) {
        await ref.read(entriesProvider.notifier).addEntry(entry);
      } else {
        await ref.read(entriesProvider.notifier).updateEntry(entry);
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.entryToEdit == null
              ? 'Kayıt başarıyla eklendi'
              : 'Kayıt başarıyla güncellendi',
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Kayıt kaydedilemedi: $e');
      }
    }
  }
}
