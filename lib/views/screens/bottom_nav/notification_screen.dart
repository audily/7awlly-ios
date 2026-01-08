import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/views/screens/drawer/drawer_screen.dart';

import '../../../backend/services_and_models/bottom_nav/models/notifications_model.dart'
    as notification;
import '../../../backend/utils/no_data_widget.dart';
import '../../../controller/btm_nav/bottom_navigation_controller.dart';
import '../../../widgets/labels/primary_text_widget.dart';
import 'item_notifcation.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      drawer: const DrawerScreen(),
      appBar: AppBar(
        backgroundColor: CustomColor.primaryColor,
        iconTheme: const IconThemeData(color: CustomColor.whiteColor),
        title: const PrimaryTextWidget(
            text: Strings.notification, color: CustomColor.whiteColor),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Get.find<BottomNavigationController>().notificationProcess();
        },
        child: _bodyWidget(context),
      ),
      // _bodyWidget(context),
    );
  }

  _bodyWidget(BuildContext context) {
    return _transactionHistoryListWidget(context);
  }

  _transactionHistoryListWidget(BuildContext context) {
    return Get.find<BottomNavigationController>()
            .notificationModel
            .message
            .success
            .notifications
            .isEmpty
        ? NoDataWidget()
        : ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: Get.find<BottomNavigationController>()
                .notificationModel
                .message
                .success
                .notifications
                .length,
            itemBuilder: (BuildContext context, int index) {
              notification.NotificationItem data =
                  Get.find<BottomNavigationController>()
                      .notificationModel
                      .message
                      .success
                      .notifications[index];
              return SizedBox(
                // height: 60.h,
                child: ItemNotifcation(data: data),
              );
            });
  }
}
