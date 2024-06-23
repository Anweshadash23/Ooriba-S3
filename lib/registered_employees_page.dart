import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registered Employees',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RegisteredEmployeesPage(),
    );
  }
}

class RegisteredEmployeesPage extends StatelessWidget {
  final CollectionReference employees =
      FirebaseFirestore.instance.collection('Regemp');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Employees'),
      ),
      body: StreamBuilder(
        stream: employees.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return EmployeeCard(
                name: data['name'],
                phone: data['phone'],
                email: data['email'],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;

  EmployeeCard({required this.name, required this.phone, required this.email});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Text(
            name[0],
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: $phone'),
            Text('Email: $email'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            // Define your "View More" action here
          },
          child: Text('View More'),
        ),
      ),
    );
  }
}
