import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yoked_in/auth/authentication.dart';
import 'package:yoked_in/auth/forgot_password.dart';
import 'package:yoked_in/auth/phone_auth.dart';
import 'package:yoked_in/auth/sign_up.dart';
import 'package:yoked_in/screens/homescreen.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/snack_bar.dart';
import 'package:yoked_in/widgets/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // for controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordHidden = true;

  Future<void> showNameDialog(BuildContext context, User user) async {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Complete Sign Up"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Enter your name",
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  showSnackBar(context, "Name is required");
                  return;
                }

                await AuthService().saveGoogleUser(
                  uid: user.uid,
                  email: user.email ?? "",
                  name: nameController.text.trim(),
                );

                Navigator.pop(context); // close dialog

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                );
              },
              child: Text("Complete Sign Up"),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    String res = await AuthService().loginUser(
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
    } else {
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
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
                    obscureText: isPasswordHidden, // ✅ correct usage
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordHidden = !isPasswordHidden;
                        });
                      },
                      icon: Icon(
                        isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  SizedBox(height: height / 15),
                  ForgotPassword(),
                  isLoading
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: MyButton(onTap: loginUser, text: "Sign In"),
                        ),

                  SizedBox(height: height / 15),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.black,
                        ),
                      ),
                      const Text("or"),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  //for google sign in
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () async {
                        final result = await AuthService().signInWithGoogle();

                        if (result == null) {
                          showSnackBar(context, "Google sign-in failed");
                          return;
                        }

                        if (result["status"] == "existing") {
                          // go straight to home
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ),
                          );
                        } else {
                          // new user → show dialog
                          await showNameDialog(context, result["user"]);
                        }
                      },
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Image.asset(
                              "images/yokedinGL.png",
                              height: 35,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  //phone auth
                  const PhoneAuthentication(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()),
                          );
                        },
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
          ),
        ),
      ),
    );
  }
}
