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
          .doc('request')
          .collection(employeeId)
          .doc(fromDateStr)
          .update({
        'isApproved': isApproved,
      });
    } catch (e) {
      print('Error updating leave status: $e');
      throw e;
    }
  }
}
