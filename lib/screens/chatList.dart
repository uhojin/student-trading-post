import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_trade_post_app/screens/Chat.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  // Future<List<Map<String, dynamic>>> getMessagesWithUser(String userId) async {
  //   QuerySnapshot<Map<String, dynamic>> messagesSnapshot = await firestore
  //       .collection('messages')
  //       .where('idFrom', isEqualTo: userId)
  //       .get();
  //
  //   List<Map<String, dynamic>> messages = messagesSnapshot.docs
  //       .map((doc) => doc.data()..['id'] = doc.id)
  //       .toList();
  //
  //   List uniqueUserIds = messages.map((message) => message['idTo']).toSet().toList();
  //   QuerySnapshot<Map<String, dynamic>> usersSnapshot = await firestore
  //       .collection('users')
  //       .where('userId', whereIn: uniqueUserIds)
  //       .get();
  //
  //   Map<String, dynamic> usersMap = {};
  //   for (var userDoc in usersSnapshot.docs) {
  //     usersMap[userDoc.data()['userId']] = userDoc.data();
  //   }
  //
  //   for (var message in messages) {
  //     message['user'] = usersMap[message['idTo']];
  //   }
  //
  //   return messages;
  // }

  Future<List<Map<String, dynamic>>> getMessagesWithUser(String userId) async {
    QuerySnapshot<Map<String, dynamic>> messagesSnapshot = await firestore
        .collection('messages')
        .where('idFrom', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> messages = messagesSnapshot.docs
        .map((doc) => doc.data()..['id'] = doc.id)
        .toList();

    // Get messages where the user is the recipient
    QuerySnapshot<Map<String, dynamic>> recipientMessagesSnapshot = await firestore
        .collection('messages')
        .where('idTo', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> recipientMessages = recipientMessagesSnapshot.docs
        .map((doc) => doc.data()..['id'] = doc.id)
        .toList();

    // Combine the two lists of messages
    messages.addAll(recipientMessages);

    return messages;
  }


  Future<List<Map<String, dynamic>>> getListingsWithMessageHistory(String userId) async {
    List<Map<String, dynamic>> messages = await getMessagesWithUser(userId);
    print('Messages: $messages');

    List uniqueListingIds = messages
        .map((message) => message['idTo'])
        .toSet()
        .toList();
    print('Unique Listing IDs: $uniqueListingIds');

    List<Map<String, dynamic>> listings = [];
    for (String listingId in uniqueListingIds) {
      QuerySnapshot<Map<String, dynamic>> listingSnapshot = await firestore.collection('listings').where('userId', isEqualTo: listingId).get();

      if (listingSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> listingData = listingSnapshot.docs.first.data();
        Map<String, dynamic> listing = listingData..['id'] = listingSnapshot.docs.first.id;
        listings.add(listing);
      } else {
        print('Listing data is null for listing ID: $listingId'); // Add this line for debugging
      }
    }

    // Add the listings where the user is the recipient of a message
    QuerySnapshot<Map<String, dynamic>> messageRecipientSnapshot = await firestore.collection('messages').where('idTo', isEqualTo: userId).get();
    for (QueryDocumentSnapshot<Map<String, dynamic>> messageRecipientDoc in messageRecipientSnapshot.docs) {
      String listingId = messageRecipientDoc.data()['idFrom'];
      QuerySnapshot<Map<String, dynamic>> listingSnapshot = await firestore.collection('listings').where('userId', isEqualTo: listingId).get();

      if (listingSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> listingData = listingSnapshot.docs.first.data();
        Map<String, dynamic> listing = listingData..['id'] = listingSnapshot.docs.first.id;
        if (!listings.any((element) => element['id'] == listing['id'])) {
          listings.add(listing);
        }
      } else {
        print('Listing data is null for listing ID: $listingId'); // Add this line for debugging
      }
    }

    print('Listings: $listings');
    return listings;
  }


  //
  // Future<List<Map<String, dynamic>>> getListingsWithMessageHistory(String userId) async {
  //   List<Map<String, dynamic>> messages = await getMessagesWithUser(userId);
  //   print('Messages: $messages');
  //
  //   List uniqueUserIds = messages
  //       .map((message) =>
  //   message['idFrom'] == userId ? message['idTo'] : message['idFrom'])
  //       .toSet()
  //       .toList();
  //   print('Unique User IDs: $uniqueUserIds');
  //
  //   List<Map<String, dynamic>> listings = [];
  //   for (String listingId in uniqueUserIds) {
  //     QuerySnapshot<Map<String, dynamic>> listingSnapshot =
  //     await firestore.collection('listings').where('userId', isEqualTo: listingId).get();
  //
  //     if (listingSnapshot.docs.isNotEmpty) {
  //       Map<String, dynamic> listingData = listingSnapshot.docs.first.data();
  //       Map<String, dynamic> listing = listingData..['id'] = listingSnapshot.docs.first.id;
  //       listings.add(listing);
  //     } else {
  //       print('Listing data is null for user ID: $listingId'); // Add this line for debugging
  //     }
  //   }
  //
  //   print('Listings: $listings');
  //   return listings;
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Listings with Message History'),
      // ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getListingsWithMessageHistory(userId),
        builder: (context, snapshot) {

            if (snapshot.hasError) {
              print(snapshot.error);
              return const Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('No listings found'));
            }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> listing = snapshot.data![index];
              return ListTile(
                title: Text(listing['title']),
                subtitle: Text(listing['description']),
                leading: listing['imageUrls'] != null && listing['imageUrls'].isNotEmpty
                    ? Image.network(listing['imageUrls'][0])
                    : const Icon(Icons.image),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Chat(otherId: listing['userId'])),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
