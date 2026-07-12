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

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      final entry = widget.entryToEdit!;
      _selectedClient = Client(id: entry.clientId, name: entry.clientName, color: entry.clientColor);

      final dateParts = entry.date.split('.');
      if(dateParts.length == 3) {
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
      _workType = AppConstants.workTypes.first;
      _notes = '';
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _fixedPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Icon(PhosphorIcons.x(), color: MidnightColors.textMain, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.entryToEdit == null ? 'Yeni Kayıt' : 'Kaydı Düzenle',
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
              child: clientsAsync.when(
                data: (clients) => _buildForm(clients),
                loading: () => const Center(child: CircularProgressIndicator(color: MidnightColors.primary)),
                error: (error, _) => Center(child: Text('Hata: $error', style: TextStyle(color: MidnightColors.textMain))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<Client> clients) {
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
                color: MidnightColors.textMuted,
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
                'PROJE *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: MidnightColors.textMuted,
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
                color: MidnightColors.textMuted,
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
                color: MidnightColors.textMuted,
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
              'ÜCRETLENDİRME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: MidnightColors.textMuted,
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
                          ? MidnightColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _billingType == 'hourly'
                            ? MidnightColors.primary
                            : MidnightColors.cardBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Saatlik Ücret',
                      style: TextStyle(
                        fontWeight: _billingType == 'hourly' ? FontWeight.bold : FontWeight.w600,
                        color: _billingType == 'hourly' ? MidnightColors.primary : MidnightColors.textMain,
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
                          ? MidnightColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: _billingType == 'fixed'
                            ? MidnightColors.primary
                            : MidnightColors.cardBorder,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Sabit Ücret',
                      style: TextStyle(
                        fontWeight: _billingType == 'fixed' ? FontWeight.bold : FontWeight.w600,
                        color: _billingType == 'fixed' ? MidnightColors.primary : MidnightColors.textMain,
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
                    hintText: 'Saatlik Ücret (TL)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(PhosphorIcons.currencyCircleDollar(), color: MidnightColors.primary),
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
                      color: MidnightColors.shimmer1.withValues(alpha: 0.15),
                      border: Border.all(color: MidnightColors.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Toplam: ${(_calcDurationHours() * _hourlyRate).toStringAsFixed(1)} TL',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MidnightColors.textMain,
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
              hintText: 'Sabit Ücret Tutarı (TL)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icon(PhosphorIcons.wallet(), color: MidnightColors.primary),
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
                color: MidnightColors.textMuted,
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
                Icon(PhosphorIcons.checkCircle(), color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  widget.entryToEdit == null ? 'KAYDI TAMAMLA' : 'DEĞİŞİKLİKLERİ KAYDET',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
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
    final projectsAsync = ref.watch(projectsProvider);
    return GestureDetector(
      onTap: () => _showProjectSelector(projectsAsync),
      child: MidnightCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(PhosphorIcons.folderSimple(), color: MidnightColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedProject?.name ?? 'Proje Seç',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: _selectedProject != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedProject != null ? MidnightColors.textMain : MidnightColors.textMuted,
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
                  child: Icon(PhosphorIcons.x(), color: MidnightColors.textMuted, size: 18),
                ),
              ),
            Icon(PhosphorIcons.caretDown(), color: MidnightColors.textMuted, size: 16),
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
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: MidnightColors.navBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: MidnightColors.cardBorder, width: 1),
            ),
            child: Column(
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
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'PROJE SEÇİN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: MidnightColors.textMuted,
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
                              style: TextStyle(color: MidnightColors.textMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: clientProjects.length,
                          itemBuilder: (context, index) {
                            final project = clientProjects[index];
                            final isSelected =
                                _selectedProject?.id == project.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: MidnightCard(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _selectedProject = project;
                                  });
                                },
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: MidnightColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: MidnightColors.primary
                                              .withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(PhosphorIcons.folderSimple(),
                                            color: MidnightColors.primary,
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
                                          color: MidnightColors.textMain,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        PhosphorIcons.checkCircle(
                                            PhosphorIconsStyle.fill),
                                        color: MidnightColors.primary,
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
                      Navigator.pop(context);
                      _showAddProjectDialog();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.plus(), color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        const Text(
                          'YENİ PROJE OLUŞTUR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showAddProjectDialog() async {
    final nameController = TextEditingController();

    final result = await showGeneralDialog<String>(
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MidnightColors.cardBorder, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MidnightColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(PhosphorIcons.folderSimplePlus(),
                          color: MidnightColors.primary, size: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'YENİ PROJE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: MidnightColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MidnightInput(
                    controller: nameController,
                    hintText: 'Proje Adı',
                    prefixIcon: Icon(PhosphorIcons.folderSimple(),
                        color: MidnightColors.primary),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: MidnightButton(
                          onPressed: () => Navigator.pop(context),
                          color: MidnightColors.shimmer1.withValues(alpha: 0.5),
                          child: const Text('İPTAL',
                              style: TextStyle(color: MidnightColors.textMain)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MidnightButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;
                            Navigator.pop(context, nameController.text.trim());
                          },
                          child: const Text('OLUŞTUR',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
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

    if (result != null && result.isNotEmpty) {
      final project = Project(
        clientId: _selectedClient!.id,
        name: result,
      );
      await ref.read(projectsProvider.notifier).addProject(project);
      setState(() {
        _selectedProject = project;
      });
    }
  }

  Future<void> _showAddClientDialog() async {
    final nameController = TextEditingController();
    String selectedColor = AppConstants.clientColors.first;

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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: MidnightColors.cardBorder, width: 1),
              ),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'YENİ MÜŞTERİ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
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
                      Text(
                        'RENK SEÇİN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
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
                              width: 36,
                              height: 36,
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
                              child: const Text('İPTAL', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MidnightButton(
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) return;
                                Navigator.pop(context, true);
                              },
                              child: const Text('EKLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      final diff = endMin - startMin;
      return diff > 0 ? diff / 60.0 : 0.0;
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

    if (_selectedProject == null) {
      CustomToast.show(context, 'Lütfen bir proje seçin');
      return;
    }

    final startParts = _startTime.split(':').map(int.parse).toList();
    final endParts = _endTime.split(':').map(int.parse).toList();
    
    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];
    
    if (endMinutes <= startMinutes) {
      CustomToast.show(context, 'Bitiş saati başlangıç saatten büyük olmalı');
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
      createdAt: widget.entryToEdit?.createdAt,
    );

    if (widget.entryToEdit == null) {
      await ref.read(entriesProvider.notifier).addEntry(entry);
    } else {
      await ref.read(entriesProvider.notifier).updateEntry(entry);
    }
    
    if (mounted) {
      CustomToast.show(context, widget.entryToEdit == null ? 'Kayıt başarıyla eklendi' : 'Kayıt başarıyla güncellendi');
      context.go('/home');
    }
  }
}
