// ignore_for_file: unused_field

import 'dart:typed_data';

import 'package:chat_app/components/my_button.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/resources/image_data.dart';
import 'package:chat_app/resources/network_helper.dart';
import 'package:chat_app/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  // final String receiverUserID;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final emailController = TextEditingController();

  final CollectionReference _user =
      FirebaseFirestore.instance.collection('users');

  Future<void> _fetchData() async {
    try {
      //get the user
      if (widget.user != null) {
        //get the document
        final DocumentSnapshot docSnapshot = await _user.doc(widget.user!.uid).get();
        //check if the document exists
        if (docSnapshot.exists) {
          //get data from the document
          final data = docSnapshot.data() as Map<String, dynamic>;
          nameController.text = data['name'];
          bioController.text = data['bio'] ?? '';
          emailController.text = data['email'];

          //load the profile image
          await loadProfileImg(widget.user!.uid);
        } else {
          print('Document does not exist on the database');
        }
      } else {
        print('User is null');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<bool> saveInfo(String userId, String name, String bio) async {
    try {
      final DocumentReference userDoc = _user.doc(userId);
      //update the contact document
      // final DocumentReference contactDoc = _user.doc(userId).collection('contacts').doc(userId);

      //check if the data has been modified
      final DocumentSnapshot docSnapshot = await userDoc.get();
      print('docSnapshot: ${docSnapshot.data()}');
      print('name: $name');
      print('bio: $bio');
      final Map<String, dynamic> currentValues = docSnapshot.data() as Map<String, dynamic>;
      print('currentValues: $currentValues');

      if (currentValues['name'] == name && currentValues['bio'] == bio) {
        print('Data has not been modified');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data has not been modified'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      } else {
        //save the data
        await userDoc.update({
          'name': name,
          'bio': bio,
        });
        
        //update the contact document in all users who you as a contact
        final QuerySnapshot contactDocs = await FirebaseFirestore.instance
          .collectionGroup('contacts')
          .where('uid', isEqualTo: userId)
          .get();

        for (final DocumentSnapshot doc in contactDocs.docs) {
          await doc.reference.update({
            'name': name,
          });
        }

        //show snackbar of success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully updated data'),
            backgroundColor: Colors.green,
          ),
        );

        print('Data has been modified');
        return true;
      }
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String? imageUrl;
  Uint8List? _image;

  Future<void> loadProfileImg(String userId) async {
    try {
      final imageSnapshot = await FirebaseFirestore.instance
          .collection('imageUser')
          .doc(userId)
          .get();
        if (imageSnapshot.exists) {
          final imageUrl = imageSnapshot['imageUrl'];

          if (imageUrl != null) {
            final image = await NetworkHelper.loadImg(imageUrl);
            setState(() {
              _image = image;
            });
          }
        }
      } catch (e) {
        print('Error loading the profile image: $e');
      }
    }


    void selectedImgProfile() async {
      //pick image from gallery
      Uint8List? img = await pickImage(ImageSource.gallery);
      //check if the image is not null
      if (img != null) {
        //compresses the picked image
        final Uint8List compressedImg = await FlutterImageCompress.compressWithList(
          img,
          minWidth: 500,
          minHeight: 500,
          quality: 80,
        );  
        //updates the image state with the compressed image
        setState(() {
          _image = compressedImg;
        });
        //shows the save dialog
        showSaveDialog(context);
      } else {
        //if the image is null, show a message
        print('The user did not select an image');
      }
    }

  void saveProfileImg() async {
    try {
      if (_image != null && widget.user != null) {
        final StoreData storeData = StoreData();
        final String res = await storeData.saveData(
          file: _image!, 
          userId: widget.user!.uid
        );
        print(res);
      } else {
        print('Image is null');
      }
    } catch (e) {
      print('Error saving profile image: $e');
    }
  }

  // void deleteProfileImg() async {
  //   try {
  //     //get the user
  //     if (widget.user != null) {
  //       //get the document
  //       DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
  //         .collection('imageUser')
  //         .doc(widget.user!.uid)
  //         .get();

  //         //get the image path
  //         String imagePath = docSnapshot['imageUrl'];
          
  //         //delete image from storage
  //         await StoreData().deleteImage(imagePath);

  //         //delete image from firestore
  //         await FirebaseFirestore.instance
  //           .collection('imageUser')
  //           .doc(widget.user!.uid)
  //           .delete();
          
  //         //set the image to null
  //         setState(() {
  //           _image = null;
  //         });
  //     } else {
  //       print('User is null');
  //     }
  //   } catch (e) {
  //     print('Error deleting profile image: $e');
  //   }
  // }

  void showSaveDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Save'),
          content: const Text('Do you want to save the changes?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              }, 
              child: const Text('No')
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                saveProfileImg();
              }, 
              child: const Text('Yes')
            ),
          ],
        );
      }
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      //safe area is used to avoid the notch and the camera hole
      body: SafeArea(
        //single child scroll view is used to avoid overflow
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  //profile picture
                  Stack(
                  children: [
                    GestureDetector(
                      // onLongPress: () {
                      //   if (_image != null) {
                      //     showDialog(
                      //       context: context,
                      //       builder: (BuildContext context) {
                      //         return AlertDialog(
                      //           title: const Text('Delete'),
                      //           content: const Text('Do you want to delete the profile image?'),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.pop(context);
                      //               }, 
                      //               child: const Text('No')
                      //             ),
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.pop(context);
                      //                 deleteProfileImg();
                      //               }, 
                      //               child: const Text('Yes')
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     );
                      //   }
                      // },
                      onTap: () {
                        if (_image != null) {
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
                                      child: Image.memory(_image!, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: _image != null
                        ? ClipOval(
                            child: Image.memory(
                              _image!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Positioned(
                        child: IconButton(
                          onPressed: selectedImgProfile,
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.black,
                          ),
                        ),
                        bottom: -10,
                        left: 45,
                      ),
                    ],
                  ),

                  FutureBuilder(
                    future: null, 
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Column(
                          children: [
                            const SizedBox(height: 25),
                  
                            //editable
                            //name textfield
                            MyTextField(
                              controller: nameController,
                              hintText: 'Name',
                              obscureText: false,
                              isEnabled: true,
                            ),

                            const SizedBox(height: 15),

                            //editable
                            //bio textfield
                            MyTextField(
                              controller: bioController,
                              hintText: 'Bio',
                              obscureText: false,
                              isEnabled: true,
                            ),

                            const SizedBox(height: 15),

                            //non editable email textfield
                            //email textfield
                            MyTextField(
                              controller: emailController,
                              hintText: 'Email',
                              obscureText: false,
                              isEnabled: false,
                            ),

                            const SizedBox(height: 25),

                            //save button
                            MyButton(
                              onTap: () async {
                                try {
                                  showDialog(
                                    context: context, 
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context).colorScheme.background,
                                        ),
                                      );
                                    }
                                  );
                                  await saveInfo(
                                    widget.user!.uid, 
                                    nameController.text, 
                                    bioController.text
                                  );
                                } catch (e) {
                                  print('Error saving data: $e');
                                } finally {
                                  Navigator.pop(context);
                                }
                              },
                              text: 'Save',
                            ),
                          ],
                        );
                      }
                    }
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}