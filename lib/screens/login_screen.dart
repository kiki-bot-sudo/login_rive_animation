import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _animationDebounce = Duration(milliseconds: 80);
  static const _idleDelay = Duration(seconds: 3);
  Timer? _animationTimer;
  Timer? _idleTimer;
  bool _isIdle = false;

  //control para mostrar u ocultar la contraseña
  bool _isObscureText = true;

  //1.1 Crear el cerebro de la animacion
  StateMachineController? _controller;

  //1.2 SMI: StateMachineInput / Entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMINumber? _numLook;

  //2.1 Crear variables para focusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _emailController = TextEditingController();

  //2.2 Crear los listeners (Oyentes/chismosos)
  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_scheduleAnimation);
    _passwordFocusNode.addListener(_scheduleAnimation);
    _emailController.addListener(_scheduleAnimation);
  }

  void _scheduleAnimation() {
    _isIdle = false;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDelay, () {
      _idleTimer = null;
      if (!mounted) return;
      _isIdle = true;
      _animationTimer?.cancel();
      _animationTimer = null;
      _syncAnimation();
    });
    _animationTimer?.cancel();
    _animationTimer = Timer(_animationDebounce, () {
      _animationTimer = null;
      if (mounted) _syncAnimation();
    });
  }

  void _syncAnimation() {
    _isChecking?.change(!_isIdle && _emailFocusNode.hasFocus);
    _isHandsUp?.change(
      !_isIdle && _passwordFocusNode.hasFocus && _isObscureText,
    );
    final selection = _emailController.selection;
    final position = selection.isValid
        ? selection.extentOffset
        : _emailController.text.length;
    _numLook?.change(position.clamp(0, 100).toDouble());
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
    );
    if (controller == null) {
      throw StateError('El archivo Rive no contiene Login Machine.');
    }

    final isChecking = controller.getBoolInput('isChecking');
    final isHandsUp = controller.getBoolInput('isHandsUp');
    final numLook = controller.getNumberInput('numLook');
    if (isChecking == null || isHandsUp == null || numLook == null) {
      controller.dispose();
      throw StateError(
        'Faltan las entradas de mirada o manos en Login Machine.',
      );
    }

    _controller?.dispose();
    _controller = controller;
    _isChecking = isChecking;
    _isHandsUp = isHandsUp;
    _numLook = numLook;
    artboard.addController(controller);
    // El usuario puede enfocar un campo antes de que termine de cargar Rive.
    _syncAnimation();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _idleTimer?.cancel();
    _controller?.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Obtain the size of the screen .i.
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/OS0g0RdO.riv',
                    onInit: _onRiveInit,
                  ),
                ),

                const SizedBox(height: 10),
                //Email
                TextField(
                  focusNode: _emailFocusNode,
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  onTapOutside: (_) => _emailFocusNode.unfocus(),
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
                  focusNode: _passwordFocusNode,
                  onChanged: (_) => _scheduleAnimation(),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _passwordFocusNode.unfocus(),
                  onTapOutside: (_) => _passwordFocusNode.unfocus(),
                  obscureText: _isObscureText,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureText
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscureText = !_isObscureText;
                        });
                        _scheduleAnimation();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
