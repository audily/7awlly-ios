import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../backend/services_and_models/bottom_nav/models/notifications_model.dart';
import '../../../utils/custom_style.dart';
import '../../../utils/dimsensions.dart';
import '../../../utils/size.dart';
import '../../../widgets/labels/primary_text_widget.dart';

class ItemNotifcation extends StatelessWidget {
  final NotificationItem data;
  const ItemNotifcation({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.3),
      child: Row(
        mainAxisAlignment: mainSpaceBet,
        crossAxisAlignment: crossCenter,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: mainStart,
              crossAxisAlignment: crossCenter,
              children: [
                Container(
                  width: 50.h,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                        image: AssetImage("assets/images/app_launcher.png"),
                        fit: BoxFit.cover),
                    shape: BoxShape.circle,
                  ),
                ),
                addHorizontalSpace(10.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: mainCenter,
                    crossAxisAlignment: crossStart,
                    children: [
                      PrimaryTextWidget(
                        text: data.title,
                        style: CustomStyler.moneyDepositTitleStyle,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: PrimaryTextWidget(
                          text: data.message,
                          style: CustomStyler.moneyDepositDateStyle.copyWith(
                              decoration: TextDecoration.none,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          addHorizontalSpace(5.w),
          PrimaryTextWidget(
            text: DateFormat('yyyy-MM-dd hh:mm a')
                .format(DateTime.parse(data.createdAt.toString())),
            style: CustomStyler.aboutUsDesStyle,
          ),
          Divider(
            color: Colors.grey,
          )
        ],
      ),
    );
  }
}
