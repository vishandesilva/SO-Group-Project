import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String profileName;
  final String userName;
  final String url;
  final String email;
  final String bio;

  User({
    this.id,
    this.profileName,
    this.userName,
    this.url,
    this.email,
    this.bio,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc.id,
      email: doc.data()['email'],
      userName: doc.data()['userName'],
      url: doc.data()['photoUrl'],
      profileName: doc.data()['profileName'],
      bio: doc.data()['bio'],
    );
  }
}
