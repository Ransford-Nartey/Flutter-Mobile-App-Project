import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../../../core/services/first_time_service.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../screens/auth_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../admin/providers/admin_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirstTimeService.isFirstTime(),
      builder: (context, firstTimeSnapshot) {
        if (firstTimeSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If it's the first time, show onboarding
        if (firstTimeSnapshot.data == true) {
          return const OnboardingScreen();
        }

        // Not first time, check authentication status
        return StreamBuilder<firebase_auth.User?>(
          stream: AuthService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              // User is authenticated, check if admin
              return Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  if (adminProvider.isLoading) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (adminProvider.isAdmin) {
                    return const AdminDashboardScreen();
                  }

                  // User is not admin, show home screen
                  return const HomeScreen();
                },
              );
            }

            // User is not authenticated, show auth screen directly
            return const AuthScreen();
          },
        );
      },
    );
  }
}
