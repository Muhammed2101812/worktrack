import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/entries_provider.dart';
import '../../providers/clients_provider.dart';
import '../../models/work_entry.dart';
import '../../models/client.dart';
import '../../core/constants.dart';
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
  late DateTime _selectedDate;
  late String _startTime;
  late String _endTime;
  late String _workType;
  late String _notes;

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
    } else {
      _selectedDate = DateTime.now();
      _startTime = '09:00';
      _endTime = '13:00';
      _workType = AppConstants.workTypes.first;
      _notes = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

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
              });
            },
            onAddClient: () => _showAddClientDialog(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'YAPILAN İŞ',
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
                borderRadius: BorderRadius.circular(20),
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

  Future<void> _saveEntry() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedClient == null) {
      CustomToast.show(context, 'Lütfen bir müşteri seçin');
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
