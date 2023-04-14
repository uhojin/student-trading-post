import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_trade_post_app/screens/Chat.dart';

class ListingDetailsScreen extends StatefulWidget {



  final String title;
  final String description;
  final List<dynamic> imageUrls;
  final String documentId;
  final String userId;
  final bool isFree;

  const ListingDetailsScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.documentId,
    required this.userId,
    required this.isFree,
  }) : super (key: key);

  @override
  _ListingDetailsScreenState createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isFavorite= false;



  late int currentIndex;
  late String userId;
  late String title;
  late String description;
  late List<dynamic> imageUrls;
  late String documentId;
  late bool isFree;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    userId = widget.userId;
    title = widget.title;
    description = widget.description;
    imageUrls = widget.imageUrls;
    documentId = widget.documentId;
    isFree = widget.isFree;
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    DocumentSnapshot favoriteSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.userId)
        .collection('listings')
        .doc(widget.documentId)
        .get();
    setState(() {
      _isFavorite = favoriteSnapshot.exists;
    });
  }

  void _addToFavorites() {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.userId)
        .collection('listings')
        .doc(widget.documentId)
        .set({
      'addedAt': DateTime.now(),
    });
    setState(() {
      _isFavorite = true;
    });
  }

  void _removeFromFavorites() {
    FirebaseFirestore.instance
        .collection('favorites')
        .doc(widget.userId)
        .collection('listings')
        .doc(widget.documentId)
        .delete();
    setState(() {
      _isFavorite = false;
    });
  }


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
            SizedBox(
              // height: 300.0, // set the height of the image container
              height: MediaQuery.of(context).size.height * 0.5, // set height to 50% of device screen height

              child: PageView.builder(
                itemCount: imageUrls.length,
                controller: PageController(initialPage: currentIndex),
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    imageUrls[index],
                    fit: BoxFit.fitHeight,
                  );
                },
              ),
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
    if (_isFavorite) {
    _removeFromFavorites();
    } else {
    _addToFavorites();
    }
    },
    icon: _isFavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
    label: Text(_isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        )
    )
,


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
