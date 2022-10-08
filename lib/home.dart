import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_marble/models/user_model.dart';
import 'package:royal_marble/screens/profile_drawer.dart';
import 'package:royal_marble/services/auth.dart';
import 'package:royal_marble/shared/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  UserData userProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      drawer: ProfileDrawer(currentUser: userProvider),
      body: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    return userProvider.isActive != null && userProvider.isActive
        ? Center(
            child: ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
              child: const Text('Sign Out'),
            ),
          )
        : const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Center(
                child: Text(
              'Current User is still not active, please contact your admin to activate your account!',
              style: textStyle4,
            )),
          );
  }
}
