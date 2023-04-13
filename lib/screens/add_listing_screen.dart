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

  // void _submitListing() async {
  //   if (_formKey.currentState != null &&
  //       _formKey.currentState!.validate() &&
  //       _imageFiles.isNotEmpty) {
  //     _formKey.currentState!.save();
  //
  //     setState(() {
  //       _isUploading = true;
  //     });
  //
  //     // Upload image files to Firebase Storage
  //     List<String> imageDownloadUrls = [];
  //     try {
  //       for (var i = 0; i < _imageFiles.length; i++) {
  //         String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i'; // Add index to the filename to avoid duplicates
  //         Reference storageReference = FirebaseStorage.instance
  //             .ref()
  //             .child('listing_images/$fileName');
  //         UploadTask uploadTask = storageReference.putFile(_imageFiles[i]);
  //         TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
  //         String imageDownloadUrl = await taskSnapshot.ref.getDownloadURL();
  //         imageDownloadUrls.add(imageDownloadUrl);
  //       }
  //     } catch (e) {
  //       print('Error uploading images: $e');
  //       setState(() {
  //         _isUploading = false;
  //       });
  //       return;
  //     }
  //
  //     // Create a new document in the 'listings' collection in Cloud Firestore
  //     try {
  //       CollectionReference listingsCollection = FirebaseFirestore.instance
  //           .collection('listings');
  //       String userId = FirebaseAuth.instance.currentUser!.uid; // Get current user ID
  //       await listingsCollection.add({
  //         'userId': userId, // Include user ID in the document
  //         'title': _title,
  //         'description': _description,
  //         'isFree': _isFree,
  //         'imageUrls': imageDownloadUrls,
  //         'timestamp': FieldValue.serverTimestamp(),
  //       });
  //       print('Listing added successfully');
  //       setState(() {
  //         _isUploading = false;
  //       });
  //       // Handle success
  //
  //       await Future.delayed(const Duration(seconds: 1));
  //       if (!context.mounted) return;
  //       Navigator.of(context as BuildContext).pop();
  //     } catch (e) {
  //       print('Error adding listing: $e');
  //
  //       setState(() {
  //         _isUploading = false;
  //       });
  //       // Handle error adding listing
  //     }
  //   }
  // }

  Future<List<String>> _uploadImagesToStorage() async {
    List<String> imageUrls = [];
    FirebaseStorage storage = FirebaseStorage.instance;
    for (var imageFile in _imageFiles) {
      String fileName = path.basename(imageFile.path);
      Reference ref = storage.ref().child('images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }
    return imageUrls;
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
                TextFormField(
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
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
                SizedBox(height: 16),
                Text('Price'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('Free'),
                        value: true,
                        groupValue: _isFree,
                        onChanged: (bool? value) {
                          setState(() {
                            _isFree = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('Paid'),
                        value: false,
                        groupValue: _isFree,
                        onChanged: (bool? value) {
                          setState(() {
                            _isFree = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Upload Images'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _showImageSourceDialog();
                  },
                  child: Text('Choose Images'),
                ),
                SizedBox(height: 8),
                _imageFiles.isNotEmpty
                    ? GridView.count(
                  physics: NeverScrollableScrollPhysics(),
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
                            icon: Icon(Icons.close),
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
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitListing,
                  child: _isUploading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : Text('Add Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


// @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Add Listing'),
  //     ),
  //     body: SingleChildScrollView(
  //       child: Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             ElevatedButton.icon(
  //               onPressed: _showImageSourceDialog,
  //               icon: const Icon(Icons.camera_alt),
  //               label: const Text('Add Image'),
  //             ),
  //             SizedBox(height: 16.0),
  //             GridView.count(
  //               crossAxisCount: 3,
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               children: _imageFiles
  //                   .map(
  //                     (image) => Stack(
  //                   children: [
  //                     Image.network(
  //                       image as String,
  //                       fit: BoxFit.cover,
  //                       height: 100.0,
  //                     ),
  //                     Positioned(
  //                       top: 0.0,
  //                       right: 0.0,
  //                       child: IconButton(
  //                         icon: const Icon(Icons.close),
  //                         onPressed: () => setState(() => _imageFiles.remove(image)),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               )
  //                   .toList(),
  //             ),
  //             SizedBox(height: 16.0),
  //             TextFormField(
  //               decoration: InputDecoration(
  //                 labelText: 'Title',
  //                 border: OutlineInputBorder(),
  //               ),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Please enter a title';
  //                 }
  //                 return null;
  //               },
  //               onChanged: (value) => setState(() => _title = value),
  //             ),
  //             SizedBox(height: 16.0),
  //             TextFormField(
  //               maxLines: null,
  //               decoration: InputDecoration(
  //                 labelText: 'Description',
  //                 border: OutlineInputBorder(),
  //               ),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return 'Please enter a description';
  //                 }
  //                 return null;
  //               },
  //               onChanged: (value) => setState(() => _description = value),
  //             ),
  //             SizedBox(height: 16.0),
  //             CheckboxListTile(
  //               title: const Text('Is Free'),
  //               value: _isFree,
  //               onChanged: (value) => setState(() => _isFree = value ?? false),
  //             ),
  //             SizedBox(height: 16.0),
  //             ElevatedButton(
  //               onPressed: _submitListing,
  //               child: const Text('Add Listing'),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }


}

