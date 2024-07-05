import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getEmployeeByPhoneNumber(
      String phoneNumber) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('Regemp')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('role', isEqualTo: 'Standard')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> searchEmployee(
      {required String phoneNumber}) async {
    if (phoneNumber.isNotEmpty) {
      final employeeData = await getEmployeeByPhoneNumber(phoneNumber);
      return employeeData;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      QuerySnapshot snapshot = await _db.collection('Regemp').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }
}
