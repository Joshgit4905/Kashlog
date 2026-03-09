import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'KashlogWidget';

  static Future<void> updateWidget({String? balance, String? currency}) async {
    if (kIsWeb) return;

    if (balance != null) {
      await HomeWidget.saveWidgetData('balance', balance);
    }
    if (currency != null) {
      await HomeWidget.saveWidgetData('currency', currency);
    }

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
