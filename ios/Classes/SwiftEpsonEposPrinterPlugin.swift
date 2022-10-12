import Flutter
import UIKit


struct EpsonEposPrinterInfo: Codable{
    var ipAddress: String? = nil
    var bdAddress: String? = nil
    var macAddress: String? = nil
    var model: String? = nil
    var type: String? = nil
    var target: String? = nil
}

struct EpsonEposPrinterResult: Codable{
    var type: String = ""
    var success: Bool = false
    var message: String?
    var content: [EpsonEposPrinterInfo?]
}

public class SwiftEpsonEposPrinterPlugin: NSObject, FlutterPlugin,     Epos2DiscoveryDelegate, Epos2PtrReceiveDelegate{
    
    
    
    
    let PAGE_AREA_HEIGHT: Int = 500
    let PAGE_AREA_WIDTH: Int = 500
    let FONT_A_HEIGHT: Int = 24
    let FONT_A_WIDTH: Int = 12
    let BARCODE_HEIGHT_POS: Int = 70
    let BARCODE_WIDTH_POS: Int = 110
    
    let encoder = JSONEncoder()
    
    var printer: Epos2Printer?
    var valuePrinterSeries: Epos2PrinterSeries = EPOS2_TM_M10
    var valuePrinterModel: Epos2ModelLang = EPOS2_MODEL_ANK
    var printerList: [EpsonEposPrinterInfo] = []
    var filterOption: Epos2FilterOption = Epos2FilterOption()
    
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "epson_epos_printer", binaryMessenger: registrar.messenger())
        let instance = SwiftEpsonEposPrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method){
            
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "onPrint":
            initializePrinterObject()
            let res = onPrint(call: call, result: result)
            print("onPrint RES \(res)")
            result(res)
            
        case "onDiscovery":
            
            onDiscovery(call: call, result: result)
            
            
        default:
            
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func onPrint( call: FlutterMethodCall, result: FlutterResult) -> Bool {
        let args = call.arguments as? Dictionary<String, Any>
        let series = args?["series"] as? String
        let target = args?["target"] as? String
        let commands = args?["commands"] as? [[String:AnyObject]] ?? []
        
        if printer == nil {
            return false
        }
        
        if (!connectPrinter(target: target!, series: series!)) {
            
            if (printer != nil) {
                printer!.clearCommandBuffer()
                
            }
            return false
            
        } else {
            
            if(!commands.isEmpty) {
                
                for command in commands{
                    
                    onGenerateCommand(command: command)
                }
                
                let res = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
                if res != EPOS2_SUCCESS.rawValue {
                    printer!.clearCommandBuffer()
                    printer!.disconnect()
                    return false
                }
                printer!.clearCommandBuffer()
                printer!.disconnect()
                
                return true
                
                
            }
            
        }
        
        finalizePrinterObject()
        return false
        
    }
    
    func onDiscovery(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("onDiscovery func execution")
        var eps = EpsonEposPrinterResult(success: false, content: self.printerList);
        filterOption.portType = EPOS2_PORTTYPE_TCP.rawValue
        filterOption.deviceType = EPOS2_TYPE_PRINTER.rawValue
        //var resp =  EpsonEposPrinterResult("onDiscoveryTCP",false)
        var res = EPOS2_SUCCESS.rawValue;
        var data: Data?;
        
        printerList.removeAll()
        
        res = Epos2Discovery.start(filterOption, delegate:self)
        
        if res != EPOS2_SUCCESS.rawValue {
            Epos2Discovery.stop()
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            eps = EpsonEposPrinterResult(success: true, content: self.printerList)
            data = try? self.encoder.encode(eps)
            //print(String(data: data!, encoding: .utf8)!)
            result(String(data: data!, encoding: .utf8)!)
        }
        
        
        
        
        
    }
    
    
    func connectPrinter(target: String, series: String) -> Bool {
        var res: Int32 = EPOS2_SUCCESS.rawValue
        
        //if printer == nil {
        //    return false
        //}
        
        res = printer!.connect(target, timeout:Int(EPOS2_PARAM_DEFAULT))
        if res != EPOS2_SUCCESS.rawValue {
            
            return false
        }
        else{
            
            return true
        }
    }
    
    func disconnectPrinter() {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return
        }
        
        result = printer!.disconnect()
        if result != EPOS2_SUCCESS.rawValue {
            DispatchQueue.main.async(execute: {
            })
        }
        
        printer!.clearCommandBuffer()
    }
    
    
    
    
    private func onGenerateCommand(command: Dictionary<String, Any>) {
        if (printer == nil) {
            return
        }
        
        let  commandId = command["id"] as? String
        if (!commandId!.isEmpty) {
            let commandValue = command["value"]
            
            switch (commandId) {
                
            case "appendText" :
                let txt: String = commandValue as? String ?? ""
                print("TEXT \(txt)")
                printer!.addText(txt)
                
            case "addFeedLine":
                let feed: Int = commandValue as? Int ?? Int(EPOS2_PARAM_DEFAULT)
                print("FEED LINE \(feed)")
                printer!.addFeedLine(feed)
                
            case   "addCut" :
                
                switch (commandValue as? String) {
                case "CUT_FEED":
                    printer!.addCut(EPOS2_CUT_FEED.rawValue)
                    print("CUT_FEED")
                case "CUT_NO_FEED":
                    printer!.addCut(EPOS2_CUT_NO_FEED.rawValue)
                    print("CUT_NO_FEED")
                case "CUT_RESERVE":
                    printer!.addCut(EPOS2_CUT_RESERVE.rawValue)
                    print("CUT_RESERVE")
                default:
                    printer!.addCut(EPOS2_PARAM_DEFAULT)
                }
                
                
            case "addLineSpace":
                let space: Int = commandValue as? Int ?? Int(EPOS2_PARAM_DEFAULT)
                print("SPACE LINE \(space)")
                printer!.addFeedLine(space)
                
            case  "addTextAlign":
                
                switch (commandValue as? String) {
                case "LEFT":
                    printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
                    print("TEXT ALIGN LEFT")
                case "CENTER":
                    printer!.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
                    print("TEXT ALIGN CENTER")
                case "RIGHT":
                    printer!.addTextAlign(EPOS2_ALIGN_RIGHT.rawValue)
                    print("TEXT ALIGN RIGHT")
                default:
                    printer!.addTextAlign(EPOS2_PARAM_DEFAULT)
                    print("TEXT ALIGN DEFAULT")
                    
                }
            case "addTextSize":
                
                switch (commandValue as? String) {
                case "SMALL":
                    printer!.addTextSize(1, height: 1)
                    print("TEXT SIZE SMALL")
                    
                case "MEDIUM":
                    printer!.addTextSize(2, height: 1)
                    print("TEXT SIZE MEDIUM")
                    
                case "BIG":
                    printer!.addTextSize(2, height: 2)
                    print("TEXT SIZE BIG")
                default:
                    printer!.addTextSize(1, height: 1)
                    print("TEXT SIZE DEFAULT")
                    
                }
            default:
                print("DEFAULT")
                break
                
            }
        }
    }
    
    public func onPtrReceive(_ printerObj: Epos2Printer!, code: Int32, status: Epos2PrinterStatusInfo!, printJobId: String!) {
        
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
            self.disconnectPrinter()
        })
    }
    
    
    
    
    public func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
        let device: EpsonEposPrinterInfo = EpsonEposPrinterInfo(ipAddress: deviceInfo.ipAddress,
                                                                macAddress: deviceInfo.macAddress,
                                                                model: deviceInfo.deviceName,
                                                                target: deviceInfo.target)
        printerList.append(device)
        
        
    }
    
    
    @discardableResult
    func initializePrinterObject() -> Bool {
        printer = Epos2Printer(printerSeries: valuePrinterSeries.rawValue, lang: valuePrinterModel.rawValue)
        
        if printer == nil {
            return false
        }
        printer!.setReceiveEventDelegate(self)
        
        return true
    }
    
    func finalizePrinterObject() {
        if printer == nil {
            return
        }
        
        printer!.setReceiveEventDelegate(nil)
        printer = nil
    }
    
    
}



