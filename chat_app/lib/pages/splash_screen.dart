import 'dart:async';

import 'package:chat_app/services/auth/auth_gate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin{

  bool isLoading = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) { 
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthGate(),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo5.png',
              width: 300,
              height: 300,
            ),
            // const SizedBox(height: 20),
            // const Text(
            //   'Birdy Mate',
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //     fontSize: 40,
            //   ),
            // ),
            const SizedBox(height: 50),
            isLoading 
              ? const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 18,
                ) : Container(),
          ],
        ),
      ),
    );
  }
}