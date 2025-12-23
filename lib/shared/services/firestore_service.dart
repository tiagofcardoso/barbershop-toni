import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'barbershop-native');

  // --- Users ---
  Future<void> saveUser(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? 'Cliente',
      'email': user.email,
      'photoUrl': user.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
      'role': user.email == 'admin@barber.com' ? 'admin' : 'client',
    }, SetOptions(merge: true));
  }

  // --- Appointments ---

  // Stream all appointments (for Admin)
  Stream<List<Map<String, dynamic>>> getAppointmentsStream() {
    return _db.collection('appointments').orderBy('dateTime').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Stream my appointments (for Client)
  Stream<List<Map<String, dynamic>>> getMyAppointmentsStream(String uid) {
    return _db
        .collection('appointments')
        .where('customerId', isEqualTo: uid)
        .orderBy('dateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Add Appointment
  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    await _db.collection('appointments').add(appointmentData);
  }

  // Update Appointment (Status or Reschedule)
  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await _db.collection('appointments').doc(id).update(data);
  }

  // Delete Appointment
  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  // --- Notifications ---

  // Add Notification
  Future<void> addNotification(
      String userId, String title, String message) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream Notifications for User
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Mark as Read
  Future<void> markNotificationAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  // Get Unread Count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
