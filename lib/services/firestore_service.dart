import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get usersCollection => _firestore.collection('users');

  CollectionReference? getUserCollection(String collectionName) {
    if (currentUserId == null) return null;
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(collectionName);
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      await usersCollection.doc(uid).set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getUserProfile(String uid) async {
    try {
      return await usersCollection.doc(uid).get();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<DocumentReference?> addData({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      final docData = {
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': currentUserId,
      };

      return await collection.add(docData);
    } catch (e) {
      debugPrint('Error adding data to $collectionName: $e');
      rethrow;
    }
  }

  Future<void> updateData({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      final docData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await collection.doc(documentId).update(docData);
    } catch (e) {
      debugPrint('Error updating data in $collectionName: $e');
      rethrow;
    }
  }

  Future<void> deleteData({
    required String collectionName,
    required String documentId,
  }) async {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      await collection.doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting data from $collectionName: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getDataStream({
    required String collectionName,
    Query Function(Query)? queryBuilder,
  }) {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      Query query = collection.orderBy('createdAt', descending: true);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return query.snapshots();
    } catch (e) {
      debugPrint('Error getting data stream from $collectionName: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot?> getData({
    required String collectionName,
    Query Function(Query)? queryBuilder,
  }) async {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      Query query = collection.orderBy('createdAt', descending: true);
      
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      return await query.get();
    } catch (e) {
      debugPrint('Error getting data from $collectionName: $e');
      return null;
    }
  }

  Future<DocumentSnapshot?> getDocument({
    required String collectionName,
    required String documentId,
  }) async {
    try {
      final collection = getUserCollection(collectionName);
      if (collection == null) throw Exception('User not authenticated');

      return await collection.doc(documentId).get();
    } catch (e) {
      debugPrint('Error getting document from $collectionName: $e');
      return null;
    }
  }

  WriteBatch get batch => _firestore.batch();

  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error committing batch: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserData() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      
      final collections = [
        'transactions',
        'categories',
        'wallets',
        'goals',
        'debts',
        'bills',
        'creditCards',
        'settings',
      ];

      for (final collectionName in collections) {
        final collection = getUserCollection(collectionName);
        if (collection != null) {
          final snapshot = await collection.get();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
        }
      }

      batch.delete(usersCollection.doc(currentUserId));

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all user data: $e');
      rethrow;
    }
  }
}