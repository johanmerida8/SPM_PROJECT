import 'package:chat_app/pages/profile_page.dart';
import 'package:chat_app/pages/setting_page.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:chat_app/services/auth/login_or_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class MenuSideBar extends StatefulWidget {
  const MenuSideBar({super.key});

  @override
  State<MenuSideBar> createState() => _MenuSideBarState();
}

class _MenuSideBarState extends State<MenuSideBar> {
  
  final User? user = FirebaseAuth.instance.currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void setUserStatusOffline() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({'status': 'offline'});
  }
}
  
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
        MaterialPageRoute(
          builder: (context) => const LoginOrRegister()
        )
      );
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
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
            ),
            child: Text(
              //show logged in user's email
              'Logged in as: ${FirebaseAuth.instance.currentUser!.email}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.contact_page),
            title: const Text('Contacts'),
            onTap: () {
              //navigate to the contacts page
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              //navigate to the profile page
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  ProfilePage(user: user!)
                )
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              //navigate to the settings page
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage()
                )
              );
            },
          ),
          const SizedBox(height: 100),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              signOut(context);
            },
          ),
        ],
      ),
    );
  }
}
