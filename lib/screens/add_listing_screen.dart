import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';

class AddListingScreen extends StatefulWidget {
  @override
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<File> _imageFiles = [];
  late String _title;
  late String _description;
  bool _isFree = true;
  bool _isUploading = false;

  void _showImageSourceDialog() async {
    showDialog(
        context: context,
        builder: (BuildContext? context) {
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
                    if (_imageFiles != null) {
                      Navigator.of(context!).pop();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    _takeImage();
                    if (_imageFiles != null) {
                      Navigator.of(context!).pop();
                    }
                  },
                ),
              ],
            ),
          );
        });
  }

  void _chooseImage() async {
    final picker = ImagePicker();
    final pickedImages =
    await picker.pickMultiImage(maxHeight: 1080, maxWidth: 1080);
    setState(() {
      if (pickedImages != null) {
        _imageFiles = pickedImages.map((pickedImage) {
          return File(pickedImage.path);
        }).toList();
      } else {
        print('No images selected.');
      }
    });
  }

  void _takeImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedImage != null) {
        _imageFiles.add(File(pickedImage.path));
      } else {
        print('No image taken.');
      }
    });
  }
  void _submitListing() async {
    if (_formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        _imageFiles.isNotEmpty) {
      _formKey.currentState!.save();

      setState(() {
        _isUploading = true;
      });

      // Upload image files to Firebase Storage
      List<String> imageDownloadUrls = [];
      try {
        for (File imageFile in _imageFiles) {
          String fileName = DateTime
              .now()
              .millisecondsSinceEpoch
              .toString();
          Reference storageReference = FirebaseStorage.instance.ref().child(
              'listing_images/$fileName');
          UploadTask uploadTask = storageReference.putFile(imageFile);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
          String imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();
          imageDownloadUrls.add(imageDownloadUrl);
        }
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
          'imageUrls': imageDownloadUrls,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Listing added successfully');
        setState(() {
          _isUploading = false;
        });
        // Handle success

        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context as BuildContext).pop();

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
        title: Text('Add Listing'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // const SizedBox(height: 16),
                // const Text('Upload Images'),
                // const SizedBox(height: 8),


                const SizedBox(height: 16),

                Row(
                  children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value!;
                    },
                  ),
                  ),
                    const SizedBox(width: 16),
                    ToggleButtons(
                      isSelected: [_isFree, !_isFree],
                      selectedColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey,
                      selectedBorderColor: Colors.blue,
                      onPressed: (int index) {
                        setState(() {
                          _isFree = index == 0;
                        });
                      },
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Free',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Trade',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                ],),




                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value!;
                  },
                ),
                const SizedBox(height: 16),
                // const Text('Give it away or trade it'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    ElevatedButton.icon(
                        onPressed: () {
                          _showImageSourceDialog();
                        },

                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add a Photo'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        )
                    ),

                    ElevatedButton.icon(
                      onPressed: _submitListing,
                      icon: _isUploading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                          : Icon(Icons.add),
                      label: Text('Add Listing'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        )
                    ),



                  ],
                ),



                // const SizedBox(height: 8),

                const SizedBox(height: 16),

                _imageFiles.isNotEmpty
                    ? GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: _imageFiles.map((imageFile) {
                    return Stack(
                      children: [
                        Image.file(imageFile),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _imageFiles.remove(imageFile);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

