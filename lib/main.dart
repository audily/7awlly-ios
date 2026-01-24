import 'dart:io';
import 'package:dynamic_languages/dynamic_languages.dart';
import 'package:fcm_config/fcm_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walletium/routes/routes.dart';

import 'backend/services_and_models/api_endpoint.dart';
import 'backend/utils/maintenance/maintenance_dialog.dart';
import 'controller/settings_controller.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Create log file for crashes
  final logFile = File('${Directory.systemTemp.path}/app_crash.log');

  try {
    print('🚀 APP STARTING - Phase 1: Basic init');

    // await initUniLinks();
    await ScreenUtil.ensureScreenSize();
    // InternetCheckDependencyInjection.init();
    await GetStorage.init();
    WidgetsFlutterBinding.ensureInitialized();

    print('✅ Phase 1 complete');

    // Phase 2: Firebase
    print('🚀 Phase 2: Firebase init');
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Phase 3: FCM
    print('🚀 Phase 3: FCM init');
    await FCMConfig.instance.init(
      onBackgroundMessage: _firebaseMessagingBackgroundHandler,
      defaultAndroidForegroundIcon:
      '@mipmap/ic_launcher',
      defaultAndroidChannel: AndroidNotificationChannel(
        'high_importance_channel',
        'Fcm config',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    );
    print('✅ FCM initialized');

    // Phase 4: System settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));

    print('✅ All initialization complete, running app...');

    // Run the app
    runApp(const MyApp());

    print('✅ App is running');

  } catch (e, s) {
    // Write crash to log file
    final errorMessage = '''
    ===== CRASH REPORT =====
    Time: ${DateTime.now()}
    Error: $e
    Stack Trace: $s
    ========================
    ''';

    print('❌ CRASH DETECTED: $e');
    print('📝 Stack trace written to crash log');

    try {
      await logFile.writeAsString(errorMessage);
      print('✅ Crash log saved to: ${logFile.path}');
    } catch (logError) {
      print('❌ Failed to write log: $logError');
    }

    // Show error screen (for testing)
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 20),
                  Text('App Crashed on Startup',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.black12,
                    child: Text('$e',
                        style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                  SizedBox(height: 20),
                  Text('Check crash log for details',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      builder: (_, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.cairoTextTheme(),
          bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.transparent),
        ),
        initialRoute: Routes.splashScreen,
        getPages: Routes.list,
        navigatorKey: Get.key,
        initialBinding: BindingsBuilder(() async {
          print('🚀 InitialBinding: Starting GetX controllers');
          try {
            Get.put(SystemMaintenanceController(), permanent: true);
            Get.put(SettingController(), permanent: true);
            await DynamicLanguage.init(url: ApiEndpoint.languageURL);
            print('✅ InitialBinding complete');
          } catch (e, s) {
            print('❌ InitialBinding error: $e');
            print('Stack: $s');
            rethrow;
          }
        }),
        builder: (context, widget) {
          ScreenUtil.init(context);
          return Obx(
                () => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.0)),
              child: Directionality(
                textDirection: DynamicLanguage.isLoading
                    ? TextDirection.ltr
                    : DynamicLanguage.languageDirection,
                child: widget!,
              ),
            ),
          );
        },
      ),
    );
  }
}