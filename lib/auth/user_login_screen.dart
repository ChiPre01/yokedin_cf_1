import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoked_in/auth/auth_provider.dart';
import 'package:yoked_in/auth/auth_services.dart';
import 'package:yoked_in/auth/google_login_screen.dart';
import 'package:yoked_in/auth/sign_up_screen.dart';
import 'package:yoked_in/helper/navigation_helper.dart';
import 'package:yoked_in/other_screens/main_home.dart';
import 'package:yoked_in/widgets/button.dart';
import 'package:yoked_in/widgets/utilis.dart';

class UserLoginScreen extends ConsumerWidget {
  const UserLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double height = MediaQuery.of(context).size.height;
    final formState = ref.watch(authFormProvider);
    final formNotifer = ref.read(authFormProvider.notifier);
    final authMethod = ref.read(authMethodProvider);
    void login() async {
      formNotifer.setLoading(true);
      final res = await authMethod.loginUser(
        email: formState.email,
        password: formState.password,
      );
      formNotifer.setLoading(false);
      if (res == "success") {
        NavigationHelper.pushReplacement(context, MainHomeScreen());
        // mySnackBar(message: "Successful Login.", context: context);
        showAppSnackbar(
          context: context,
          type: SnackbarType.success,
          description: "Successful Login",
        );
      } else {
        showAppSnackbar(
          context: context,
          type: SnackbarType.error,
          description: res,
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: height / 2.1,
              width: double.maxFinite,
              child: Image.asset("images/yokedinB2.jpg", fit: BoxFit.cover),
            ),
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
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
                          onTab: formState.isFormValid ? login : null,

                          buttonText: "Login",
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
                      Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          NavigationHelper.push(context, SignupScreen());
                        },
                        child: Text(
                          "SignUp",
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
