import 'package:flutter/material.dart';
import 'package:ooriba/facial/RecognitionScreen.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;
  const HomeScreen({super.key, required this.phoneNumber});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 100),
            child: Image.asset("assets/images/logo.png",
                width: screenWidth - 40, height: screenWidth - 40),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecognitionScreen(
                          phoneNumber: widget.phoneNumber,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size(screenWidth - 30, 50)),
                  child: const Text("Recognize"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
