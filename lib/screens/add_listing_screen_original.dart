import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_trade_post_app/screens/listings_screen.dart';


class AddListingScreen extends StatefulWidget {
  @override
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    FirebaseAuth.instance.signInAnonymously();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File ? _imageFile;
  late String _title;
  late String _description;
  bool _isFree = true;
  bool _isUploading = false;

  void _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _chooseImage();
                  if (_imageFile != null) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _takeImage();
                  if (_imageFile != null) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          )
        );
      }
    );
  }

  void _chooseImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _imageFile = File(pickedImage.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void _takeImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedImage != null) {
        _imageFile = File(pickedImage.path);
      } else {
        print('No image taken.');
      }
    });
  }

  void _submitListing() async {
    if (_formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        _imageFile != null) {
      _formKey.currentState!.save();

      setState(() {
        _isUploading = true;
      });

      // Upload image file to Firebase Storage
      String imageDownloadUrl;
      try {
        String fileName = DateTime
            .now()
            .millisecondsSinceEpoch
            .toString();
        Reference storageReference = FirebaseStorage.instance.ref().child(
            'listing_images/$fileName');
        UploadTask uploadTask = storageReference.putFile(_imageFile!);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
        imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();
      } catch (e) {
        print('Error uploading image: $e');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Create a new document in the 'listings' collection in Cloud Firestore
      try {
        CollectionReference listingsCollection = FirebaseFirestore.instance
            .collection('listings');
        String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
        await listingsCollection.add({
          'userId': userId, // Include user ID in the document
          'title': _title,
          'description': _description,
          'isFree': _isFree,
          'imageUrl': imageDownloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Listing added successfully');
        setState(() {
          _isUploading = false;
        });
        // Handle success

        await Future.delayed(const Duration(seconds: 1));
        if (!context.mounted) return;
        Navigator.of(context).pop();
        // Navigator.pop(context);

      } catch (e) {
        print('Error adding listing: $e');

        setState(() {
          _isUploading = false;
        });
        // Handle error adding listing
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Listing'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Image box
                GestureDetector(
                  onTap: () => _showImageSourceDialog(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _imageFile == null
                        ? Icon(
                      Icons.add_a_photo,
                      size: 72,
                      color: Colors.grey[800],
                    )
                        : Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value==null) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) => _title = value!,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value==null) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Checkbox(
                      value: _isFree,
                      onChanged: (value) {
                        setState(() {
                          _isFree = value!;
                        });
                      },
                    ),
                    const Text('Free'),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isUploading ? null : _submitListing,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('Submit Listing'),
                  style: ElevatedButton.styleFrom(
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16.0),
                   ),
                    padding: const EdgeInsets.all(16.0),
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
