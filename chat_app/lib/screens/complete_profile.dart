import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/navigations/user_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompleteProfile extends StatefulWidget {
  const CompleteProfile({super.key});

  @override
  State<CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<CompleteProfile> {

  final nameController = TextEditingController();

  Future completeGoogleProfile(User user) async {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    print('completeGoogleProfile called');
    // await checkUserProfile(user);

    try {
      if (areFieldsEmpty()) {
        Navigator.pop(context);
        showErrorMsg(lanNotifier.translate('fillFields'));
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
          builder: (context) => const UserScreens(),
        )
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lanNotifier.translate('completedProfile')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      showErrorMsg(lanNotifier.translate('error') + e.toString());
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

                  const Icon(Icons.person, size: 80),

                  const SizedBox(height: 25),

                  Text(
                    lanNotifier.translate('completeProfile'),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  //name field
                  MyTextField(
                    controller: nameController, 
                    hintText: lanNotifier.translate('name'), 
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
                    text: lanNotifier.translate('saveProfile'),
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