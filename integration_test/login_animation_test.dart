import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:login_rive_animation/screens/login_screen.dart';
import 'package:rive/rive.dart';

Future<void> waitForAnimationDebounce(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// Permite cerrar la pantalla antes de vencer el debounce, sin depender
// de la velocidad del emulador.
class _PendingTimer implements Timer {
  _PendingTimer(this._callback);

  final void Function() _callback;
  bool _active = true;
  int _tick = 0;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() => _active = false;

  void elapse() {
    if (!_active) return;
    _active = false;
    _tick++;
    _callback();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bear asset responds to its login state machine', (tester) async {
    await RiveFile.initialize();
    final bytes = await rootBundle.load('assets/OS0g0RdO.riv');
    final file = RiveFile.import(bytes);
    final artboard = file.mainArtboard.instance();
    final states = <String>[];
    final controller = StateMachineController.fromArtboard(
      artboard,
      'Login Machine',
      onStateChange: (_, state) => states.add(state),
    );
    expect(controller, isNotNull);
    artboard.addController(controller!);
    addTearDown(controller.dispose);
    expect(controller.getBoolInput('isChecking'), isNotNull);
    expect(controller.getNumberInput('numLook'), isNotNull);
    expect(controller.getTriggerInput('trigSuccess'), isNotNull);
    expect(controller.getTriggerInput('trigFail'), isNotNull);
    for (var frame = 0; frame < 60; frame++) {
      artboard.advance(1 / 60);
    }
    await tester.pump();
    states.clear();
    controller.getBoolInput('isHandsUp')!.value = true;
    for (var frame = 0; frame < 60; frame++) {
      artboard.advance(1 / 60);
    }
    await tester.pump();
    expect(states, contains('Hands_up'));

    states.clear();
    controller.getBoolInput('isHandsUp')!.value = false;
    for (var frame = 0; frame < 60; frame++) {
      artboard.advance(1 / 60);
    }
    await tester.pump();
    controller.getBoolInput('isChecking')!.value = true;
    controller.getNumberInput('numLook')!.value = 50;
    for (var frame = 0; frame < 60; frame++) {
      artboard.advance(1 / 60);
    }
    await tester.pump();
    expect(states, contains('hands_down'));
    expect(
      states,
      contains('unknown'),
    ); // El seguimiento usa un estado de mezcla.
  });

  testWidgets('email, keyboard focus and password visibility drive the bear', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    for (var frame = 0; frame < 30; frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(Rive).evaluate().isNotEmpty) break;
    }
    expect(find.byType(Rive), findsOneWidget);
    final artboard = tester.widget<Rive>(find.byType(Rive)).artboard;
    final controller = artboard.animationControllers
        .whereType<StateMachineController>()
        .single;
    final email = find.byType(TextField).first;
    await tester.tap(email);
    await tester.enterText(email, 'oso@example.com');
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isChecking')!.value, isTrue);
    expect(controller.getBoolInput('isHandsUp')!.value, isFalse);
    expect(controller.getNumberInput('numLook')!.value, 15);
    await tester.pump(const Duration(milliseconds: 3100));
    expect(controller.getBoolInput('isChecking')!.value, isFalse);
    expect(tester.widget<TextField>(email).focusNode!.hasFocus, isTrue);
    final emailController = tester.widget<TextField>(email).controller!;
    emailController.selection = const TextSelection.collapsed(offset: 3);
    await waitForAnimationDebounce(tester);
    expect(controller.getNumberInput('numLook')!.value, 3);
    expect(controller.getBoolInput('isChecking')!.value, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isChecking')!.value, isFalse);
    expect(controller.getBoolInput('isHandsUp')!.value, isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isHandsUp')!.value, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isHandsUp')!.value, isTrue);
    await tester.pump(const Duration(milliseconds: 3100));
    expect(controller.getBoolInput('isHandsUp')!.value, isFalse);
    final password = find.byType(TextField).at(1);
    expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
    await tester.enterText(password, 'nueva actividad');
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isHandsUp')!.value, isTrue);
    FocusManager.instance.primaryFocus?.unfocus();
    await waitForAnimationDebounce(tester);
    expect(controller.getBoolInput('isChecking')!.value, isFalse);
    expect(controller.getBoolInput('isHandsUp')!.value, isFalse);

    final pendingTimers = <_PendingTimer>[];
    runZoned(
      () {
        emailController.text = 'primer cambio';
        emailController.text = 'ultimo cambio';
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          if (duration == const Duration(milliseconds: 80)) {
            final timer = _PendingTimer(zone.bindCallback(callback));
            pendingTimers.add(timer);
            return timer;
          }
          return parent.createTimer(zone, duration, callback);
        },
      ),
    );
    expect(pendingTimers, hasLength(2));
    expect(pendingTimers.first.isActive, isFalse);
    expect(pendingTimers.last.isActive, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(pendingTimers.last.isActive, isFalse);
    for (final timer in pendingTimers) {
      timer.elapse();
      expect(timer.tick, 0);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
