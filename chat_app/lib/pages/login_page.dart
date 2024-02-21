// ignore_for_file: use_build_context_synchronously

import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/components/square_tile.dart';
import 'package:chat_app/pages/home_page.dart';
import 'package:chat_app/pages/reset_password.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editing controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

  // sign in user
  void signIn() async {
    //get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    //Show a SnackBar with a circular progress indicator while signing in
      const snackBar = SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Signing in...'),
          ],
        ),
        duration: Duration(seconds: 3),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

    try {
      UserCredential userCredential = await authService.signInWithEmailandPassword(
        emailController.text, 
        passwordController.text
      );
      User? user = userCredential.user;
      //check if the email is verified
      print('Email is verified: ${user?.emailVerified}');

      //set user status to online
      setUserStatusOnline();

      //Navigate to the contacts page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _authService = AuthService(context: context);
  // }

  // AuthService? _authService;

  // void handleSignIn() async {
  //   bool signInSuccessful = await _authService?.signInWithGoogle();
  //   if (signInSuccessful) {
  //     Navigator.push(
  //       context, 
  //       MaterialPageRoute(builder: (context) => const HomePage())
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Sign in failed'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

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
                  //logo
                  const Icon(Icons.message, size: 80),
        
                  const SizedBox(height: 25),
                  //welcome back message
                  const Text(
                    'Welcome back you\'ve been missed!',
                    style: TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold
                    ),
                  ),
        
                  const SizedBox(height: 25),
                  //email textfield
                  MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                      isEnabled: true
                  ),
        
                  const SizedBox(height: 15),
                  //password textfield
                  MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      isEnabled: true
                  ),
        
                  const SizedBox(height: 15),

                  //reset password
                  
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) {
                                return const ResetPassword();
                              })
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  

                  const SizedBox(height: 25),
        
                  //sign in button
                  MyButton(
                    onTap: signIn, 
                    text: 'Sign In'
                  ),
        
                  const SizedBox(height: 50),

                  //or continue with

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  //google sign in button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //google icon
                      SquareTile(
                        imgPath: 'assets/images/google.png', 
                        // onTap: handleSignIn,
                        onTap: () => AuthService().signInWithGoogle(context),
                      )
                    ],
                  ),

                  const SizedBox(height: 50),
        
                  //not a member? register now
        
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Not a member?'),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                          'Register now',
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
