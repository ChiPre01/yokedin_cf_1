import 'package:flutter/material.dart';
import 'package:yoked_in/auth/authentication.dart';
import 'package:yoked_in/auth/forgot_password.dart';
import 'package:yoked_in/auth/sign_up.dart';
import 'package:yoked_in/screens/homescreen.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/snack_bar.dart';
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
  bool isLoading = false;

   @override
  void dispose(){
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    String res = await AuthServices().loginUser(
      email: emailController.text,
      password: passwordController.text,
    );
    //if sign in is a success, user has been created, navigate to next screen
    // otherwise show the error message
    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      //navigate to the next screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: ((context) => HomeScreen()),
        ),
      );
    } else{
      setState(() {
        isLoading = false;
      });
      //show the error message
      showSnackBar(context, res);
    }
  }

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
                isPass: true,
                textEditingController: passwordController,
                hintText: "Enter your Password",
                icon: Icons.lock,
              ),
              MyButton(onTab: loginUser, text: "Sign In"),
              
              // we call our forgot password below the log in button
              ForgotPassword(),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?",
                      style: TextStyle(fontSize: 16)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: Text(
                      "Sign  Up",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
