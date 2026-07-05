import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/journal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TradeJournalApp());
}

class TradeJournalApp extends StatelessWidget {
  const TradeJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.bg,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            );
          }
          if (snapshot.hasData) {
            return const JournalScreen();
          }
          return const SignInScreen();
        },
      ),
    );
  }
}
