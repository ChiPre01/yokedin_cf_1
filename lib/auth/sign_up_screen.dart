import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/auth_provider.dart';
import 'package:yoked_in/auth/auth_services.dart';
import 'package:yoked_in/auth/google_login_screen.dart';
import 'package:yoked_in/auth/user_login_screen.dart';
import 'package:yoked_in/helper/navigation_helper.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/utilis.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(authFormProvider);
    final formNotifer = ref.read(authFormProvider.notifier);
    final authMethod = ref.read(authMethodProvider);
    void sigup() async {
      formNotifer.setLoading(true);
      final res = await authMethod.signUpUser(
        email: formState.email,
        password: formState.password,
        name: formState.name,
      );
      formNotifer.setLoading(false);
      if (res == "success" && context.mounted) {
        NavigationHelper.pushReplacement(context, UserLoginScreen());
        showAppSnackbar(
          context: context,
          type: SnackbarType.success,
          description: "Sinup Up Successful. Now turn to login",
        );
      } else {
        if (context.mounted) {
          showAppSnackbar(
            context: context,
            type: SnackbarType.error,
            description: res,
          );
        }
      }
    }

    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              height: height / 2.4,
              width: double.maxFinite,
              decoration: BoxDecoration(),
              child: Image.asset("images/yokedinB1.jpg", fit: BoxFit.cover),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  TextField(
                    autocorrect: false,
                    onChanged: (value) => formNotifer.updateName(value),
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: "Enter your name",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15),
                      errorText: formState.nameError,
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    autocorrect: false,
                    onChanged: (value) => formNotifer.updateEmail(value),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Enter your email",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15),
                      errorText: formState.emailError,
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    autocorrect: false,
                    onChanged: (value) => formNotifer.updatePassword(value),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: formState.isPasswordHidden,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Enter your password",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15),
                      errorText: formState.passwordError,
                      suffixIcon: IconButton(
                        onPressed: () => formNotifer.togglePasswordVisibility(),
                        icon: Icon(
                          formState.isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  formState.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : MyButton(
                          onTab: formState.isFormValid ? sigup : null,
                          buttonText: "Sign Up",
                        ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: Colors.black26),
                      ),
                      Text(" or "),
                      Expanded(
                        child: Container(height: 1, color: Colors.black26),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  // for google auth
                  GoogleLoginScreen(),
                  SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Spacer(),
                      Text("Already have an account?"),
                      GestureDetector(
                        onTap: () {
                          NavigationHelper.push(context, UserLoginScreen());
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
