import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class AntiCheatService {
  bool _active = false;

  bool get isActive => _active;

  Future<void> enable() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    await windowManager.setPreventClose(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();

    // Даем ОС 600 мс на переключение видеорежима
    await Future.delayed(const Duration(milliseconds: 600));
    _active = true;
  }

  Future<void> disable() async {
    _active = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setPreventClose(false);
  }
}

/// Блокирует вставку текста длиннее 2 символов за одно нажатие
class AntiPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final int addedChars = newValue.text.length - oldValue.text.length;
    if (addedChars > 2) {
      return oldValue;
    }
    return newValue;
  }
}
