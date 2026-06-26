import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // دالة حفظ رحلة جديدة سحابياً
  Future<void> saveNewTrip(TripModel trip) async {
    try {
      await _db.collection('trips').add(trip.toMap());
    } catch (e) {
      print('خطأ أثناء حفظ الرحلة: $e');
      rethrow;
    }
  }

  // جلب دفق الرحلات مع تمرير المخطط والـ ID بشكل متوافق تماماً
  Stream<List<TripModel>> getDriverTrips(String driverId) {
    return _db
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // تم التعديل هنا لتمرير الخريطة والـ ID معاً ليتوافق مع الـ Factory الخاص بـ TripModel
            return TripModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}