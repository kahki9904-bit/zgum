import 'dart:async';

final emailAuthCompletedController = StreamController<void>.broadcast();
final emailAuthErrorController = StreamController<String>.broadcast();
final emailRecoveryConfirmationController = StreamController<String>.broadcast();
