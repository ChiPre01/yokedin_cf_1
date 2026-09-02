import 'package:flutter/material.dart';
import 'package:yoked_in/auth/authentication.dart';
import 'package:yoked_in/auth/login_screen.dart';
import 'package:yoked_in/widgets/button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Congrats",
            ),
            MyButton(onTap: ()async{
              await AuthService().signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>LoginScreen()));
            }, text: "Sign Out"),
          ],
        ),
      ),
    );
  }
}