import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'epson_epos_printer_method_channel.dart';

abstract class EpsonEposPrinterPlatform extends PlatformInterface {
  /// Constructs a EpsonEposPrinterPlatform.
  EpsonEposPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static EpsonEposPrinterPlatform _instance = MethodChannelEpsonEposPrinter();

  /// The default instance of [EpsonEposPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelEpsonEposPrinter].
  static EpsonEposPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EpsonEposPrinterPlatform] when
  /// they register themselves.
  static set instance(EpsonEposPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
