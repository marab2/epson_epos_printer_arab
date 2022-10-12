import 'package:flutter/services.dart';

import 'enums.dart';
import 'epson_epos_printer_platform_interface.dart';
import 'helpers.dart';
import 'models.dart';

class EpsonEposPrinter {
  static final EpsonEPOSHelper _eposHelper = EpsonEPOSHelper();
  static const MethodChannel _channel = MethodChannel('epson_epos_printer');

  Future<String?> getPlatformVersion() {
    return EpsonEposPrinterPlatform.instance.getPlatformVersion();
  }

  static Future<List<EpsonPrinterModel>?> onDiscovery(
      {EpsonEPOSPortType type = EpsonEPOSPortType.ALL}) async {
    String printType = _eposHelper.getPortType(type);
    final Map<String, dynamic> params = {"type": printType};
    String? rep = await _channel.invokeMethod('onDiscovery', params);
    if (rep != null) {
      try {
        final response = EpsonPrinterResponse.fromRawJson(rep);
        List<dynamic> prs = response.content;
        if (prs.isNotEmpty) {
          return prs.map((e) {
            final modelName = e['model'];
            final modelSeries = _eposHelper.getSeries(modelName);
            return EpsonPrinterModel(
              ipAddress: e['ipAddress'],
              bdAddress: e['bdAddress'],
              macAddress: e['macAddress'],
              type: printType,
              model: modelName,
              series: modelSeries?.id,
              target: e['target'],
            );
          }).toList();
        }
      } catch (e) {
        rethrow;
      }
    }
    return [];
  }

  Future<dynamic> onPrint(
      EpsonPrinterModel printer, List<Map<String, dynamic>> commands) async {
    final Map<String, dynamic> params = {
      "type": printer.type,
      "series": printer.series,
      "commands": commands,
      "target": printer.target
    };
    return await _channel.invokeMethod('onPrint', params);
  }

  static Future<dynamic> getPrinterSetting(EpsonPrinterModel printer) async {
    final Map<String, dynamic> params = {
      "type": printer.type,
      "series": printer.series,
      "target": printer.target
    };
    return await _channel.invokeMethod('getPrinterSetting', params);
  }

  static Future<dynamic> setPrinterSetting(EpsonPrinterModel printer,
      {int? paperWidth, int? printDensity, int? printSpeed}) async {
    final Map<String, dynamic> params = {
      "type": printer.type,
      "series": printer.series,
      "paper_width": paperWidth,
      "print_density": printDensity,
      "print_speed": printSpeed,
      "target": printer.target
    };
    return await _channel.invokeMethod('setPrinterSetting', params);
  }
}
