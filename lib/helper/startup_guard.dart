import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helpers that keep app start-up from ever blocking or crashing before
/// `runApp`.
///
/// Why: on iOS a Firebase configuration problem (a GoogleService-Info.plist
/// that does not match the Dart options, or one that is missing from the
/// bundle) made `Firebase.initializeApp` throw. Because that happens before
/// `runApp`, users only saw a permanent black screen. Start-up steps that are
/// not essential for drawing the first frame must therefore be guarded.

/// Initialises Firebase safely. Returns true when a usable default Firebase
/// app exists afterwards.
///
/// * [hasApps]   – whether a default app is already configured (native side)
/// * [initialize]– performs `Firebase.initializeApp(...)`
/// * [fallbackApp] – tries to fetch the default app after a failure (it may
///   have been configured natively); should throw when there is none.
Future<bool> initFirebaseSafely({
  required bool Function() hasApps,
  required Future<void> Function() initialize,
  required void Function() fallbackApp,
  Duration timeout = const Duration(seconds: 10),
  void Function(Object error)? onError,
}) async {
  try {
    if (!hasApps()) {
      await initialize().timeout(timeout);
    }
    return true;
  } catch (e) {
    (onError ?? (Object err) => debugPrint('Firebase init failed: $err'))(e);
    try {
      fallbackApp();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Runs a non-essential start-up step. Returns its value, or null when it
/// failed or took longer than [timeout]. Never throws.
Future<T?> guardedStep<T>(
  Future<T> Function() step, {
  Duration timeout = const Duration(seconds: 5),
  String label = 'startup step',
  void Function(Object error)? onError,
}) async {
  try {
    return await step().timeout(timeout);
  } catch (e) {
    (onError ?? (Object err) => debugPrint('$label failed: $err'))(e);
    return null;
  }
}
