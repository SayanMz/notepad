import 'package:flutter/material.dart';
import 'package:notepad/constants/ui_constants.dart';

/// ---------------------------------------------------------------------------
/// APP ROUTER (NAVIGATION + TRANSITIONS)
/// ---------------------------------------------------------------------------
///
/// ROLE:
/// - Centralizes all navigation animations
/// - Prevents duplication of PageRouteBuilder logic across UI
///
/// BENEFITS:
/// - Consistent transitions across app
/// - Easier to modify animations globally
/// - Cleaner UI code (HomePage, controllers)
///
/// DESIGN:
/// - Static utility class (no state)
/// - Returns Route objects for Navigator.push()
///

class AppRouter {
  /// -------------------------------------------------------------------------
  /// SLIDE TRANSITION (PRIMARY NAVIGATION)
  /// -------------------------------------------------------------------------
  ///
  /// BEHAVIOR:
  /// - New page slides in from right → center
  /// - Current page slightly shifts left (secondaryAnimation)
  ///
  /// RESULT:
  /// - Smooth, modern, iOS-like transition
  ///
  /// ANIMATION FLOW:
  /// - animation → controls incoming page
  /// - secondaryAnimation → controls outgoing page
  static Route slide(Widget page) {
    return PageRouteBuilder(
      transitionDuration: UIConstants.animationSlow,
      reverseTransitionDuration: UIConstants.animationMedium,

      /// Builds target page
      pageBuilder: (_, _, _) => page,

      /// Custom animation builder
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        /// Incoming page animation
        final inTween = Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        /// Outgoing page animation (subtle shift)
        final outTween = Tween(
          begin: Offset.zero,
          end: const Offset(-0.2, 0),
        ).chain(CurveTween(curve: Curves.easeOut));

        return SlideTransition(
          position: animation.drive(inTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(outTween),
            child: child,
          ),
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// FADE TRANSITION (SECONDARY NAVIGATION)
  /// -------------------------------------------------------------------------
  ///
  /// USE CASES:
  /// - Search screen
  /// - Dialog-like pages
  ///
  /// BEHAVIOR:
  /// - Page fades in on push
  /// - Page fades out on pop (reverse animation)
  static Route fade(Widget page) {
    return PageRouteBuilder(
      transitionDuration: UIConstants.animationMedium,
      reverseTransitionDuration: UIConstants.animationFast,

      pageBuilder: (_, _, _) => page,

      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

/// INTERVIEW NOTE:
/// This demonstrates separation of navigation concerns from UI layer