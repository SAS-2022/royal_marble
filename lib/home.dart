import 'package:flutter/material.dart';
import 'package:royal_marble/services/auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await _authService.signOut();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
        child: Text('Sign Out'),
      ),
    );
  }
}
