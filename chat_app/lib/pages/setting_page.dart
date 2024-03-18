// import 'package:chat_app/pages/notification_provider.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/pages/delete_profile_page.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  void initState() {
    super.initState();
    //load the selected language
    _loadLanguagePreference();
  }

  void _loadLanguagePreference() async {
    //shared preference to get the selected language
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //get the selected language from shared preference or default to 'es'
    String language = prefs.getString('language') ?? 'es';
    setState(() {
      _selectedLanguage = language;
    });
  }

  //method to update the selected language
  void _updateLanguagePreference (String language) async {
    //shared preference to store the selected language
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  //variable to store the selected language and default to 'es'
  String _selectedLanguage = 'es';

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(lanNotifier.translate('settings')),
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
                  Text(lanNotifier.translate('darkMode')),
                  CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context).isDarkMode, 
                    onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme()
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lanNotifier.translate('language')),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: ['en', 'es', 'pt'].map((String value) {
                      return DropdownMenuItem<String>(
                        child: Text(value),
                        value: value,
                      );
                    }).toList(), 
                    onChanged: (value) {
                      Provider.of<LanguageNotifier>(context, listen: false).change(value!);
                      _updateLanguagePreference(value);
                    },
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
                child: Text(lanNotifier.translate('deleteProfile')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}