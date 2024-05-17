import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/pages/home_page.dart';
import 'package:chat_app/pages/profile_page.dart';
import 'package:chat_app/pages/setting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';

class UserScreens extends StatefulWidget {
  const UserScreens({super.key});

  @override
  State<UserScreens> createState() => _UserScreensState();
}

class _UserScreensState extends State<UserScreens> {
  final User? user = FirebaseAuth.instance.currentUser; 
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomePage(receiverUserID: ''),
      ProfilePage(user: user),
      SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _screens[_selectedIndex],
            ),
            Container(
              color: Theme.of(context).colorScheme.background,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15.0, vertical: 12.0),
                child: GNav(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  color: Theme.of(context).colorScheme.onBackground,
                  activeColor: Theme.of(context).colorScheme.onBackground,
                  tabBackgroundColor: Theme.of(context).colorScheme.secondary,
                  gap: 8,
                  tabs: [
                    GButton(
                      icon: Icons.contact_page, 
                      text: lanNotifier.translate('contact'),
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GButton(
                      icon: Icons.person, 
                      text: lanNotifier.translate('profile'),
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GButton(
                      icon: Icons.settings, 
                      text: lanNotifier.translate('settings'),
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
