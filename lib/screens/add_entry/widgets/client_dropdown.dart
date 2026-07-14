import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../models/client.dart';
import '../../../core/widgets/app_widgets.dart';
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
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => _showClientSelector(context),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (selectedClient != null) ...[
              AppAvatar(
                name: selectedClient!.name,
                hexColor: selectedClient!.color,
                size: AvatarSize.sm,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedClient!.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textMain,
                  ),
                ),
              ),
            ] else ...[
              Icon(PhosphorIcons.buildings(), color: c.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Müşteri Seç',
                  style: TextStyle(fontSize: 15, color: c.textMuted),
                ),
              ),
            ],
            Icon(PhosphorIcons.caretDown(), color: c.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  void _showClientSelector(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sc = AppColors.of(sheetContext);
        return AppSheet.decoration(
          sheetContext,
          title: 'Müşteri Seç',
          child: SizedBox(
            height: screenHeight * 0.6,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: clients.length + 1,
              itemBuilder: (itemContext, index) {
                if (index == clients.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: AppButton(
                      onPressed: () {
                        Navigator.pop(itemContext);
                        onAddClient();
                      },
                      variant: ButtonVariant.solid,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'YENİ MÜŞTERİ EKLE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sc.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final client = clients[index];
                final isSelected = selectedClient?.id == client.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () {
                      Navigator.pop(itemContext);
                      onClientSelected(client);
                    },
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: client.name,
                          hexColor: client.color,
                          size: AvatarSize.sm,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            client.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 15,
                              color: sc.textMain,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                              color: sc.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
