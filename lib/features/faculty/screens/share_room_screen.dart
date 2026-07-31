import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Simple screen to display and copy a shareable room link, and quick share options.
class ShareRoomScreen extends StatelessWidget {
  const ShareRoomScreen({super.key});

  /// Builds the UI for sharing a room link and methods.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Room'),
        backgroundColor: AppColors.navyBrand,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share Room Link', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text('https://library.app/room/BSN1A'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.navyBrand),
                  onPressed: () {},
                  child: const Text('Copy Link'),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Share via', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ShareButton(icon: Icons.qr_code, label: 'QR Code'),
                  const SizedBox(width: 12),
                  _ShareButton(icon: Icons.email_outlined, label: 'Email'),
                  const SizedBox(width: 12),
                  _ShareButton(icon: Icons.message_outlined, label: 'Messenger'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ShareButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
