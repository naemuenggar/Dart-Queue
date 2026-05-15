import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/queue_repository.dart';
import 'data/services/deeplink_service.dart';
import 'data/services/notification_service.dart';
import 'presentation/screens/admin/dev_tools_screen.dart';
import 'presentation/screens/admin/table_qr_screen.dart';
import 'presentation/screens/customer/home_screen.dart';
import 'presentation/screens/customer/take_ticket_screen.dart';
import 'presentation/screens/operator/operator_dashboard.dart';
import 'presentation/screens/operator/scanner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase. Setelah `flutterfire configure`, ganti dengan:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // Offline persistence — penting buat WiFi restoran yang flaky.
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  await NotificationService.instance.init();
  await DeepLinkService.instance.init();

  runApp(const RestoQueueApp());
}

class RestoQueueApp extends StatelessWidget {
  const RestoQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<QueueRepository>(
          create: (_) => QueueRepository(FirebaseFirestore.instance),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: DeepLinkService.instance.navigatorKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: '/',
        routes: {
          '/': (_) => const CustomerHomeScreen(),
          '/take': (_) => const TakeTicketScreen(),
          '/operator': (_) => const OperatorDashboard(),
          '/operator/scan': (_) => const OperatorScannerScreen(),
          '/admin/qr': (_) => const TableQrScreen(),
          if (kDebugMode) '/dev': (_) => const DevToolsScreen(),
        },
      ),
    );
  }
}
