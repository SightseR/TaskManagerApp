// lib/src/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:project_productivity/src/bloc/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeState.isDark,
                onChanged: (_) {
                  context.read<ThemeCubit>().toggleTheme();
                },
              );
            },
          ),
          // add other settings here...
        ],
      ),
    );
  }
}
