import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // CHECK IF USERNAME EXISTS VALIDATION
  Future<bool> checkUsernameExists({required String username}) async {
    final QuerySnapshot result = await _usersCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  /*
  
    CREATE

  */

  // create user
  Future<void> addUserToDatabase({
    required String uid,
    required String email,
    required username,
  }) async {
    await _usersCollection.doc(uid).set({
      'email': email,
      'username': username,
    });
  }

  // upload profile picture
  Future<void> uploadProfilePicture({
    required String userId,
    required String filePath,
  }) async {
    await _usersCollection.doc(userId).update({
      'profilePicture': filePath,
    });
  }

  /*

    READ

  */

  // get universities
  Future<List<Map<String, dynamic>>> getUniversities() async {
    final QuerySnapshot universities =
        await FirebaseFirestore.instance.collection('universities').get();
    return universities.docs
        .map((DocumentSnapshot doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // get buildings
  Future<List<dynamic>> getBuildings({
    required String userId,
  }) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final String university = userDoc.get('university');

    final DocumentSnapshot universityDoc = await FirebaseFirestore.instance
        .collection('universities')
        .doc(university)
        .get();

    if (!universityDoc.exists) {
      throw Exception('University not found');
    }

    return universityDoc.get('buildings');
  }

  // get classes
  Future<Map<String, dynamic>> getClassesFromDatabase(
      {required String userId}) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  // get user
  Future<Map<String, dynamic>> getUser({required String? userId}) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  // get profile picture
  Future<String> getProfilePicture({required String userId}) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    final String profilePicture = userDoc.get('profilePicture');
    return profilePicture;
  }

  /*

    UPDATE

  */

  // update user password
  Future<void> updateUserPassword({
    required String userId,
    required String password,
  }) async {
    await _usersCollection.doc(userId).update({
      'password': password,
    });
  }

  // create/add a class
  Future<void> addClassToDatabase({
    required String userId,
    required Map<String, dynamic> userClass,
  }) async {
    await _usersCollection.doc(userId).update({
      'classes': FieldValue.arrayUnion([userClass]),
    });
  }

  // update user's preferred university
  Future<void> updateUserUniversity({
    required String userId,
    required String university,
  }) async {
    await _usersCollection.doc(userId).update({
      'university': university,
    });
  }

  /*

    // DELETE

  */

  Future<void> deleteClassFromDatabase({
    required String userId,
    required Map<String, dynamic> userClass,
  }) async {
    await _usersCollection.doc(userId).update({
      'classes': FieldValue.arrayRemove([userClass]),
    });
  }

  // DELETE USER
  Future<void> deleteUserData(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}
