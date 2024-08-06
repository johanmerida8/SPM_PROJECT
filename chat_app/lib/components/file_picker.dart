import 'dart:io';
import 'package:chat_app/language/locale_notifier.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';


class FilePickerSheet extends StatelessWidget {
  final Function(File) onImagePicked;
  final Function(File) onDocumentPicked;
  final Function(File) onAudioPicked;

  const FilePickerSheet({
    Key? key,
    required this.onImagePicked,
    required this.onDocumentPicked,
    required this.onAudioPicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lanNotifier = Provider.of<LanguageNotifier>(context);
    return SafeArea(
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(lanNotifier.translate('selectImage')),
            onTap: () async {
              Navigator.pop(context); // Close the modal
              final List<XFile> imgs = await ImagePicker().pickMultiImage(imageQuality: 70);
              if (imgs.isEmpty) return;
              for (var img in imgs) {
                onImagePicked(File(img.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(lanNotifier.translate('selectDocument')),
            onTap: () async {
              Navigator.pop(context); // Close the modal
              final res = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx'],
              );
              if (res == null) return;

              final File file = File(res.files.single.path!);
              onDocumentPicked(file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.audio_file),
            title: Text(lanNotifier.translate('selectAudio')),
            onTap: () async {
              Navigator.pop(context); // Close the modal
              final res = await FilePicker.platform.pickFiles(
                type: FileType.audio,
              );
              if (res == null) return;

              final File file = File(res.files.single.path!);
              onAudioPicked(file);
            },
          ),
        ],
      ),
    );
  }
}
