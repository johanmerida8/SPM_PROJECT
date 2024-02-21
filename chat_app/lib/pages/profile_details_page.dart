// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileDetails extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  const ProfileDetails({
    super.key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  });

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {

  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  // Uint8List? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //profile picture
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('imageUser').doc(widget.receiverUserID).get(),
                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.hasData && !snapshot.data!.exists) {
                        print('Document does not exist');
                        return const Icon(
                          Icons.person, 
                          size: 50,
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                        String? imageUrl = data['imageUrl'] as String?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            //profile picture user
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.6), // make it circular
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.8, // adjust this value as needed
                                              height: MediaQuery.of(context).size.width * 0.8, // adjust this value as needed
                                              child: ClipOval(
                                                child: imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover) : const Icon(Icons.person, size: 50)
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                    child: imageUrl == null ? const Icon(Icons.person, size: 50) : null,

                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return const Text('loading');
                    },
                  ),

                  //user information
                  FutureBuilder<DocumentSnapshot>(
                    future: users.doc(widget.receiverUserID).get(),
                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.hasData && !snapshot.data!.exists) {
                        return const Text('Document does not exist');
                      }

                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                        // String? imageUrl = data['imageUrl'] as String?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 25),
                            Text(
                              'Name: ${data['name']}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Bio: ${data['bio'] ?? 'No bio'}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Email: ${data['email']}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      }

                      return const Text('loading');
                    },
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