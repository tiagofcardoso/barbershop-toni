import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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

  // Save User Consent (RGPD)
  Future<void> saveUserConsent(String userId) async {
    try {
      await _db.collection('users').doc(userId).set({
        'termsAccepted': true,
        'termsAcceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving consent: $e');
      throw e; // Rethrow to show error in UI
    }
  }

  // Get User Data Stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // Get specific user data once
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  // Update specific user fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  // --- Services Management ---

  // Get Services Stream
  Stream<List<Map<String, dynamic>>> getServicesStream() {
    return _db
        .collection('services')
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Seed Services (Migration Tool) - Clears existing and re-adds
  Future<void> seedServices(List<dynamic> services) async {
    // 1. Delete existing services
    final snapshot = await _db.collection('services').get();
    final deleteBatch = _db.batch();
    for (var doc in snapshot.docs) {
      deleteBatch.delete(doc.reference);
    }
    await deleteBatch.commit();

    // 2. Add new services
    final createBatch = _db.batch();
    int index = 0;
    for (var service in services) {
      final docRef = _db.collection('services').doc(); // Auto-ID
      createBatch.set(docRef, {
        'name': service.name,
        'price': service.price,
        'durationMinutes': service.durationMinutes,
        'imageUrl': service.imageUrl,
        'description': 'Serviço profissional',
        'orderIndex': index++,
      });
    }
    await createBatch.commit();
  }

  // Add Service
  Future<void> addService(Map<String, dynamic> data) async {
    // Basic implementation: adds to end (or 999 if lazy)
    // Ideally query max index first, but for now fixed high number or 0
    // Better: let's query count
    final snapshot = await _db.collection('services').count().get();
    data['orderIndex'] = snapshot.count;
    await _db.collection('services').add(data);
  }

  // Update Service
  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _db.collection('services').doc(id).update(data);
  }

  // Delete Service
  Future<void> deleteService(String id) async {
    await _db.collection('services').doc(id).delete();
  }

  // Update Service Order
  Future<void> updateServicesOrder(List<Map<String, dynamic>> services) async {
    final batch = _db.batch();
    for (int i = 0; i < services.length; i++) {
      final docRef = _db.collection('services').doc(services[i]['id']);
      batch.update(docRef, {'orderIndex': i});
    }
    await batch.commit();
  }

  // --- End Services Management ---

  // --- Products Management ---

  // Get Products Stream
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Add Product
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add(data);
  }

  // Update Product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  // Delete Product
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // --- End Products Management ---

  // --- Settings Management ---

  Future<Map<String, dynamic>?> getBusinessSettings() async {
    final doc = await _db.collection('settings').doc('business').get();
    return doc.data();
  }

  Future<void> saveBusinessSettings(Map<String, dynamic> data) async {
    await _db
        .collection('settings')
        .doc('business')
        .set(data, SetOptions(merge: true));
  }

  // --- End Settings Management ---

  // --- Appointments ---

  // Stream all appointments (for Admin) - Optimized: Recent + Future
  Stream<List<Map<String, dynamic>>> getAppointmentsStream() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _db
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .orderBy('dateTime')
        .snapshots()
        .map(
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

  // Delete Notification
  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  // Get Booked Appointments for a Date
  Stream<List<Map<String, dynamic>>> getBookedAppointmentsOnDate(
      DateTime date) {
    // Create start and end of the day
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status'] as String?;
            // Filter out cancelled appointments
            return status != 'Cancelado';
          })
          .map((doc) => doc.data())
          .toList();
    });
  }

  // Get Booked Slots for a Date
  Stream<List<DateTime>> getBookedSlotsStream(DateTime date) {
    // Create start and end of the day
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status'] as String?;
            // Filter out cancelled appointments
            return status != 'Cancelado';
          })
          .map((doc) => (doc.data()['dateTime'] as Timestamp).toDate())
          .toList();
    });
  }
  // --- Reservations ---

  // Create Reservation
  Future<void> createReservation(String userId, String userName,
      List<Map<String, dynamic>> items, double totalPrice) async {
    await _db.collection('reservations').add({
      'userId': userId,
      'userName': userName,
      'items': items,
      'totalPrice': totalPrice,
      'status': 'pending', // pending, completed, cancelled
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Optional: Add notification for Admin?
  }

  // Stream Reservations (optionally filtered by status)
  Stream<List<Map<String, dynamic>>> getReservationsStream({String? status}) {
    Query query =
        _db.collection('reservations').orderBy('timestamp', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream My Reservations (User)
  Stream<List<Map<String, dynamic>>> getMyReservationsStream(String userId) {
    return _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Complete Reservation (Transaction: Update Status + Decrement Stock)
  Future<void> completeReservation(
      String reservationId, List<dynamic> items) async {
    return _db.runTransaction((transaction) async {
      // 1. Get current reservation state to ensure it exists
      final reservationRef = _db.collection('reservations').doc(reservationId);
      final reservationSnapshot = await transaction.get(reservationRef);

      if (!reservationSnapshot.exists) {
        throw Exception("Reservation does not exist!");
      }

      // 2. Decrement Stock for each item
      for (var item in items) {
        final productId = item['productId'];
        final quantity = item['quantity'] as int;

        final productRef = _db.collection('products').doc(productId);
        final productSnapshot = await transaction.get(productRef);

        if (productSnapshot.exists) {
          final currentStock = productSnapshot.data()?['stock'] as int? ?? 0;
          final newStock = currentStock - quantity;
          transaction.update(productRef, {'stock': newStock});
        }
      }

      // 3. Update Reservation Status
      transaction.update(reservationRef, {'status': 'completed'});
    });
  }

  // Cancel Reservation
  Future<void> cancelReservation(String reservationId) async {
    await _db
        .collection('reservations')
        .doc(reservationId)
        .update({'status': 'cancelled'});
  }

  // --- Professionals Management ---
  Stream<List<Map<String, dynamic>>> getProfessionalsStream() {
    return _db
        .collection('professionals')
        .orderBy('orderIndex')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<void> addProfessional(Map<String, dynamic> data) async {
    final snapshot = await _db.collection('professionals').count().get();
    data['orderIndex'] = snapshot.count;
    await _db.collection('professionals').add(data);
  }

  Future<void> updateProfessional(String id, Map<String, dynamic> data) async {
    await _db.collection('professionals').doc(id).update(data);
  }

  Future<void> deleteProfessional(String id) async {
    await _db.collection('professionals').doc(id).delete();
  }
}
