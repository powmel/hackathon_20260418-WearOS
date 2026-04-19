import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    await signInAnonymously();
  }

  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // Ignore for now
    }
  }

  // CognitoユーザーIDでFirestoreからデータを取得
  Stream<UserData?> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return UserData.fromMap(data);
    });
  }

  Future<UserData?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserData.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Stream<List<Comment>> getCommentsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> updateRhinoStatus({
    required String userId,
    required int focusScore,
    required int fullness,
    required String mood,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'rhinoStatus': {
          'focusScore': focusScore,
          'fullness': fullness,
          'mood': mood,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      // Ignore for now
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;
}

class UserData {
  final String userId;
  final String displayName;
  final int focusScore;
  final int fullness;
  final String mood;
  final int usageMinutes;
  final DateTime? lastUpdated;

  UserData({
    required this.userId,
    required this.displayName,
    required this.focusScore,
    required this.fullness,
    required this.mood,
    required this.usageMinutes,
    this.lastUpdated,
  });

  factory UserData.fromMap(Map<String, dynamic> map) {
    final rhinoStatus = map['rhinoStatus'] as Map<String, dynamic>? ?? {};
    return UserData(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'ユーザー',
      focusScore: rhinoStatus['focusScore'] ?? 0,
      fullness: rhinoStatus['fullness'] ?? 50,
      mood: rhinoStatus['mood'] ?? 'calm',
      usageMinutes: map['usageMinutes'] ?? 0,
      lastUpdated: rhinoStatus['lastUpdated'] != null
          ? (rhinoStatus['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }
}

class Comment {
  final String text;
  final DateTime timestamp;
  final String? author;

  Comment({
    required this.text,
    required this.timestamp,
    this.author,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      author: map['author'],
    );
  }
}
