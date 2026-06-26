import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String? id;
  final String driverId;
  final DateTime startTime;
  final double distanceKm;
  final double fareAmount;
  final double netEarnings;
  final String platform;

  TripModel({
    this.id,
    required this.driverId,
    required this.startTime,
    required this.distanceKm,
    required this.fareAmount,
    required this.netEarnings,
    required this.platform,
  });

  // تحويل الكائن إلى خريطة لحفظها في Firestore
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'startTime': Timestamp.fromDate(startTime), // تحويل DateTime إلى Timestamp الخاص بفايربيز
      'distanceKm': distanceKm,
      'fareAmount': fareAmount,
      'netEarnings': netEarnings,
      'platform': platform,
    };
  }

  // استقبال البيانات وتوليد الكائن مع دعم الـ documentId بشكل إلزامي
  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripModel(
      id: documentId,
      driverId: map['driverId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      fareAmount: (map['fareAmount'] as num).toDouble(),
      netEarnings: (map['netEarnings'] as num).toDouble(),
      platform: map['platform'] ?? 'Uber',
    );
  }
}