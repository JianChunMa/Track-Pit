import 'package:flutter/material.dart';
import 'widgets/bottom_navbar.dart';
import 'core/constants/colors.dart';
import 'widgets/appbar.dart';
import 'pages/home/home_page.dart';
import '/pages/auth/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '/pages/auth/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/pages/more/more_page.dart';
import '/pages/vehicle/add_vehicle.dart';
import '/pages/vehicle/my_vehicles.dart';
import '/pages/vehicle/swap_vehicle.dart';
import '/pages/book_service/book_service.dart';
import '/pages/book_service/service_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CarServiceApp());
}

class CarServiceApp extends StatelessWidget {
  const CarServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackPit',
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.black87),
          elevation: 4,
        ), // Explicit PopupMenuTheme to avoid dynamic lookups
      ),
      routes: {
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignUpPage(),
        '/home': (_) => HomePage(),
        '/more': (_) => const MorePage(),
        '/addvehicle': (_) => const AddVehiclePage(),
        '/my_vehicles': (_) => MyVehiclesPage(),
        '/swap_vehicle': (_) => const SwapVehiclePage(),
        '/service_Page':(_)=> const ServicesPage(),
         '/bookService': (context) => const BookServicePage(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.data != null) return HomePage();
          return const SignInPage();
        },
      ),
    );
  }
}