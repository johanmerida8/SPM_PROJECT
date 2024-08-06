// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/components/chat_bubble.dart';
import 'package:chat_app/components/file_picker.dart';
import 'package:chat_app/components/message_options.dart';
import 'package:chat_app/components/my_textfield.dart';
import 'package:chat_app/components/typing_indicator.dart';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:chat_app/model/message.dart';
import 'package:chat_app/model/reactions.dart';
import 'package:chat_app/screens/profile_details_page.dart';
import 'package:chat_app/services/auth/chat_services/chat_service.dart';
import 'package:chat_app/services/auth/notification_services.dart/notification_service.dart';
import 'package:chat_app/theme/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

// import 'package:webview_flutter/webview_flutter.dart';

// import 'package:encrypt/encrypt.dart' as encrypt;

class ChatPage extends StatefulWidget {
  final String receiverUserName;
  final String receiverUserEmail;
  final String receiverUserID;
  const ChatPage({
    super.key,
    required this.receiverUserName,
    required this.receiverUserEmail,
    required this.receiverUserID,
    // required this.otherUserId,
    // required this.receiverUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _msgEditController = TextEditingController();
  // final TextEditingController _msgReplyController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore database = FirebaseFirestore.instance;

  //for textfield focus
  final FocusNode _focusNode = FocusNode();
  

  final List<Reaction> reactions = [
    Reaction(id: '1', emoji: '😍'),
    Reaction(id: '2', emoji: '😂'),
    Reaction(id: '3', emoji: '😢'),
    Reaction(id: '4', emoji: '😡'),
    Reaction(id: '5', emoji: '👍'),
    Reaction(id: '6', emoji: '👎'),
  ];

  bool hasReactions(Map<String, dynamic> data) {
  return data.containsKey('reactions') && data['reactions'] is Map<String, dynamic> && data['reactions'].isNotEmpty;
}

  @override
  void initState() {
    super.initState();

    _msgController.addListener(() { 
      isTypingNotifier.value = _msgController.text.isNotEmpty;
    });

    //call a method from chat service to reset the unread messages field for the current user
    _chatService.readMsg(widget.receiverUserID);

    //add listener to focus node
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // cause a delay so that the keyboard has time to show up
        // then the amount of remaining space will be calculated
        // then scroll down
        Future.delayed(const Duration(milliseconds: 600), () => scrollDown());
      }
    });

    // wait a bit for listview to be built, then scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () => scrollDown());
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _msgController.removeListener(() { });
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // scroll controller
  final ScrollController _scrollController = ScrollController();

  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void sendMsg(String message) async {
    //check if the _msgController is empty
    if (_msgController.text.isEmpty) {
      print('Message controller is empty. No message to send.');
      return;
    }

    final Timestamp messageSentTime = Timestamp.now();
    //only send message if there is something to send
    if (_msgController.text.isNotEmpty) {
      await _chatService.sendMsg(
          widget.receiverUserID, _msgController.text, MessageType.text, messageSentTime);

      // After sending the message, set 'typing' to false
      FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'typing': false,
      });

      //clear the text controller after sending the message
      _msgController.clear();
    }

    //scroll down after sending the message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollDown();
    });
  }

  //delete message
  void deleteMsg(String msg) async {
    // final lanNotifier = Provider.of<LanguageNotifier>(context);
    await _chatService.deleteMsg(context, widget.receiverUserID, msg);
  }

  //format the date to show the time if the message was sent today or yesterday, otherwise show the date
  String formatDate(Timestamp timestamp) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateFormat timeFormatter = DateFormat('HH:mm a');
    DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${lanNotifier.translate('today')} ${timeFormatter.format(date)}';
    } else if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return '${lanNotifier.translate('yesterday')} ${timeFormatter.format(date)}';
    } else {
      return '${dateFormatter.format(date)} ${timeFormatter.format(date)}';
    }
  }

  ValueNotifier<List<XFile>> pickedImagesNotifier = ValueNotifier<List<XFile>>([]);
  ValueNotifier<List<XFile>> pickedDocumentsNotifier = ValueNotifier<List<XFile>>([]);
  ValueNotifier<List<XFile>> pickedAudiosNotifier = ValueNotifier<List<XFile>>([]);
  ValueNotifier<Map<String, bool>> sendingStatesNotifier = ValueNotifier<Map<String, bool>>({});
  ValueNotifier<bool> isImageReceivedNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> isDocumentReceivedNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> isAudioReceivedNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> isTypingNotifier = ValueNotifier<bool>(false);

  
  AudioPlayer _audioPlayer = AudioPlayer();  
  AudioPlaybackNotifier _audioPlaybackNotifier = AudioPlaybackNotifier();
  bool isPlaying = false;
  String currentAudioUrl = '';  

  Future<void> toggleAudio(String audioUrl) async {
  if (isPlaying && currentAudioUrl == audioUrl) {
    await _audioPlayer.stop();
    Future.microtask(() => 
      setState(() {
        isPlaying = false;
      })
    );
  } else {
    await _audioPlayer.play(UrlSource(audioUrl));
    Future.microtask(() => 
      setState(() {
        isPlaying = true;
        currentAudioUrl = audioUrl;
      })
    );
    _audioPlayer.onPlayerComplete.listen((event) {
      Future.microtask(() => 
        setState(() {
          isPlaying = false;
        })
      );
    });
  }
}

//GET EMOJI
String getEmojiMsg(Map<String, dynamic> data, String userId) {
  // Check if the data contains reactions
  if (data.containsKey('reactions')) {
    // Get the reactions map
    var reactions = data['reactions'];
    // Check if the reactions map contains the user's ID
    if (reactions is Map<String, dynamic> && reactions.containsKey(userId)) {
      // Get the user's reaction
      var userReaction = reactions[userId];
      // Check if the user's reaction contains the emojiMsg field
      if (userReaction is Map<String, dynamic> && userReaction.containsKey('emojiMsg')) {
        // Get the emojiMsg field
        var emojiMsg = userReaction['emojiMsg'];
        // Check if the emojiMsg is a string
        if (emojiMsg is String) {
          // Return the emojiMsg
          return emojiMsg;
        }
      }
    }
  }
  // Return an empty string if the emojiMsg is not found
  return '';
}
  
  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              //status indicator if user is online or offline
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.receiverUserID)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    Map<String, dynamic> data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    String status = (data['status'] ?? 'offline').toLowerCase();
                    print('Status: $status');
                    Color statusColor =
                        status == 'online' ? Colors.green : Colors.grey;
                    
                    //future builder to fetch and display the profile image
                    
                    return FutureBuilder<String>(
                    future: _chatService.getImageUrl(data['uid']),
                    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                      Widget leadingWidget;
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        String imageUrl = snapshot.data!;
                        if (imageUrl.isNotEmpty) {
                          leadingWidget = CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl),
                            onBackgroundImageError: (exception, stackTrace) {
                              print('Error loading image: $exception');
                            },
                          );
                        } else {
                          leadingWidget = const CircleAvatar(child: Icon(Icons.person));
                        }
                      } else if (snapshot.hasError) {
                        print('Error getting image url: ${snapshot.error}');
                        leadingWidget = const CircleAvatar(child: Icon(Icons.person));
                      } else {
                        leadingWidget = const CircleAvatar(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileDetails(
                                receiverUserEmail: widget.receiverUserEmail,
                                receiverUserID: widget.receiverUserID,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Transform.translate(
                              offset: const Offset(-10.0, 0.0),
                              child: leadingWidget,
                            ),
                            
                            Text(
                              data['name'] ?? lanNotifier.translate('unknown'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8.0),
                            CircleAvatar(radius: 5, backgroundColor: statusColor),
                          ],
                        ),
                      );
                    },
                  );
                    
                  } else if (snapshot.hasError) {
                    return Text(lanNotifier.translate('error'));
                  } else {
                    return Text(lanNotifier.translate('loading'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          //message list
          Expanded(
            child: _buildMessageList(),
          ),
          //user input
          _buildMessageInput(),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

//build message list
  Widget _buildMessageList() {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return StreamBuilder(
      stream:
          _chatService.getMsg(widget.receiverUserID, _auth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(lanNotifier.translate('error'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(lanNotifier.translate('loading'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data?.docs.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

//build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    //align the messages to the right if the sender is the current user, otherwise align to the left
    var alignment = (data['senderId'] == _auth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    var bubbleColor = (data['senderId'] == _auth.currentUser!.uid)
        ? (isDarkMode ? Colors.green.shade600 : Colors.grey.shade600)
        : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300);

    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    return GestureDetector(
    onLongPress: () {
    //set the text of _msgController to the current message
    _msgEditController.text = data['message'];

    //show a dialog to delete and edit the message
    showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return MessageOptions(
              data: data, 
              document: document, 
              msgEditController: _msgEditController, 
              receiverUserID: widget.receiverUserID, 
              chatService: _chatService, 
              reactions: reactions, 
              hasReactions: hasReactions, 
              toggleAudio: toggleAudio, 
              isPlaying: isPlaying, 
              currentAudioUrl: currentAudioUrl, 
              setState: setState, 
              audioPlayer: _audioPlayer
            );
          }
        );
      },

      child: Container(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: (data['senderId'] == _auth.currentUser!.uid)
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisAlignment: (data['senderId'] == _auth.currentUser!.uid)
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ChatBubble(
              messageId: document.id,
              message: data['message'] ?? '',
              messageType: data['type'] ?? '',
              bubbleColor: bubbleColor,
              isDeleted: data['isDeleted'] ?? false,
              reactions: getEmojiMsg(data, _auth.currentUser!.uid),
              isSending: sendingStatesNotifier.value[data['message']] == true,
              msgEditController: _msgEditController,
              chatService: _chatService,
              audioPlayer: _audioPlayer,
              audioPlaybackNotifier: _audioPlaybackNotifier,
            ),

              

              //show the time the message was sent
              Text(
                formatDate(data['timestamp']),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
              //show if the message has been delivered or seen by the user
              if (data['senderId'] == _auth.currentUser!.uid)
                Text(
                  data['isRead'] == true
                      ? lanNotifier.translate('seen')
                      : lanNotifier.translate('delivered'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  //build message input
  Widget _buildMessageInput() {
    final lanNotifier = Provider.of<LanguageNotifier>(context, listen: false);
    String otherUserID = widget.receiverUserID;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserID)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return const SizedBox.shrink();
                } else if (snapshot.hasData && snapshot.data!.data() != null) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  if (!data.containsKey('typing')) {
                    print('Document does not contain typing field');
                    return const SizedBox.shrink();
                  }
                  bool isTyping = data['typing'] ?? false;
                  print('isTyping: $isTyping');
                  String name = data['name'] ?? '';
                  return isTyping
                      ? Column(
                          children: [
                            Text('$name ${lanNotifier.translate('typing')}'),
                            const SizedBox(height: 15),
                            TypingIndicator(isTyping: isTyping),
                          ],
                        )
                      : const SizedBox.shrink();
                } else {
                  print('Document does not exist or data is null');
                  return const SizedBox.shrink();
                }
              }),
          const SizedBox(height: 15),
          Row(
            children: [
              //text field
              Expanded(
                child: MyTextField(
                  controller: _msgController,
                  hintText: lanNotifier.translate('message'),
                  obscureText: false,
                  isEnabled: true,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({
                        'typing': true,
                      });
                    } else {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .update({
                        'typing': false,
                      });
                    }
                  },
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return FilePickerSheet(
                                onImagePicked: (file) async {
                                  pickedImagesNotifier.value.add(XFile(file.path));
                                  sendingStatesNotifier.value[file.path] = true;
                                  isImageReceivedNotifier.value = true;

                                  await _chatService.sendChatImage(otherUserID, file);
                                  sendingStatesNotifier.value[file.path] = false;
                                  sendingStatesNotifier.notifyListeners();

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    scrollDown();
                                  });
                                },
                                onDocumentPicked: (file) async {
                                  pickedDocumentsNotifier.value.add(XFile(file.path));
                                  sendingStatesNotifier.value[file.path] = true;
                                  isDocumentReceivedNotifier.value = true;

                                  await _chatService.sendChatDocument(otherUserID, file);
                                  sendingStatesNotifier.value[file.path] = false;
                                  sendingStatesNotifier.notifyListeners();

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    scrollDown();
                                  });
                                },
                                onAudioPicked: (file) async {
                                  pickedAudiosNotifier.value.add(XFile(file.path));
                                  sendingStatesNotifier.value[file.path] = true;
                                  isAudioReceivedNotifier.value = true;

                                  await _chatService.sendChatAudio(otherUserID, file);
                                  sendingStatesNotifier.value[file.path] = false;
                                  sendingStatesNotifier.notifyListeners();

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    scrollDown();
                                  });
                                },
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.attach_file,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                      // Camera icon button remains unchanged
                      IconButton(
                        onPressed: () async {
                          final XFile? img = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 70,
                          );
                          if (img != null) {
                            pickedImagesNotifier.value.add(img);
                            sendingStatesNotifier.value[img.path] = true;
                            isImageReceivedNotifier.value = true;

                            await _chatService.sendChatImage(otherUserID, File(img.path));
                            sendingStatesNotifier.value[img.path] = false;
                            sendingStatesNotifier.notifyListeners();

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              scrollDown();
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              //send button
              ValueListenableBuilder<bool>(
                valueListenable: isTypingNotifier,
                builder: (context, isTyping, child) {
                  return IconButton(
                    onPressed: () async {
                      if (_msgController.text.isNotEmpty) {
                        // The existing code for sending a message
                        String message = '';
                        DocumentSnapshot senderDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_auth.currentUser!.uid)
                            .get();
                        String senderName = senderDoc['name'] ?? 'Unknown';
                        message = '$senderName: ${_msgController.text}';
                        sendMsg(message);
                        String title = 'New message from $senderName';
                        DocumentSnapshot userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserID)
                            .get();
                        String token = userDoc['token'];
                        LocalNotificationService localNotificationService = LocalNotificationService();
                        localNotificationService.sendNotification(title, message, token);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          scrollDown();
                        });
                        _msgController.clear();
                      } else {
                        print('Message controller is empty. No message to send.');
                      }
                    },
                    icon: Icon(
                      Icons.send,
                      size: 30,
                      color: isTyping ? Colors.green : Colors.grey, // Color changes based on typing status
                    ),
                  );
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
