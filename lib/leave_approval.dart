import 'package:flutter/material.dart';
import 'services/leave_service.dart';

class LeaveApprovalPage extends StatefulWidget {
  @override
  _LeaveApprovalPageState createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final LeaveService _leaveService = LeaveService();
  List<Map<String, dynamic>> _leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      List<Map<String, dynamic>> leaveRequests =
          await _leaveService.getLeaveRequests();
      setState(() {
        _leaveRequests = leaveRequests;
      });
    } catch (e) {
      print('Error fetching leave requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Approval'),
      ),
      body: _leaveRequests.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _leaveRequests.length,
              itemBuilder: (context, index) {
                final leave = _leaveRequests[index];
                return ListTile(
                  title: Text('${leave['employeeId']} - ${leave['leaveType']}'),
                  subtitle: Text(
                      'From: ${leave['fromDate']} To: ${leave['toDate']} Days: ${leave['numberOfDays']}'),
                  trailing: Text(leave['leaveReason'] ?? 'No reason provided'),
                );
              },
            ),
    );
  }
}
