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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await ScreenUtil.ensureScreenSize();

    await Firebase.initializeApp();

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

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    runApp(const MyApp());

  } catch (e) {
    // Basic error screen (user-friendly)
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 50, color: Colors.red),
              SizedBox(height: 20),
              Text('حدث خطأ في التطبيق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('الرجاء إعادة فتح التطبيق', style: TextStyle(fontSize: 14)),
            ],
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
        initialBinding: BindingsBuilder(() {
          Get.put(SystemMaintenanceController(), permanent: true);
          Get.put(SettingController(), permanent: true);
          // Handle async initialization properly
          DynamicLanguage.init(url: ApiEndpoint.languageURL);
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