import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  //control para mostrar u ocultar la contraseña
  bool _IsObscuretext = true;


  @override
  Widget build(BuildContext context) {
    //Obtain the size of the screen .i.
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              width: size.width,
              height: 200,
              child: RiveAnimation.asset('assets/OS0g0RdO.riv'),
            ),
            const SizedBox(height: 10),
            //Email
            TextField(
              //para mostrar un tipo de teclado
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            //Password
            TextField(
              obscureText: _IsObscuretext,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _IsObscuretext ? Icons.visibility : Icons.visibility_off
                  ),
                  onPressed: () {
                    setState(() {
                      _IsObscuretext = !_IsObscuretext;
                    });
                  }
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                )
              )
            )
          ],
        ),
      )),
    );
  }
}
