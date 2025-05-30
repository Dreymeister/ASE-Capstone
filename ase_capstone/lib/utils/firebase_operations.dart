import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

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

  Future<void> addToFavorites({
    required String userId,
    String? building,
  }) async {
    if (building != null) {
      await _usersCollection.doc(userId).update({
        'favorite-buildings': FieldValue.arrayUnion([building])
      });
    }
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

  // create pin
  Future<void> createPin({
    required LocationData currentLocation,
    required String markerTitle,
  }) async {
    await FirebaseFirestore.instance.collection('pins').add({
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
      'title': markerTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'category': markerTitle, // Store the category
      'yesVotes': 0,
      'noVotes': 0,
    });
  }

  // Check if the user has already voted on a pin
  Future<bool> hasUserVotedOnPin({
    required String userId,
    required String pinId,
  }) async {
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final List<dynamic> votedPins = (userDoc.data() as Map<String, dynamic>?)?['votedPins'] ?? [];
    return votedPins.contains(pinId);
  }

  // Add a pin to the user's votedPins field
  Future<void> addPinToUserVotes({
    required String userId,
    required String pinId,
  }) async {
    await _usersCollection.doc(userId).update({
      'votedPins': FieldValue.arrayUnion([pinId]),
    });
  }

  // create university
  Future<void> createUniversity(
      {required Map<String, dynamic> university}) async {
    // Check if the university already exists
    final QuerySnapshot existingUniversity = await FirebaseFirestore.instance
        .collection('universities')
        .where('name', isEqualTo: university['name'])
        .get();

    if (existingUniversity.docs.isNotEmpty) {
      // University already exists, do not create it again
      throw Exception('University name already exists');
    }

    // Create the university document
    await FirebaseFirestore.instance
        .collection('universities')
        .doc(university['name'])
        .set(university);
  }

  Future<void> addResource(
      {required Map<String, dynamic> resource, required String uid}) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final String university = userDoc.get('university');

    await FirebaseFirestore.instance
        .collection('universities')
        .doc(university)
        .update({
      'resources': FieldValue.arrayUnion([resource])
    });
  }

  Future<void> addEventReminder({
    required String userId,
    required Map<String, dynamic> event,
  }) async {
    _usersCollection.doc(userId).update({
      'eventReminders': FieldValue.arrayUnion([event])
    });
  }

  // add notification
  Future<void> addNotification({
    required String userId,
    required String message,
    String type = 'general',
  }) async {
    await _usersCollection.doc(userId).collection('notifications').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': type,
    });
  }

  /*
  
    READ
    
  */

  // get user theme
  Future<Map<String, dynamic>> getUserTheme({
    required String userId,
    required String themeName,
  }) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final data = userDoc.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('theme-$themeName')) {
      return {};
    }

    return data['theme-$themeName'] as Map<String, dynamic>;
  }

  // get universities
  Future<List<Map<String, dynamic>>> getUniversities() async {
    final QuerySnapshot universities =
        await FirebaseFirestore.instance.collection('universities').get();
    return universities.docs
        .map((DocumentSnapshot doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // get user favorites
  Future<dynamic> getFavorite({
    required String userId,
    String? building,
  }) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final data = userDoc.data() as Map<String, dynamic>?;

    // get buildings
    if (building != null) {
      if (data == null || !data.containsKey('favorite-buildings')) {
        return false;
      }

      final List<dynamic> favorites = userDoc.get('favorite-buildings') ?? [];

      return favorites.contains(building);
    } else {
      // return all favorites
      return data?['favorite-buildings'] ?? [];
    }
  }

  // get user's university
  Future<String> getUserUniversity({required String userId}) async {
    try {
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      return userDoc.get('university');
    } catch (e) {
      return "";
    }
  }

  // get university by name
  Future<Map<String, dynamic>> getUniversityByName(
      {required String name}) async {
    try {
      final QuerySnapshot university = await FirebaseFirestore.instance
          .collection('universities')
          .where('name', isEqualTo: name)
          .get();
      return university.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      // return empty university if not found
      return {
        'name': '',
        'abbreviation': '',
        'buildings': [],
      };
    }
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
  Future<Map<String, dynamic>> getClassesFromDatabase({
    required String userId,
  }) async {
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

  // check if the user is an adimin
  Future<bool> isAdmin({required String userId}) async {
    final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
    try {
      final bool? isAdmin = userDoc.get('isAdmin');
      return isAdmin ?? false;
    } catch (e) {
      return false; // Return false if the field doesn't exist
    }
  }

// get resources from university collection if exists
  Future<List<Map<String, dynamic>>> getResources(
      {String? universityId}) async {
    if (universityId == null || universityId.isEmpty) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('universities')
        .doc(universityId)
        .get();

    if (snapshot['resources'].isEmpty) {
      throw Exception('The university does not have any resources yet');
    }

    return (snapshot["resources"] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // get notifications
  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
  }) async {
    final snapshot = await _usersCollection
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  // get unread notifications count
  Future<int> getUnreadNotificationCount({required String userId}) async {
    final snapshot = await _usersCollection
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  /*
  
    UPDATE
    
  */

  // update user theme
  Future<void> saveTheme({
    required userId,
    required Map<String, dynamic> theme,
    required String themeName,
  }) async {
    await _usersCollection.doc(userId).update({
      'theme-$themeName': theme,
    });
  }

  //update username
  Future<void> updateUserField({
    required String userId,
    required String field,
    required dynamic value,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      field: value,
    });
  }

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

  // update pins
  Future<void> updatePins({
    required String markerId,
    required bool isYesVote,
  }) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('pins').doc(markerId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Marker does not exist!");
      }

      int newYesVotes = snapshot['yesVotes'];
      int newNoVotes = snapshot['noVotes'];

      if (isYesVote) {
        newYesVotes += 1;
      } else {
        newNoVotes += 1;
      }

      if (newNoVotes > 5) {
        transaction.delete(docRef);
      } else {
        transaction.update(docRef, {
          'yesVotes': newYesVotes,
          'noVotes': newNoVotes,
          'lastActivity': FieldValue.serverTimestamp()
        });
      }
    });
  }

  // update university
  Future<void> updateUniversity({
    required String name,
    required Map<String, dynamic> university,
  }) async {
    await FirebaseFirestore.instance
        .collection('universities')
        .doc(name)
        .update(university);
  }

  // mark all notifications as read
  Future<void> markAllNotificationsAsRead({required String userId}) async {
    final snapshot = await _usersCollection
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  /*
  
    DELETE
    
  */

  Future<void> deleteEventReminder({
    required String userId,
    required Map<String, dynamic> event,
  }) async {
    await _usersCollection.doc(userId).update({
      'eventReminders': FieldValue.arrayRemove([event])
    });
  }

  Future<void> removeFavorite(
      {required String userId, String? building}) async {
    if (building != null) {
      await _usersCollection.doc(userId).update({
        'favorite-buildings': FieldValue.arrayRemove([building])
      });
    }
  }

  Future<void> deleteClassFromDatabase({
    required String userId,
    required Map<String, dynamic> userClass,
  }) async {
    await _usersCollection.doc(userId).update({
      'classes': FieldValue.arrayRemove([userClass]),
    });
  }

  // delete user data
  Future<void> deleteUserData(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // delete expired pins
  Future<void> deleteExpiredPins({required DateTime expirationTime}) async {
    FirebaseFirestore.instance
        .collection('pins')
        .where('lastActivity', isLessThan: expirationTime)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    }).catchError((error) {
      throw Exception('Error deleting expired pins: $error');
    });
  }

  Future<String> getEventUrl({required String userId}) async {
    try {
      // Get the user's university
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User document does not exist.');
      }
      final String university = userDoc.get('university');

      // Fetch the event URL from the university document
      final universityDoc = await FirebaseFirestore.instance
          .collection('universities')
          .doc(university)
          .get();

      if (!universityDoc.exists) {
        throw Exception('University document does not exist.');
      }

      // Return the eventUrl field
      return universityDoc.data()?['eventUrl'] ??
          'https://default-url.com'; // Provide a default URL if none exists
    } catch (e) {
      throw Exception('Error fetching event URL: $e');
    }
  }

  // clear notifications
  Future<void> clearNotifications({
    required String userId,
  }) async {
    final snapshot =
        await _usersCollection.doc(userId).collection('notifications').get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
