import 'dart:io';

import 'package:dynamic_languages/dynamic_languages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/backend/model/common/common_success_model.dart';
import 'package:walletium/views/screens/success_screen.dart';

import '../../backend/services_and_models/add_money/add_money_index_model.dart';
import '../../backend/services_and_models/withdraw/withdraw_money_index_model.dart';
import '../../backend/services_and_models/withdraw/withdraw_money_submit_model.dart';
import '../../backend/services_and_models/withdraw/withdraw_service.dart';
import '../../backend/utils/api_method.dart';
import '../../routes/routes.dart';
import '../../utils/custom_color.dart';
import '../../utils/dimsensions.dart';
import '../../utils/size.dart';
import '../../utils/strings.dart';
import '../../widgets/custom_upload_file_widget.dart';
import '../../widgets/dropdown/custom_dropdown_widget.dart';
import '../../widgets/inputs/input_text_field.dart';
import '../../widgets/labels/text_labels_widget.dart';
import '../profile/kyc_controller.dart';

class WithdrawController extends GetxController with WithdrawService {
  final amountController = TextEditingController();

  late Rx<UserWallet> selectedWallet;
  late Rx<GatewayCurrencyWithdraw> selectedGateway;

  RxDouble exchangeRate = 0.0.obs;
  RxDouble min = 0.0.obs;
  RxDouble max = 0.0.obs;
  RxDouble totalCharge = 0.0.obs;

  calculation(String amount) {
    exchangeRate.value = selectedGateway.value.rate / selectedWallet.value.rate;
    min.value = selectedGateway.value.minLimit / exchangeRate.value;
    max.value = selectedGateway.value.maxLimit / exchangeRate.value;
    if (amount.isNotEmpty) {
      double enteredAmount = double.parse(amount);
      totalCharge.value = selectedGateway.value.fixedCharge +
          ((enteredAmount * exchangeRate.value) *
              (selectedGateway.value.percentCharge / 100));
    } else {
      totalCharge.value = selectedGateway.value.fixedCharge;
    }
  }

  ///-------------------------------------------------------------------------
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  late WithdrawMoneyIndexModel _withdrawMoneyIndexModel;
  WithdrawMoneyIndexModel get withdrawMoneyIndexModel =>
      _withdrawMoneyIndexModel;

  ///* Get WithdrawMoneyIndex in process
  Future<WithdrawMoneyIndexModel> withdrawMoneyIndexProcess() async {
    _isLoading.value = true;
    update();
    await withdrawMoneyIndexProcessApi().then((value) {
      _withdrawMoneyIndexModel = value!;

      selectedWallet = _withdrawMoneyIndexModel.data.userWallet.first.obs;

      selectedGateway =
          _withdrawMoneyIndexModel.data.gatewayCurrencies.first.obs;
      convertCurrencyCodeToEmoji(selectedGateway.value.currencyCode);
      withdrawMoneyIndexModel.data.userWallet.firstWhere((element) {
        if (element.currencyCode == selectedGateway.value.currencyCode) {
          selectedWallet.value = element;
          //  amountController.text = selectedWallet.value.balance.toString();
          calculation("");
        }
        return element.currencyCode == selectedGateway.value.currencyCode;
      });
      changeFilterWallet(UserWallet(
          name: selectedGateway.value.name,
          balance: selectedWallet.value.balance,
          currencyCode: selectedGateway.value.currencyCode,
          currencySymbol: selectedGateway.value.currencySymbol,
          currencyType: "",
          rate: selectedGateway.value.rate,
          flag: selectedGateway.value.image,
          imagePath: selectedGateway.value.image));
      update();

      calculation("");
      Future.delayed(Duration(milliseconds: 200), () {
        Get.toNamed(Routes.withdrawScreen);
      });

      _isLoading.value = false;
      update();
    }).catchError((onError) {
      log.e(onError);
    });
    _isLoading.value = false;
    update();
    return _withdrawMoneyIndexModel;
  }

  ///-------------------------------------------------------------------------

  final _isSubmitLoading = false.obs;
  bool get isSubmitLoading => _isSubmitLoading.value;

  late WithdrawMoneySubmitModel _withdrawMoneySubmitModel;
  WithdrawMoneySubmitModel get withdrawMoneySubmitModel =>
      _withdrawMoneySubmitModel;

  ///* WithdrawMoneySubmitModel in process
  Future<WithdrawMoneySubmitModel> withdrawMoneySubmitProcess() async {
    _isSubmitLoading.value = true;
    update();
    Map<String, dynamic> inputBody = {
      'amount': amountController.text,
      'sender_currency': selectedWallet.value.currencyCode,
      'gateway_currency': selectedGateway.value.alias
    };
    await withdrawMoneySubmitProcessApi(body: inputBody).then((value) {
      _withdrawMoneySubmitModel = value!;

      _getDynamicInputField(_withdrawMoneySubmitModel.data.inputFields);
      Get.toNamed(Routes.withdrawMoneyDetailsScreen);

      _isSubmitLoading.value = false;
      update();
    }).catchError((onError) {
      log.e(onError);
    });
    _isSubmitLoading.value = false;
    update();
    return _withdrawMoneySubmitModel;
  }

  List<TextEditingController> inputFieldControllers = [];
  RxList inputFields = [].obs;
  RxList inputFileFields = [].obs;

  final selectedIDType = "".obs;
  List<IdTypeModel> idTypeList = [];

  int totalFile = 0;
  List<String> listImagePath = [];
  List<String> listFieldName = [];
  RxBool hasFile = false.obs;

  late Rx<IdTypeModel> selectedValue;

  void _getDynamicInputField(List<InputField> data) {
    inputFieldControllers.clear();
    inputFields.clear();
    inputFileFields.clear();
    idTypeList.clear();
    listImagePath.clear();
    listFieldName.clear();

    for (int item = 0; item < data.length; item++) {
      var textEditingController = TextEditingController();
      inputFieldControllers.add(textEditingController);
      if (data[item].type.contains('select')) {
        hasFile.value = true;
        selectedIDType.value = data[item].validation.options.first.toString();
        inputFieldControllers[item].text = selectedIDType.value;
        for (var element in data[item].validation.options) {
          idTypeList.add(IdTypeModel("", element));
        }
        selectedValue = idTypeList.first.obs;
        inputFields.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: Dimensions.marginSize * 0.5),
                    child: CustomDropDown<IdTypeModel>(
                      selectedValue: selectedValue.value,
                      items: idTypeList,
                      title: data[item].label,
                      hint: selectedIDType.value.isEmpty
                          ? Strings.selectIDType
                          : selectedIDType.value,
                      onChanged: (value) {
                        selectedIDType.value = value!.title;
                      },
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingHorizontalSize * 0.25,
                      ),
                      titleTextColor: CustomColor.textColor,
                      selectedTextColor: CustomColor.whiteColor,
                      hintTextColor: CustomColor.textColor,
                      borderEnable: true,
                      dropDownFieldColor: Colors.transparent,
                      decorationColor: CustomColor.textColor,
                    ),
                  )),
              addVerticalSpace(Dimensions.paddingVerticalSize * .3),
            ],
          ),
        );
      } else if (data[item].type.contains('file')) {
        totalFile++;
        hasFile.value = true;
        inputFileFields.add(
          Column(
            mainAxisAlignment: mainStart,
            crossAxisAlignment: crossStart,
            children: [
              CustomUploadFileWidget(
                labelText: data[item].label,
                hint: data[item].validation.mimes.join(","),
                onTap: (File value) {
                  updateImageData(data[item].name, value.path);
                },
              ),
            ],
          ),
        );
      } else if (data[item].type.contains('textarea')) {
        inputFields.add(
          Column(
            mainAxisAlignment: mainStart,
            crossAxisAlignment: crossStart,
            children: [
              TextLabelsWidget(
                textLabels: data[item].label,
                textColor: CustomColor.textColor, textStyle:TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                // Note: color here will override textColor if both are defined,
                // so ensure textColor is handled inside the widget.
              ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: Dimensions.marginSize * 0.5),
                child: InputTextField(
                  maxLine: 3,
                  controller: inputFieldControllers[item],
                  hintText: DynamicLanguage.isLoading
                      ? ""
                      : DynamicLanguage.key(Strings.enter) + data[item].label,
                  borderColor: CustomColor.gray,
                  backgroundColor: Colors.transparent,
                  hintTextColor: CustomColor.textColor,
                ),
              ),
            ],
          ),
        );
      } else if (data[item].type == 'text') {
        inputFields.add(
          Column(
            mainAxisAlignment: mainStart,
            crossAxisAlignment: crossStart,
            children: [
              TextLabelsWidget(
                textLabels: data[item].label,
                textColor: CustomColor.textColor, textStyle: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                // Note: color here will override textColor if both are defined,
                // so ensure textColor is handled inside the widget.
              ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: Dimensions.marginSize * 0.5),
                child: InputTextField(
                  controller: inputFieldControllers[item],
                  hintText: DynamicLanguage.isLoading
                      ? ""
                      : DynamicLanguage.key(Strings.enter) + data[item].label,
                  borderColor: CustomColor.gray,
                  backgroundColor: Colors.transparent,
                  hintTextColor: CustomColor.textColor,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  updateImageData(String fieldName, String imagePath) {
    if (listFieldName.contains(fieldName)) {
      int itemIndex = listFieldName.indexOf(fieldName);
      listImagePath[itemIndex] = imagePath;
    } else {
      listFieldName.add(fieldName);
      listImagePath.add(imagePath);
    }
    update();
  }

  ///-------------------------------------------------------------------------
  final _isConfirmLoading = false.obs;
  bool get isConfirmLoading => _isConfirmLoading.value;

  late CommonSuccessModel _withdrawMoneyConfirmModel;
  CommonSuccessModel get withdrawMoneyConfirmModel =>
      _withdrawMoneyConfirmModel;

  ///* WithdrawMoneyConfirm in process
  Future<CommonSuccessModel> withdrawMoneyConfirmProcess() async {
    _isConfirmLoading.value = true;
    update();
    Map<String, String> inputBody = {
      "trx": _withdrawMoneySubmitModel.data.paymentInformations.trx
    };

    final data = _withdrawMoneySubmitModel.data.inputFields;

    for (int i = 0; i < data.length; i += 1) {
      if (data[i].type != 'file') {
        inputBody[data[i].name] = inputFieldControllers[i].text;
      }
    }
    await withdrawMoneyConfirmProcessApi(
            body: inputBody, fieldList: listFieldName, pathList: listImagePath)
        .then((value) {
      _withdrawMoneyConfirmModel = value!;

      inputFields.clear();
      listImagePath.clear();
      listFieldName.clear();
      inputFieldControllers.clear();

      Get.to(SuccessScreen(
          title: Strings.withdrawMoney,
          msg: _withdrawMoneyConfirmModel.message.success.first,
          onTap: () {
            Get.offAllNamed(Routes.bottomNavigationScreen);
          }));
      _isConfirmLoading.value = false;
      update();
    }).catchError((onError) {
      log.e(onError);
    });
    _isConfirmLoading.value = false;
    update();
    return _withdrawMoneyConfirmModel;
  }

  changeFilterWallet(UserWallet value) {
    selectedWallet.value = value;
    //filteredWalletList.value = value;

    update();
  }

  final Map<String, String> currencyEmojiMap = {
    "AED": "🇦🇪",
    "AFN": "🇦🇫",
    "ALL": "🇦🇱",
    "AMD": "🇦🇲",
    "ANG": "🇳🇱",
    "AOA": "🇦🇴",
    "ARS": "🇦🇷",
    "AUD": "🇦🇺",
    "AWG": "🇦🇼",
    "AZN": "🇦🇿",
    "BAM": "🇧🇦",
    "BBD": "🇧🇧",
    "BDT": "🇧🇩",
    "BGN": "🇧🇬",
    "BHD": "🇧🇭",
    "BIF": "🇧🇮",
    "BMD": "🇧🇲",
    "BND": "🇧🇳",
    "BOB": "🇧🇴",
    "BRL": "🇧🇷",
    "BSD": "🇧🇸",
    "BTN": "🇧🇹",
    "BWP": "🇧🇼",
    "BYN": "🇧🇾",
    "BYR": "🇧🇾",
    "BZD": "🇧🇿",
    "CAD": "🇨🇦",
    "CDF": "🇨🇩",
    "CHF": "🇨🇭",
    "CLF": "🇨🇱",
    "CLP": "🇨🇱",
    "CNY": "🇨🇳",
    "COP": "🇨🇴",
    "CRC": "🇨🇷",
    "CUC": "🇨🇺",
    "CUP": "🇨🇺",
    "CVE": "🇨🇻",
    "CZK": "🇨🇿",
    "DJF": "🇩🇯",
    "DKK": "🇩🇰",
    "DOP": "🇩🇴",
    "DZD": "🇩🇿",
    "EGP": "🇪🇬",
    "ERN": "🇪🇷",
    "ETB": "🇪🇹",
    "EUR": "🇪🇺",
    "FJD": "🇫🇯",
    "FKP": "🇫🇰",
    "GBP": "🇬🇧",
    "GEL": "🇬🇪",
    "GHS": "🇬🇭",
    "GIP": "🇬🇮",
    "GMD": "🇬🇲",
    "GNF": "🇬🇳",
    "GTQ": "🇬🇹",
    "GYD": "🇬🇾",
    "HKD": "🇭🇰",
    "HNL": "🇭🇳",
    "HRK": "🇭🇷",
    "HTG": "🇭🇹",
    "HUF": "🇭🇺",
    "IDR": "🇮🇩",
    "ILS": "🇮🇱",
    "INR": "🇮🇳",
    "IQD": "🇮🇶",
    "IRR": "🇮🇷",
    "ISK": "🇮🇸",
    "JMD": "🇯🇲",
    "JOD": "🇯🇴",
    "JPY": "🇯🇵",
    "KES": "🇰🇪",
    "KGS": "🇰🇬",
    "KHR": "🇰🇭",
    "KMF": "🇰🇲",
    "KPW": "🇰🇵",
    "KRW": "🇰🇷",
    "KWD": "🇰🇼",
    "KYD": "🇰🇾",
    "KZT": "🇰🇿",
    "LAK": "🇱🇦",
    "LBP": "🇱🇧",
    "LKR": "🇱🇰",
    "LRD": "🇱🇷",
    "LSL": "🇱🇸",
    "LTL": "🇱🇹",
    "LVL": "🇱🇻",
    "LYD": "🇱🇾",
    "MAD": "🇲🇦",
    "MDL": "🇲🇩",
    "MGA": "🇲🇬",
    "MKD": "🇲🇰",
    "MMK": "🇲🇲",
    "MNT": "🇲🇳",
    "MOP": "🇲🇴",
    "MRO": "🇲🇷",
    "MUR": "🇲🇺",
    "MVR": "🇲🇻",
    "MWK": "🇲🇼",
    "MXN": "🇲🇽",
    "MYR": "🇲🇾",
    "MZN": "🇲🇿",
    "NAD": "🇳🇦",
    "NGN": "🇳🇬",
    "NIO": "🇳🇮",
    "NOK": "🇳🇴",
    "NPR": "🇳🇵",
    "NZD": "🇳🇿",
    "OMR": "🇴🇲",
    "PAB": "🇵🇦",
    "PEN": "🇵🇪",
    "PGK": "🇵🇬",
    "PHP": "🇵🇭",
    "PKR": "🇵🇰",
    "PLN": "🇵🇱",
    "PYG": "🇵🇾",
    "QAR": "🇶🇦",
    "RON": "🇷🇴",
    "RSD": "🇷🇸",
    "RUB": "🇷🇺",
    "RWF": "🇷🇼",
    "SAR": "🇸🇦",
    "SBD": "🇸🇧",
    "SCR": "🇸🇨",
    "SDG": "🇸🇩",
    "SEK": "🇸🇪",
    "SGD": "🇸🇬",
    "SHP": "🇸🇭",
    "SLE": "🇸🇱",
    "SLL": "🇸🇱",
    "SOS": "🇸🇴",
    "SRD": "🇸🇷",
    "STD": "🇸🇹",
    "SYP": "🇸🇾",
    "SZL": "🇸🇿",
    "THB": "🇹🇭",
    "TJS": "🇹🇯",
    "TMT": "🇹🇲",
    "TND": "🇹🇳",
    "TOP": "🇹🇴",
    "TRY": "🇹🇷",
    "TTD": "🇹🇹",
    "TWD": "🇹🇼",
    "TZS": "🇹🇿",
    "UAH": "🇺🇦",
    "UGX": "🇺🇬",
    "USD": "🇺🇸",
    "UYU": "🇺🇾",
    "UZS": "🇺🇿",
    "VEF": "🇻🇪",
    "VES": "🇻🇪",
    "VND": "🇻🇳",
    "VUV": "🇻🇺",
    "WST": "🇼🇸",
    "XAF": "🇨🇲",
    "XCD": "🇦🇮",
    "XOF": "🇧🇯",
    "XPF": "🇵🇫",
    "YER": "🇾🇪",
    "ZAR": "🇿🇦",
    "ZMW": "🇿🇲",
    "ZWL": "🇿🇼"
  };

  String emoji = '';

  convertCurrencyCodeToEmoji(String code) {
    emoji = currencyEmojiMap[code.toUpperCase()] ??
        '❓'; // Use '❓' if the code is not found
    update();
  }
}
