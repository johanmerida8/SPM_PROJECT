// ignore_for_file: use_build_context_synchronously

import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/navigations/user_screens.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //text editing controller
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;

  void setUserStatusOnline() async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({'status': 'online'});
  }
}

  // sign up user
  void signUp() async {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lanNotifier.translate('passwordNotMatch')),
        ),
      );
      return;
    }

    //get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    // Show a SnackBar with a circular progress indicator while signing up
     final snackBar = SnackBar(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text(lanNotifier.translate('signingup')),
        ],
      ),
      duration: Duration(seconds: 5),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    try {
      UserCredential userCredential = await authService.signUpWithEmailandPassword(
          nameController.text,
          emailController.text, 
          passwordController.text
        );

        //send verification email
        await userCredential.user!.sendEmailVerification();

        // show snackbar to inform user to verify email
        if (mounted) {
          ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(lanNotifier.translate('verifyEmail')),
              backgroundColor: Color.fromRGBO(255, 152, 0, 1),
              duration: Duration(seconds: 8),
            ),
          );
        }

        //message to verify user's email
        print('Email verification sent to ${userCredential.user!.email}');

        if (mounted) {
          ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(lanNotifier.translate('accountCreated')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        //set user status to online
        setUserStatusOnline();

        //Navigate to the user screens
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const UserScreens(),
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  //logo
                  const Icon(Icons.person, size: 80),

                  const SizedBox(height: 25),
                  //create account message
                  Text(
                    lanNotifier.translate('createAccount'),
                    style: TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold
                    ),
                  ),

                  const SizedBox(height: 25),

                  //name textfield
                  MyTextField(
                      controller: nameController,
                      hintText: lanNotifier.translate('name'),
                      obscureText: false,
                      isEnabled: true,
                  ),

                  const SizedBox(height: 15),

                  //email textfield
                  MyTextField(
                      controller: emailController,
                      hintText: lanNotifier.translate('email'),
                      obscureText: false,
                      isEnabled: true,
                  ),

                  const SizedBox(height: 15),
                  //password textfield
                  MyTextField(
                      controller: passwordController,
                      hintText: lanNotifier.translate('password'),
                      obscureText: true,
                      isEnabled: true,
                  ),

                  const SizedBox(height: 15),
                  //confirm password textfield
                  MyTextField(
                      controller: confirmController,
                      hintText: lanNotifier.translate('confirmPassword'),
                      obscureText: true,
                      isEnabled: true,
                  ),

                  const SizedBox(height: 25),

                  //sign in button
                  MyButton(
                    onTap: signUp, 
                    text: lanNotifier.translate('signup')
                  ),

                  const SizedBox(height: 50),

                  //not a member? register now

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(lanNotifier.translate('notMember')),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          lanNotifier.translate('login'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
