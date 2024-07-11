import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getEmployeeById(String employeeId) async {
    try {
      QuerySnapshot snapshot = (await _db
          .collection('Regemp')
          .where('employeeId', isEqualTo: employeeId).limit(1)
          .get());

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
