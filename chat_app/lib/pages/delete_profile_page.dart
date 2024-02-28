import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/services/auth/login_or_register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class DeleteProfile extends StatefulWidget {
  const DeleteProfile({super.key});

  @override
  State<DeleteProfile> createState() => _DeleteProfileState();
}

class _DeleteProfileState extends State<DeleteProfile> {

  //instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  //controller for the email field
  final emailController = TextEditingController();

  deleteProfile() async {
    //Get the current user from the authentication
    User? user = _auth.currentUser;

    //check if the entered email matches the current user's email
    if (user != null && user.email == emailController.text) {
      //get the user's uid
      String uid = user.uid;

      //delete the user's document from the users collection
      await _firestore.collection('users').doc(uid).delete();

      //delete the user's authentication account
      await user.delete();

      print('Profile deleted successfully');

      //sign out of authentication
      _auth.signOut();

      //sign out of google
      await _googleSignIn.signOut();

      //navigate to the login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginOrRegister()
        )
      );
    } else {
      //the entered email does not match the current user's email
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The entered email does not match the current user\'s email'),
          backgroundColor: Colors.red,
        ),
      );
      print('The entered email does not match the current user\'s email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lanNotifier.translate('deleteProfile')),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              
                const Icon(Icons.delete, size: 80),

                const SizedBox(height: 25),

                Text(
                  'Enter your email to delete your profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 25),
                
                MyTextField(
                  controller: emailController, 
                  hintText: lanNotifier.translate('email'), 
                  obscureText: false, 
                  isEnabled: true,
                ),

                const SizedBox(height: 15),

                MyButton(
                  onTap: deleteProfile,
                  text: lanNotifier.translate('deleteProfile'),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}