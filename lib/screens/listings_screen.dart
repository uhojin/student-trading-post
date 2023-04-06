import 'package:flutter/material.dart';
import 'package:student_trade_post_app/screens/add_listing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_trade_post_app/screens/listing_details_screen.dart';

class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          List<QueryDocumentSnapshot> listings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (BuilderContext, int index) {
              // Extract listing data from snapshot
              String title = listings[index]['title'];
              String description = listings[index]['description'];
              bool isFree = listings[index]['isFree'];
              String imageUrl = listings[index]['imageUrl'];

              // Return a card widget for each listing
              return Card(
                child: ListTile(
                  leading: Image.network(imageUrl),
                  title: Text(title),
                  subtitle: Text(description),
                  trailing: isFree ? const Text('Free') : const Text('Trade'),
                  onTap: () {
                    // Navigate to Listing Details
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ListingDetailsScreen(
                        title: title,
                        description: description,
                        imageUrl: imageUrl,
                        documentId: listings[index].id,
                        userId: listings[index]['userId'],
                      )),
                    );
                  },
                )
              );
            }
          );
        }

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Listings
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddListingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
