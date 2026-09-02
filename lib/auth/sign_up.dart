import 'package:flutter/material.dart';
import 'package:yoked_in/auth/authentication.dart';
import 'package:yoked_in/auth/login_screen.dart';
import 'package:yoked_in/screens/homescreen.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/snack_bar.dart';
import 'package:yoked_in/widgets/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // for controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  bool isPasswordHidden = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

//sign up function to handle user registration
  void signUp() async {
    setState(() {
      isLoading = true;
    });
    //call the method
    final result = await _authService.signUpUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );
    if (result == "success") {
      setState(() {
        isLoading = false;
      });
      //navigate to the next screen
      showSnackBar(context, "Sign Up Successful!! Now Turn to Log In");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Sign Up Failed! $result");
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
                    textEditingController: nameController,
                    hintText: "Enter your name",
                    icon: Icons.person,
                  ),
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

                  //for sign up button
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: MyButton(onTap: signUp, text: "Sign Up")),
                  SizedBox(height: height / 15),

                  //already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          "Sign  In",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      )
                    ],
                  ),
                  //OR
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
                  //continue with google
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey),
                      onPressed: () async {
                        await AuthService().signInWithGoogle();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(),
                          ),
                        );
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
                            "Sign Up with Google",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
