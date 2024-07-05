import 'package:flutter/material.dart';
import 'RecognitionScreen.dart';
import 'RegistrationScreen.dart';

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});
  @override
  State<HomeScreen2> createState() => _HomePageState2();
}

class _HomePageState2 extends State<HomeScreen2> {
  // Add a TextEditingController to capture phone number input
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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
            child: Image.asset(
              "assets/images/logo.png",
              width: screenWidth - 40,
              height: screenWidth - 40,
            ),
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
                        builder: (context) => const RegistrationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(screenWidth - 30, 50),
                  ),
                  child: const Text("Register"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Phone Number',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String phoneNumber = _phoneController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RecognitionScreen(phoneNumber: phoneNumber),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(screenWidth - 30, 50),
                  ),
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
