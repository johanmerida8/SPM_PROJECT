import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  State<CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {

  final nameController = TextEditingController();

  Future completeGoogleProfile(User user) async {
    print('completeGoogleProfile called');
    // await checkUserProfile(user);

    try {
      if (areFieldsEmpty()) {
        Navigator.pop(context);
        showErrorMsg('Please fill in all fields');
        return;
      }

      await createGoogleDoc(
        user, 
        nameController.text
      );

      // Navigator.pop(context);
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(
          builder: (context) => const HomePage()
        )
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      showErrorMsg('An error occurred, please try again: $e');
    }
  }

  final CollectionReference _user =
      FirebaseFirestore.instance.collection('users');

  Future createGoogleDoc(User user, String name) async {
    try {
      await _user.doc(user.uid).set({
        'name': name
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  bool areFieldsEmpty() {
    return nameController.text.isEmpty;
  }

  void showErrorMsg(String errorMsg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: const TextStyle(
              color: Colors.white,
            )
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  const Icon(Icons.person, size: 80),

                  const SizedBox(height: 25),

                  const Text(
                    'Complete profile',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  //name field
                  MyTextField(
                    controller: nameController, 
                    hintText: 'Name', 
                    obscureText: false, 
                    isEnabled: true,
                  ),

                  const SizedBox(height: 15),

                  //complete profile button

                  MyButton(
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await completeGoogleProfile(user);
                      } else {
                        print('User is null');
                      }
                    }, 
                    text: 'Save profile',
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