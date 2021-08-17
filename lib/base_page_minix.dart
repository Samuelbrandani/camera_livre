import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;

typedef WidgetInCaseError = Widget Function();

mixin BasePage {
  late VoidCallback cancel;

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void removeFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  void handleLoading(bool value) {
    if (value) {
      showLoading();
    } else {
      hideLoading();
    }
  }

  void showLoading() {
    cancel = BotToast.showCustomLoading(
      backgroundColor: Colors.white60,
      toastBuilder: (_) => Container(),
    );
  }

  void hideLoading() => cancel.call();
}
