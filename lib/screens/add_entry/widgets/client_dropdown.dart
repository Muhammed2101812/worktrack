import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/client.dart';
import '../../../core/widgets/midnight_widgets.dart';
import '../../../core/theme.dart';

class ClientDropdown extends StatelessWidget {
  final List<Client> clients;
  final Client? selectedClient;
  final ValueChanged<Client> onClientSelected;
  final VoidCallback onAddClient;

  const ClientDropdown({
    super.key,
    required this.clients,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showClientSelector(context),
      child: MidnightCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (selectedClient != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(int.parse(selectedClient!.color.replaceAll('#', '0xFF'))).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    selectedClient!.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Color(int.parse(selectedClient!.color.replaceAll('#', '0xFF'))),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedClient!.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ] else ...[
              Icon(PhosphorIcons.buildings(), color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Müşteri Seç',
                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                ),
              ),
            ],
            Icon(PhosphorIcons.caretDown(), color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _showClientSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'MÜŞTERİ SEÇİN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clients.length + 1,
                  itemBuilder: (context, index) {
                    if (index == clients.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: MidnightButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onAddClient();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIcons.plus(), color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              const Text(
                                'YENİ MÜŞTERİ EKLE',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final client = clients[index];
                    final isSelected = selectedClient?.id == client.id;
                    final clientColor = Color(int.parse(client.color.replaceAll('#', '0xFF')));

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MidnightCard(
                        onTap: () {
                          Navigator.pop(context);
                          onClientSelected(client);
                        },
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: clientColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: clientColor.withValues(alpha: 0.4), width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  client.name[0].toUpperCase(),
                                  style: TextStyle(color: clientColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                client.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
