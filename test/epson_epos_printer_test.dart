import 'package:flutter_test/flutter_test.dart';
import 'package:epson_epos_printer/epson_epos_printer.dart';
import 'package:epson_epos_printer/epson_epos_printer_platform_interface.dart';
import 'package:epson_epos_printer/epson_epos_printer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEpsonEposPrinterPlatform
    with MockPlatformInterfaceMixin
    implements EpsonEposPrinterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EpsonEposPrinterPlatform initialPlatform = EpsonEposPrinterPlatform.instance;

  test('$MethodChannelEpsonEposPrinter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEpsonEposPrinter>());
  });

  test('getPlatformVersion', () async {
    EpsonEposPrinter epsonEposPrinterPlugin = EpsonEposPrinter();
    MockEpsonEposPrinterPlatform fakePlatform = MockEpsonEposPrinterPlatform();
    EpsonEposPrinterPlatform.instance = fakePlatform;

    expect(await epsonEposPrinterPlugin.getPlatformVersion(), '42');
  });
}
