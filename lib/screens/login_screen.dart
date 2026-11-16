import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Control para mostrar/ocultar contraseña
  bool _isObscure = true;
  bool _isLoading = false;

  // 1.1 Controlador de la animación
  StateMachineController? _controller;

  // 1.2 Entradas de la máquina de estados
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  // 3.2 Timer para detener la mirada
  Timer? _typingDebounce;

  // 2.1 FocusNodes
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // 4.1 Controladores de texto
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // 4.2 Errores de validación
  String? emailError;
  String? passError;

  // 4.3 Validar correo electrónico
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  // Validar contraseña
  bool isValidPassword(String pass) {
    // Mínimo 8 caracteres:
    // Una mayúscula, una minúscula,
    // un número y un símbolo.
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Acción del botón Login
  Future<void> _onLogin() async {
    if (_isLoading) return;

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalcular errores
    final emailTypedError = isValidEmail(email) ? null : 'Email no válido';

    final passwordTypedError = isValidPassword(pass)
        ? null
        : 'Contraseña no válida';

    // 4.5 Actualizar la interfaz
    setState(() {
      emailError = emailTypedError;
      passError = passwordTypedError;
    });

    // 4.6 Cerrar teclado y bajar manos
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();

    _isHandsUp?.change(false);
    _isChecking?.change(false);
    _numLook?.value = 50;

    // 4.9 Si el formato es inválido, mostrar error y detener aquí.
    if (emailTypedError != null || passwordTypedError != null) {
      _trigFail?.fire();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // La pausa permite ver el indicador mientras Firebase responde.
      await Future<void>.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _trigSuccess?.fire();
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const ProductsScreen()),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _trigFail?.fire();
      setState(() {
        passError = switch (error.code) {
          'user-not-found' => 'No existe una cuenta con este correo',
          'wrong-password' ||
          'invalid-credential' => 'Correo o contraseña incorrectos',
          'invalid-email' => 'El correo no es válido',
          'too-many-requests' => 'Demasiados intentos. Inténtalo más tarde',
          _ => 'No se pudo iniciar sesión. Inténtalo de nuevo',
        };
      });
    } catch (_) {
      if (!mounted) return;
      _trigFail?.fire();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con Firebase')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Inicializar la animación de Rive
  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
    );

    if (_controller == null) {
      debugPrint('No se encontró Login Machine');
      return;
    }

    artboard.addController(_controller!);

    _isChecking = _controller!.findSMI<SMIBool>('isChecking');

    _isHandsUp = _controller!.findSMI<SMIBool>('isHandsUp');

    _trigSuccess = _controller!.findSMI<SMITrigger>('trigSuccess');

    _trigFail = _controller!.findSMI<SMITrigger>('trigFail');

    _numLook = _controller!.findSMI<SMINumber>('numLook');

    // Estado inicial
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50;
  }

  // 2.2 Listeners
  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        // El personaje mira el correo
        _isHandsUp?.change(false);
        _numLook?.value = 50;
      } else {
        _typingDebounce?.cancel();
        _isChecking?.change(false);
      }
    });

    _passwordFocusNode.addListener(() {
      final hasFocus = _passwordFocusNode.hasFocus;

      // Levantar manos al escribir contraseña
      _isHandsUp?.change(hasFocus);

      if (hasFocus) {
        _typingDebounce?.cancel();
        _isChecking?.change(false);
      }
    });
  }

  // Animación al escribir Email
  void _onEmailChanged(String value) {
    if (emailError != null) {
      setState(() {
        emailError = null;
      });
    }

    _isHandsUp?.change(false);
    _isChecking?.change(true);

    // 3.4 Movimiento de los ojos
    final double look = (value.length / 50.0 * 100).clamp(0.0, 100.0);

    _numLook?.value = look;

    // 3.5 Reiniciar temporizador
    _typingDebounce?.cancel();

    _typingDebounce = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _isChecking?.change(false);
    });
  }

  // Animación al escribir Password
  void _onPasswordChanged(String value) {
    if (passError != null) {
      setState(() {
        passError = null;
      });
    }

    _isChecking?.change(false);
    _isHandsUp?.change(true);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Animación Rive
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'assets/OS0g0RdO.riv',
                  onInit: _onRiveInit,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),

              // Campo Email
              TextField(
                controller: emailCtrl,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                onChanged: _onEmailChanged,
                decoration: InputDecoration(
                  errorText: emailError,
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Campo Contraseña
              TextField(
                controller: passCtrl,
                focusNode: _passwordFocusNode,
                obscureText: _isObscure,
                onChanged: _onPasswordChanged,
                decoration: InputDecoration(
                  errorText: passError,
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Recuperar contraseña
              SizedBox(
                width: size.width,
                child: const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.right,
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),

              const SizedBox(height: 10),

              // Botón Login
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onPressed: _isLoading ? null : _onLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
              ),

              const SizedBox(height: 20),

              // Registro
              SizedBox(
                width: size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        // Navegación pendiente
                      },
                      child: const Text(
                        'register',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();

    emailCtrl.dispose();
    passCtrl.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    super.dispose();
  }
}
