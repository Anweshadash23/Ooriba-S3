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
          .doc('request')
          .collection(employeeId)
          .doc('dates')
          .collection(fromDateStr)
          .doc('details')
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
          .doc('request')
          .collection(employeeId)
          .doc('dates')
          .collection(fromDateStr)
          .doc('details')
          .update({
        'isApproved': isApproved,
      });
    } catch (e) {
      print('Error updating leave status: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getLeaveRequests() async {
    List<Map<String, dynamic>> leaveRequests = [];

    try {
      QuerySnapshot employeeSnapshot = await _firestore
          .collection('leave')
          .doc('request')
          .collection('employees')
          .get();

      for (QueryDocumentSnapshot employeeDoc in employeeSnapshot.docs) {
        String employeeId = employeeDoc.id;
        QuerySnapshot dateSnapshot = await _firestore
            .collection('leave')
            .doc('request')
            .collection(employeeId)
            .doc('dates')
            .collection(
                'fromDateStr') // You need to specify the correct collection here
            .get();

        for (QueryDocumentSnapshot dateDoc in dateSnapshot.docs) {
          String fromDateStr = dateDoc.id;
          QuerySnapshot detailsSnapshot = await _firestore
              .collection('leave')
              .doc('request')
              .collection(employeeId)
              .doc('dates')
              .collection(fromDateStr)
              .get();

          for (QueryDocumentSnapshot detailDoc in detailsSnapshot.docs) {
            leaveRequests.add(detailDoc.data() as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      print('Error fetching leave requests: $e');
      throw e;
    }

    return leaveRequests;
  }
}
