import 'package:flutter/material.dart';
import 'widgets/bottom_navbar.dart';
import 'core/constants/colors.dart';
import 'widgets/appbar.dart';
import 'pages/home/home_page.dart';
import 'package:assignment/pages/auth/signup.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:assignment/pages/auth/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignment/pages/more/more_page.dart';
import 'package:assignment/pages/vehicle/add_vehicle.dart';
import 'package:assignment/pages/vehicle/my_vehicles.dart';

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
      routes: {
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignUpPage(),

        '/home'  : (_) =>  HomePage(),
        '/more' : (_) => const MorePage(),

        '/addvehicle' :(_) => const AddVehiclePage(),
        '/my_vehicles':(_) => const MyVehiclesPage(),
      },
      // Auth gate: if already signed in, go straight to Home
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.data != null) return  HomePage();
          return const SignInPage();
        },
      ),
    );
  }
}

//
// class HomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           CustomAppBar(userName: "Mr. Lim Yuet Yang"), // 👈 reused here
//           SizedBox(height: 50),
//           Expanded(
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset('lib/assets/images/findworkshop.png'),
//                   Text(
//                     "Explore",
//                     style: TextStyle(
//                       color: AppColors.primaryGreen,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     "Find nearby workshops from you",
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: 0,
//         onTap: (index) {
//           // navigation handler
//         },
//       ),
//     );
//   }
// }
