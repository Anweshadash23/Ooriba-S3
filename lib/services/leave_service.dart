import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime? fromDate,
    required DateTime? toDate,
    required double numberOfDays,
    required String? leaveReason,
  }) async {
    try {
      String fromDateStr =
          fromDate != null ? fromDate.toIso8601String().split('T').first : '';

      await _firestore
          .collection('leave')
          .doc(employeeId)
          .collection('dates')
          .doc(fromDateStr)
          .set({
        'employeeId': employeeId,
        'leaveType': leaveType,
        'fromDate': fromDate,
        'toDate': toDate,
        'numberOfDays': numberOfDays,
        'leaveReason': leaveReason,
      });
    } catch (e) {
      print('Error applying leave: $e');
      throw e;
    }
  }

  Future<void> updateLeaveStatus({
    required String employeeId,
    required String fromDateStr,
    required bool isApproved,
  }) async {
    try {
      await _firestore
          .collection('leave')
          .doc(employeeId)
          .collection('dates')
          .doc(fromDateStr)
          .update({
        'isApproved': isApproved,
      });
    } catch (e) {
      print('Error updating leave status: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>?> fetchLeaveDetails(
      String employeeId, String fromDateStr) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('leave')
          .doc(employeeId)
          .collection('dates')
          .doc(fromDateStr)
          .get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      print('Error fetching leave details: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllLeaveRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collectionGroup('dates').get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['employeeId'] = doc.reference.parent.parent?.id ??
            'Unknown'; // Include employeeId in the data
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching all leave requests: $e');
      throw e;
    }
  }
}
