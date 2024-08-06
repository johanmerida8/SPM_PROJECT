import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/services/auth/auth_gate.dart';
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

  @override
  void initState() {
    super.initState();
    checkAuthentication();
  }

  void checkAuthentication() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthGate()
          )
        );
      }
    });
  }

  Future<bool> deleteProfile(BuildContext context) async {
  final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);

  // Show the loading dialog
  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Dialog(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(lanNotifier.translate('loading')),
            ],
          ),
        ),
      );
    } 
  );

  //check if the user has entered their email
  if (emailController.text.isEmpty) {
    // Dismiss the loading dialog
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lanNotifier.translate('deleteEmailNull')),
        backgroundColor: Colors.red,
      ),
    );
    print('Please enter your email');
    return false;
  }

  //Get the current user from the authentication
  User? user = _auth.currentUser;

  //check if the entered email matches the current user's email
  if (user != null && user.email == emailController.text) {
    //get the user's uid
    String uid = user.uid;

    //delete the user's document from the users collection
    await _firestore.collection('users').doc(uid).delete();

    // Check if the user signed up with Google
    bool isGoogleUser = user.providerData.any((userInfo) => userInfo.providerId == 'google.com');

    if (isGoogleUser) {
      // Force a sign in with Google
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently(suppressErrors: false);
      if (googleUser != null) {
        OAuthCredential googleAuthCredential = GoogleAuthProvider.credential(
          accessToken: (await googleUser.authentication).accessToken,
          idToken: (await googleUser.authentication).idToken,
        );

        await user.reauthenticateWithCredential(googleAuthCredential);
      } else {
        // Dismiss the loading dialog
        Navigator.pop(context);

        print('No current Google user');
        return false;
      }
    }

    //delete the user's authentication account
    await user.delete().then((_) async {
      print('Profile deleted successfully');

      //sign out of authentication
      _auth.signOut();

      //sign out of google
      await _googleSignIn.signOut();

      //wait for the user to be signed out
      await Future.delayed(const Duration(seconds: 1));

      // Dismiss the loading dialog
      Navigator.pop(context);

      // Show the SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lanNotifier.translate('deletedProfileSuccess'),
            style: const TextStyle(
              color: Colors.black,
            ),
          ),
        ),
      );

      //authenticate page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthGate()
        ),
        (Route<dynamic> route) => false,
      );
    });
    return true;
  } else {
    //the entered email does not match the current user's email
    // Dismiss the loading dialog
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lanNotifier.translate('deleteEmailMatch')),
        backgroundColor: Colors.red,
      ),
    );
    print('The entered email does not match the current user\'s email');
    return false;
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
                  lanNotifier.translate('deleteText'),
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
                  onTap: () => deleteProfile(context),
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