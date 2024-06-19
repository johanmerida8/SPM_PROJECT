// import 'package:chat_app/pages/notification_provider.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/pages/delete_profile_page.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void setUserStatusOffline() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status': 'offline'});
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //sign out
  void signOut(BuildContext context) async {
    //get auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      setUserStatusOffline();

      authService.signOut();
      //sign out of google
      await _googleSignIn.signOut();

      // Navigate to the login page

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthGate()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

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
  void _updateLanguagePreference(String language) async {
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
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          lanNotifier.translate('birdyMate'),
          style: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 20,
          ),
        ),
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
                      onChanged: (value) =>
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme()),
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
                      Provider.of<LanguageNotifier>(context, listen: false)
                          .change(value!);
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
                    MaterialPageRoute(
                        builder: (context) => const DeleteProfile()));
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
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context, 
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(lanNotifier.translate('loggingOut')),
                      content: Text(lanNotifier.translate('logoutMsg')),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          }, 
                          child: Text(lanNotifier.translate('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            signOut(context);
                            Navigator.of(context).pop();
                          }, 
                          child: Text(lanNotifier.translate('logout')),
                        ),
                      ],
                    );
                  }
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(18),
                child: Text(lanNotifier.translate('logout')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
