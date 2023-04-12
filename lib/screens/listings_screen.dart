import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:student_trade_post_app/screens/add_listing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_trade_post_app/screens/listing_details_screen.dart';
import 'package:appinio_swiper/appinio_swiper.dart';

// import 'add_listing_screen_original.dart';


class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),

        title: const Text('Listings',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
            // fontSize: 36,
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

            return AppinioSwiper(loop: true, cardsBuilder: (BuildContext context, int index) {
// Extract listing data from snapshot
              String title = listings[index]['title'];
              String description = listings[index]['description'];
              bool isFree = listings[index]['isFree'];
              String imageUrl = listings[index]['imageUrl'];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingDetailsScreen(
                        title: title,
                        description: description,
                        imageUrl: imageUrl,
                        documentId: listings[index].id,
                        userId: listings[index]['userId'],
                      ),
                    ),
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  child: Card(
                    child: Column(
                      children: [
                        Padding(padding: const EdgeInsets.all(8),
                          child: Image.network(
                            listings[index]['imageUrl'],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listings[index]['title'],
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                listings[index]['description'],
                                style: const TextStyle(fontSize: 18.0),
                                // overflow: TextOverflow.ellipsis,
                              ),
                              isFree
                                                    ? const Text(
                                                  'Free',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                    : const Text(
                                                  'Trade',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

            }, cardsCount: listings.length,);

          }

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Listings
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddListingScreen()),
            // MaterialPageRoute(builder: (context) => UploadListingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
