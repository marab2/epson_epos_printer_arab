import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'epson_epos_printer_platform_interface.dart';

/// An implementation of [EpsonEposPrinterPlatform] that uses method channels.
class MethodChannelEpsonEposPrinter extends EpsonEposPrinterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('epson_epos_printer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
