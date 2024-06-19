import 'package:chat_app/navigations/user_screens.dart';
import 'package:chat_app/services/auth/login_or_register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//check if we are logged in or not

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user is logged in
          if(snapshot.hasData) {
            return const UserScreens();
          }

          //user is not logged in
          else {
            return const LoginOrRegister();
          }
        }
      ),
    );
  }
}