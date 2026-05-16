import 'package:flutter/material.dart';

/// Clef globale pour la navigation hors contexte strict (logout / première ouverture).
final class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
