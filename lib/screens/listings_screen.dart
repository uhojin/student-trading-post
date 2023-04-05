import 'package:flutter/material.dart';
import 'package:student_trade_post_app/screens/add_listing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => ListingDetailsScreen(listing: listings[index])),
                    // );
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
