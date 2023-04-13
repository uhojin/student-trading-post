import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_trade_post_app/screens/Chat.dart';


class ListingDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String documentId;
  final String userId;

  ListingDetailsScreen({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.documentId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    bool isCurrentUserListingOwner = userId == FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                if (!isCurrentUserListingOwner)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle contact seller button tap
                          Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(otherId: userId)));
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        )
                    ),
                  ),
                const SizedBox(height: 16.0,),
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle report listing button tap
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Report'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    )
                ),
                const SizedBox(height: 16.0,),

                ElevatedButton.icon(
                  onPressed: () {
                    // Handle favourite button tap
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favourite'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    )
                ),
                const SizedBox(height: 16.0,),
                if (isCurrentUserListingOwner)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Delete the listing
                        FirebaseFirestore.instance
                            .collection('listings')
                            .doc(documentId)
                            .delete()
                            .then((value) => Navigator.pop(context))
                            .catchError((error) => print('Error deleting listing: $error'));
                      },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Listing'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
