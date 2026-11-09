import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //3.1 Importar el timer

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {


  //Control para mostrar/ocultar contraseña
  bool _isObscure = true;

  //1.1 Crear el cerebro de la animación
  StateMachineController? _controller;

  //paso 1.2 SMI: StateMachineInput / Entrada de maquina de estado
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;


  //3.2 TImer para detener la mirada al dejar de escribir
  Timer? _typingDebounce;

  // 2.1 Crear variables para FocusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  //4.1 Controller 
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para mostrar en la UI
  String? emailError;
  String? passError;

   // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.[a-z])(?=.[A-Z])(?=.\d)(?=.[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Accion al boton
  void _onLogin(){
    //De lo que escribio el usuario, quita espacios en blanco
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    //Recalcular errores
    final emaiLTypedError = isValidEmail(email) ? null : 'Email no valido';
    final passTypedError = isValidPassword(pass) ? null : 'Contraseña no valida';

    //4.5 Avisar que hubo un cambio
    setState(() {
      emailError = emaiLTypedError;
      passError = passTypedError;
    });
  }

  //4.6 Cerrar el teclado y bajar manos
  FocusScope.of(context).unfocus();
  _typingDebounce?.cancel();
  _isHandsUp?.change(false);
  _isCheking?.change(false);
  _numLook.value = 50; //mirada neutral

  //4.7 Activar triggers
  if(emailTypedError == null && passwordTypedError == null){   
    _trigSuccess?.fire();
  } else {
    _trigFail?.fire();
  }  

  //2.2 Crear los listeners (oyentes/chismosos)

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener((){
      if (_emailFocusNode.hasFocus) {
        if(_isHandsUp != null) {
          //ojos sin cerrar
          _isHandsUp?.change(false);

          //3.3 Mirada neutral
          _numLook?.value = 50; //mirada neutral
        }
      }
    });
    _passwordFocusNode.addListener((){
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }
  

  @override
  Widget build(BuildContext context) {
    //Obtener el tamaño de la pantalla del dispositivo
    final Size size = MediaQuery.of(context).size;


    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20 ),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                  'assets/OS0g0RdO.riv', 
                  stateMachines: ['Login Machine'],
                  //1.3 Vincular la animacion
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard, 
                      'Login Machine',
                      );
                    //1.4 Verificar que inicio bien
                    if (_controller == null) return;


                    //Agregar el controlador al tablero
                    artboard.addController(_controller!);

                    //Vincular las variables
                    _isChecking = _controller!.findSMI('isChecking');
                    _isHandsUp = _controller!.findSMI('isHandsUp');
                    _trigSuccess = _controller!.findSMI('trigSuccess');
                    _trigFail = _controller!.findSMI('trigFail');
                    _numLook = _controller!.findSMI('numLook');




                  }

                  )
                  ),
                  //Para separar
                  const SizedBox(height: 10),
                  //Email
                  //4.8 Vincular controller
                    controller: emailCtrl,
                  TextField(
                    //2.3 asignar foco al campo de texto
                    focusNode: _emailFocusNode,

                    //1.5 Vincular a campos de texto
                    onChanged: (value){
                      if (_isHandsUp != null){
                        //no tapes los ojos
                        //_isHandsUp!.change(false); //Esto ya esta puesto arriba en 2.1
                      }

                      //si isCheking es null
                      if (_isChecking == null) return;

                      //Activar el modo chismoso
                      _isChecking!.change(true);

                      //3.4 Implementar numLook
                      //Ajustes del 0 al 100
                      //80 es medida de calibracion. clamp es el rango "(abrazadera)"
                      final look = (value.length / 50.0 * 100).clamp(0.0, 100.0);
                      _numLook?.value = look;

                      //3.5 Debounce: si  vuelve a teclar reinicia el contador
                      _typingDebounce?.cancel(); //cancelamos cualquier timer existente
                      //crear nuevo timer
                      _typingDebounce = Timer(const Duration(seconds: 3),(){
                        //si se cierra la pantalla (!mounted)
                        if(!mounted) return;
                        _isChecking?.change(false);
                      });

                    },


                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      //4.9 Mostar el texto de error
                      errorText: emailError,
                      hintText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      
                      ),
                  ),
                  SizedBox(height: 10),
                  //Constraseña
                  TextField(
                    //4.8 Vincular controller
                    controller: passCtrl,
                    //2.3 Asignar foco al campo de texto
                    focusNode: _passwordFocusNode,
                    onChanged: (value){
                    
                    
                      //1.5 Vincular a campos de texto
                      if (_isChecking != null){
                        //no tapes los ojos
                        //_isChecking!.change(false);
                      }

                      //si isCheking es null
                      if (_isHandsUp == null) return;

                      //Activar el modo chismoso
                      _isHandsUp!.change(true);
                    },
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      //4.9 Mostar el texto de error
                      errorText: passError,
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ), // El icono se cierra aquí correctamente
                      onPressed: () {
                        // Para refrescar el icono
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
                  SizedBox(height: 10),
                  SizedBox(
                    width: size.width,
                    child: const Text(
                      "Forgot Password?",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  MaterialButton(
                    minWidth: size.width,
                    height: 50,
                    color: Colors.blueAccent,
                    shape: ROundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: _onLogin,
                    child: Text("Login", style: TextStyle(color: Colors.white))
                  ),
                  const SizedBox(height: 20),
                  //No tienes cuenta? Registrate
                  SizedBox(
                    width: size.width,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: (){},
                          child: const Text("register", style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold
                          ),
                          )
                        )
                      ],
                    )
                  )

              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose(){
    //4.10 Liberar controllers
    emailCtrl.dispose();
    passCtrl.dispose();
    //paso 2.4 liberar recursos de los FocusNode
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    //3.5 Liberar Timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}