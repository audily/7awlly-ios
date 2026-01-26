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
  String errorMessage = '';
  StackTrace? errorStackTrace;

  try {
    print('🚀 APP STARTING');

    // Basic initialization
    await ScreenUtil.ensureScreenSize();
    await GetStorage.init();
    WidgetsFlutterBinding.ensureInitialized();

    print('✅ Basic init complete');

    // Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // FCM
    await FCMConfig.instance.init(
      onBackgroundMessage: _firebaseMessagingBackgroundHandler,
      defaultAndroidForegroundIcon: '@mipmap/ic_launcher',
      defaultAndroidChannel: AndroidNotificationChannel(
        'high_importance_channel',
        'Fcm config',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
    );
    print('✅ FCM initialized');

    // System settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));

    print('✅ All initialization complete');

    // Run the app
    runApp(const MyApp());

  } catch (e, s) {
    errorMessage = 'CRASH: $e';
    errorStackTrace = s;

    print('❌ CRASH DETECTED: $e');
    print('📝 Stack trace: $s');

    // Show FULL error on screen
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.error, size: 40, color: Colors.red),
                      SizedBox(width: 10),
                      Text('🔥 APP CRASHED ON STARTUP',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Error message
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 10),
                        SelectableText(
                          errorMessage,
                          style: TextStyle(fontSize: 14, fontFamily: 'Monospace'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Stack trace (collapsible)
                  ExpansionTile(
                    title: Text('Stack Trace (Click to expand)', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: SelectableText(
                          errorStackTrace.toString(),
                          style: TextStyle(fontSize: 10, fontFamily: 'Monospace'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📱 What to do:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 10),
                        Text('1. Take a screenshot of this screen', style: TextStyle(fontSize: 14)),
                        Text('2. Send it to the developer', style: TextStyle(fontSize: 14)),
                        Text('3. Restart the app', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // Restart button
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                      onPressed: () {
                        // In a real app, you might want to restart
                        // For now, just show message
                        Get.snackbar('Info', 'Please re-open the app');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ),
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
            rethrow; // This will be caught by outer try-catch
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