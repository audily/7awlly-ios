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
  print('🚀 APP STARTING - If you see this, Flutter engine loaded');

  try {
    // await initUniLinks();
    await ScreenUtil.ensureScreenSize();
    // InternetCheckDependencyInjection.init();
    await GetStorage.init();
    WidgetsFlutterBinding.ensureInitialized();

    print('✅ Basic initialization done');

    // Try Firebase - this might be crashing
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');
    } catch (e) {
      print('❌ Firebase error: $e');
      // Continue without Firebase for testing
    }

    try {
      await FCMConfig.instance.init(
        onBackgroundMessage: _firebaseMessagingBackgroundHandler,
        defaultAndroidForegroundIcon:
        '@mipmap/ic_launcher', //default is @mipmap/ic_launcher
        defaultAndroidChannel: AndroidNotificationChannel(
          'high_importance_channel', // same as value from android setup
          'Fcm config',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
      );
      print('✅ FCM initialized');
    } catch (e) {
      print('❌ FCM error: $e');
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light));

    print('✅ All initialization complete, running app...');
    runApp(const MyApp());
    print('✅ App running');

  } catch (e, s) {
    print('❌ MAIN FUNCTION ERROR: $e');
    print('📝 Stack: $s');

    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔥 CRASH ON STARTUP', style: TextStyle(fontSize: 24, color: Colors.red)),
                  SizedBox(height: 20),
                  Text('Error: $e', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Text('Stack trace in console', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
          /*ThemeData.light().textTheme.apply(
                fontFamily: 'Roboto',
              ),*/
          bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.transparent),
        ),
        initialRoute: Routes.splashScreen,
        getPages: Routes.list,
        navigatorKey: Get.key,
        initialBinding: BindingsBuilder(() async {
          Get.put(SystemMaintenanceController(), permanent: true);
          Get.put(SettingController(), permanent: true);
          await DynamicLanguage.init(url: ApiEndpoint.languageURL);
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
