import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class FavoritesScreen extends StatelessWidget {
  final String userId;

  FavoritesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(userId)
            .collection('listings')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No favorites added'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                // Build your list view items here
              },
            );
          }
        },
      ),
    );
  }
}
