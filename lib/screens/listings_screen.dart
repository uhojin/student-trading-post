import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appinio_swiper/appinio_swiper.dart';

import 'package:student_trade_post_app/screens/listing_details_screen.dart';
import 'package:student_trade_post_app/screens/add_listing_screen.dart';
import 'package:student_trade_post_app/screens/chatList.dart';
import 'package:student_trade_post_app/screens/favourites_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  _ListingsScreenState createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [    const ListingsScreen(),    const ChatList(),    const FavouritesScreen(),  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


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

            return AppinioSwiper(
              loop: true,
              cardsBuilder: (BuildContext context, int index) {
                // Extract listing data from snapshot
                String title = listings[index]['title'];
                String description = listings[index]['description'];
                bool isFree = listings[index]['isFree'];
                List<dynamic> imageUrls = listings[index]['imageUrls'];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailsScreen(
                          title: title,
                          description: description,
                          imageUrls: listings[index]['imageUrls'],
                          documentId: listings[index].id,
                          userId: listings[index]['userId'],
                          isFree: listings[index]['isFree'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    alignment: Alignment.center,
                    child: Card(

                      child: Column(

                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5, // Set a minimum height
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                imageUrls[0],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              // mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(

                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                const SizedBox(height: 16.0),
                                Text(
                                  description,
                                  style: const TextStyle(fontSize: 18.0),
                                  // overflow: TextOverflow.ellipsis,
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
