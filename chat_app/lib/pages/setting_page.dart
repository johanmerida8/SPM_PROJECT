// import 'package:chat_app/pages/notification_provider.dart';
import 'package:chat_app/pages/delete_profile_page.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        margin: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode'),
                  CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context).isDarkMode, 
                    onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme()
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const DeleteProfile())
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(18),
                child: const Text('Delete Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}