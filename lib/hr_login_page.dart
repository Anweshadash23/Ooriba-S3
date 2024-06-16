// hr_login_page.dart
import 'package:flutter/material.dart';
import 'package:ooriba/services/auth_service.dart';

class HRLoginPage extends StatefulWidget {
  const HRLoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HRLoginPageState createState() => _HRLoginPageState();
}

class _HRLoginPageState extends State<HRLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signIn() {
    // Mock authentication logic
    //   if (loginId == 'admin' && password == 'password') {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => const HRDashboardPage()),
    //     );
    //   } else {
    //     showDialog(
    //       context: context,
    //       builder: (context) => AlertDialog(
    //         title: const Text('Error'),
    //         content: const Text('Invalid login credentials'),
    //         actions: [
    //           TextButton(
    //             onPressed: () => Navigator.pop(context),
    //             child: const Text('OK'),
    //           ),
    //         ],
    //       ),
    //     );
    //   }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Login'),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;

            return Container(
              width: maxWidth * 1.3,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Login ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await AuthService().signin(
                          email: _emailController.text,
                          password: _passwordController.text,
                          role: "HR",
                          context: context);
                    },
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password functionality
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
