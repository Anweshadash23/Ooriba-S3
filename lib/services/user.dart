import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveLastLoginTime(String phoneNo, DateTime lastLoginTime) async {
    await _db.collection('Users').doc(phoneNo).update({
      'lastLoginTime': lastLoginTime,
    });
  }

  Future<DocumentSnapshot> getLastLoginTime(String phoneNo) async {
    return await _db.collection('Users').doc(phoneNo).get();
  }

  Future<void> createLastLoginTime(String phoneNo, DateTime lastLoginTime) async {
    await _db.collection('Users').doc(phoneNo).set({
      'lastLoginTime': lastLoginTime,
    });
  }

  Future<DocumentSnapshot> getCheckInOutData(String phoneNo, String date) async {
    return await _db.collection('Dates').doc(date).get();
  }

  Future<void> addCheckInOutData(String phoneNo, DateTime checkInTime, DateTime? checkOutTime, DateTime timestamp) async {
    String date = DateFormat('yyyy-MM-dd').format(timestamp);
    DocumentReference docRef = _db.collection('Dates').doc(date);
    Map<String, dynamic> data = {
      'checkIn': checkInTime,
      'checkOut': checkOutTime,
    };
    await docRef.set({
      phoneNo: data,
    }, SetOptions(merge: true));
  }
}
