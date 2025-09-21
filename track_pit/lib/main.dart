import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_pit/core/db/database_helper.dart';
import 'package:track_pit/pages/billing/billing.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:track_pit/pages/billing/keys.dart';
import 'package:track_pit/pages/find_workshop.dart';
import 'package:track_pit/pages/service/book_service.dart';
import 'package:track_pit/pages/service/service.dart';
import 'package:track_pit/pages/service/service_details.dart';
import 'package:track_pit/pages/vehicle/add_vehicle.dart';
import 'package:track_pit/provider/auth_provider.dart';
import 'package:track_pit/provider/invoice_provider.dart';
import 'package:track_pit/provider/payment_provider.dart';
import 'package:track_pit/provider/service_provider.dart';
import 'package:track_pit/provider/user_provider.dart';
import 'package:track_pit/provider/vehicle_provider.dart';
import 'package:track_pit/core/constants/colors.dart';
import 'package:track_pit/pages/auth/signin.dart';
import 'package:track_pit/pages/auth/signup.dart';
import 'package:track_pit/pages/home/home_page.dart';
import 'package:track_pit/pages/more/more.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await DatabaseHelper.instance.database;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Stripe.publishableKey = publishableKey;
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const CarServiceApp(),
    ),
  );
}

class CarServiceApp extends StatelessWidget {
  const CarServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackPit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.secondaryGreen,
        ),
        useMaterial3: true,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(color: Colors.black87),
          elevation: 4,
        ),
      ),
      routes: {
        '/signin': (_) => const SignInPage(),
        '/signup': (_) => const SignUpPage(),
        '/home': (_) => const HomePage(),
        '/service_page': (_) => const ServicePage(),
        '/book_service': (_) => const BookServicePage(),
        '/billing': (_) => const BillingPage(),
        '/more': (_) => const MorePage(),
        '/service_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return ServiceDetailsPage(serviceId: args);
        },
        '/find_workshop': (_) => const FindWorkshopPage(),
        '/add_vehicle': (_) => const AddVehiclePage(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userProvider.stopListening();
        vehicleProvider.stopListening(notify: false);
        serviceProvider.stopListening(notify: false);
        invoiceProvider.stopListening(notify: false);
        paymentProvider.stopListening(notify: false);
      });
      return const SignInPage();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.startListening(auth.firebaseUser!.uid);
      vehicleProvider.startListening();
      serviceProvider.startListening();
      invoiceProvider.startListening();
      paymentProvider.startListening();
    });
    return const HomePage();
  }
}
