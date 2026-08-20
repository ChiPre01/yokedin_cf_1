import 'package:flutter/material.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<LoginScreen> {
  // for controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: height / 2.7,
                  child: Image.asset("images/yokedinB1.jpg"),
                ),
                // we have a multiple textform field in our code, that's why we have create a common textfield
                TextFieldInput(
                  textEditingController: emailController,
                  hintText: "Enter your Email",
                  icon: Icons.email,
                ),
                TextFieldInput(
                  textEditingController: passwordController,
                  hintText: "Enter your Password",
                  icon: Icons.lock,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Forgot Password",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red),
                    ),
                  ),
                ),
                MyButton(onTab: () {}, text: "Sign In"),
                SizedBox(height: height / 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        "Sign  Up",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
