// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier{

  //build context
  // final BuildContext context;

  //constructor
  // AuthService({required this.context});
  
  //instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //sign in with google
  signInWithGoogle(BuildContext context) async {
    try {
      //start the sign in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();   

      if (gUser == null) {
        print('User cancelled the sign in process');
        return;
      }

      //get the authentication from the user
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      //get the credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      ); 

      //sign in using the credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      //get the user
      final User user = userCredential.user!;

      //get a reference to the user's document
      final DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
      
      //check if the users document already exists
      final DocumentSnapshot docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': DateTime.now(),
        }, 
          SetOptions(merge: true)
        );
      } else {
        //if the document does not exist, create a new document for the user
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
        }, 
          SetOptions(merge: true)
        );
      }

    } catch (e, s) {
      print("Error signing with google: $e");
      print("Stack trace: $s");
    }
  }

  //sign user in
  Future<UserCredential> signInWithEmailandPassword(String email, String password) async {
    try {
      //sign in
      UserCredential userCredential = 
      await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      //add a new document for the user in users collection if it doesn't already exist
      _firestore.collection('users').doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
          // 'name': name,

          //merge: true will update the existing document if it already exists
        }, SetOptions(merge: true),
      );

      return userCredential;
    } 
    //catch any errors
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //create a new user
  Future<UserCredential> signUpWithEmailandPassword(String name, String email, password) async {
    try {
      UserCredential userCredential = 
      await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // final User? user = userCredential.user;
      // await user?.updateDisplayName(name);

      //after creating the user, create a new document for the user in the users collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set(
        {
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'createdAt': DateTime.now(),
        }
      );

      return userCredential;
    }
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //sign user out
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }
}