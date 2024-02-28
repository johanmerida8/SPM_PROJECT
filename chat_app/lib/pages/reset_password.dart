// ignore_for_file: use_build_context_synchronously

import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      //first check if the email is valid
      //attempt to send a password reset email to the user
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text);

      //second check if the email exists in Firestore
      //where is used to query the database
      var querySnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: emailController.text).get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent!'),
          ),
        );
      } else {
        //if the email does not exist, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('There is no user with this email.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The email address is not valid.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again later.'),
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

                    const Icon(Icons.password, size: 80),

                    const SizedBox(height: 25),

                    Text(
                      lanNotifier.translate('resetPassword'),
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 25),

                    //email field

                    MyTextField(
                      controller: emailController,
                      hintText: lanNotifier.translate('email'),
                      obscureText: false,
                      isEnabled: true,
                    ),

                    const SizedBox(height: 15),

                    //reset password button

                    MyButton(onTap: passwordReset, 
                      text: lanNotifier.translate('send')
                    ),

                    const SizedBox(height: 15),

                    //back to login button

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                      lanNotifier.translate('backToLogin'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
