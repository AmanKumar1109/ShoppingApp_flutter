import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../utils/festival_date_helper.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Festival Themes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE4F7A6),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose Active App Theme:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF152C1E)),
          ),
          const SizedBox(height: 12),
          _buildThemeTile(
            context,
            type: FestivalType.defaultTheme,
            title: 'Default Fresh Grocery',
            subtitle: 'Lime & Forest Green',
            color: const Color(0xFF0D4828),
            provider: theme,
          ),
          _buildThemeTile(
            context,
            type: FestivalType.diwali,
            title: 'Diwali Theme',
            subtitle: 'Warm Golden Saffron & Festive Lights',
            color: const Color(0xFFD97706),
            provider: theme,
          ),
          _buildThemeTile(
            context,
            type: FestivalType.holi,
            title: 'Holi Theme',
            subtitle: 'Vibrant Gulal Colors & Celebration',
            color: const Color(0xFFDB2777),
            provider: theme,
          ),
          _buildThemeTile(
            context,
            type: FestivalType.durgaPuja,
            title: 'Durga Puja Theme',
            subtitle: 'Royal Crimson & Golden Touch',
            color: const Color(0xFFDC2626),
            provider: theme,
          ),
          _buildThemeTile(
            context,
            type: FestivalType.christmas,
            title: 'Christmas Theme',
            subtitle: 'Emerald Green & Festive Red',
            color: const Color(0xFF15803D),
            provider: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required FestivalType type,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeProvider provider,
  }) {
    final isSelected = provider.currentThemeType == type;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 14),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () {
          provider.setTheme(type);
        },
      ),
    );
  }
}
