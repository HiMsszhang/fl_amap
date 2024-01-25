import AMapLocationKit
import Flutter
import Foundation

class AMapLocation: NSObject, AMapLocationManagerDelegate {
    var channel: FlutterMethodChannel
    private var manager: AMapLocationManager?
    private var result: FlutterResult?
    private var isLocation: Bool = false

    init(_ binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "fl.amap.Location", binaryMessenger:
            binaryMessenger)
        super.init()
    }

    public func setMethodCallHandler() {
        channel.setMethodCallHandler(handle)
    }

    public func detach() {
        channel.setMethodCallHandler(nil)
    }

    func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        self.result = result
        switch call.method {
        case "setApiKey":
            let args = call.arguments as! [String: Any?]
            let key = args["key"] as! String
            let isAgree = args["isAgree"] as! Bool
            let isContains = args["isContains"] as! Bool
            let isShow = args["isShow"] as! Bool
            AMapServices.shared().enableHTTPS = true
            AMapLocationManager.updatePrivacyAgree(isAgree ? .didAgree : .notAgree)
            AMapLocationManager.updatePrivacyShow(isShow ? .didShow : .notShow, privacyInfo: isContains ? .didContain : .notContain)
            AMapServices.shared().apiKey = key
            result(true)
        case "initialize":
            manager = manager ?? AMapLocationManager()
            setLocationOption(call)
            result(true)
        case "dispose":
            isLocation = false
            manager?.stopUpdatingLocation()
            manager?.delegate = nil
            manager = nil
            result(true)
        case "getLocation":
            if manager == nil || isLocation {
                result(nil)
                return
            }
            setLocationOption(call)
            let args = call.arguments as? [AnyHashable: Any]
            let withReGeocode = args?["withReGeocode"] as? Bool ?? false
            manager!.requestLocation(withReGeocode: withReGeocode, completionBlock: { (location: CLLocation?, reGeocode: AMapLocationReGeocode?, error: Error?) in
                var map = [String: Any?]()
                if location != nil {
                    map.merge(location!.data)
                }
                if reGeocode != nil {
                    map.merge(reGeocode!.data)
                }
                if error != nil {
                    map["errorInfo"] = error!.localizedDescription
                    map["errorCode"] = (error! as NSError).code

                } else {
                    map["errorCode"] = 0
                }
                print(map)
                result(map)
            })
        case "startLocation":
            if isLocation || manager == nil {
                result(false)
                return
            }
            isLocation = true
            setLocationOption(call)
            manager!.delegate = self
            manager!.startUpdatingLocation()
            result(true)
        case "stopLocation":
            isLocation = false
            manager?.stopUpdatingLocation()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func setLocationOption(_ call: FlutterMethodCall) {
        let args = call.arguments as? [AnyHashable: Any]
        if args != nil, manager != nil {
            if #available(iOS 14.0, *) {
                manager!.locationAccuracyMode = AMapLocationAccuracyMode(rawValue: args!["locationAccuracyMode"] as! Int)!
            }
            let distanceFilter = args!["distanceFilter"] as? Double
            manager!.distanceFilter = (distanceFilter == nil ? kCLDistanceFilterNone : distanceFilter!)
            manager!.desiredAccuracy = getDesiredAccuracy(args!["desiredAccuracy"] as! String)
            manager!.pausesLocationUpdatesAutomatically = args!["pausesLocationUpdatesAutomatically"] as! Bool
            manager!.allowsBackgroundLocationUpdates = args!["allowsBackgroundLocationUpdates"] as! Bool
            manager!.locationTimeout = args!["locationTimeout"] as! Int
            manager!.reGeocodeTimeout = args!["reGeocodeTimeout"] as! Int
            manager!.locatingWithReGeocode = args!["withReGeocode"] as! Bool
            manager!.reGeocodeLanguage = AMapLocationReGeocodeLanguage(rawValue: args!["reGeocodeLanguage"] as! Int)!
            manager!.detectRiskOfFakeLocation = args!["detectRiskOfFakeLocation"] as! Bool
        }
    }

    func getDesiredAccuracy(_ str: String) -> CLLocationAccuracy {
        switch str {
        case "kCLLocationAccuracyBest":
            return kCLLocationAccuracyBest
        case "kCLLocationAccuracyNearestTenMeters":
            return kCLLocationAccuracyNearestTenMeters
        case "kCLLocationAccuracyHundredMeters":
            return kCLLocationAccuracyHundredMeters
        case "kCLLocationAccuracyKilometer":
            return kCLLocationAccuracyKilometer
        case "kCLLocationAccuracyThreeKilometers":
            return kCLLocationAccuracyThreeKilometers
        default:
            return kCLLocationAccuracyThreeKilometers
        }
    }

    // 连续定位回调函数
    // 注意：如果实现了本方法，则定位信息不会通过amapLocationManager:didUpdateLocation:方法回调。
    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!, reGeocode: AMapLocationReGeocode?) {
        var map = location.data
        if reGeocode != nil {
            map.merge(reGeocode!.data)
        }
        channel.invokeMethod("onLocationChanged", arguments: map)
    }

    // 定位权限状态改变时回调函数 ios14及之后
    func amapLocationManager(_ manager: AMapLocationManager!, locationManagerDidChangeAuthorization locationManager: CLLocationManager!) {
        if #available(iOS 14.0, *) {
            channel.invokeMethod("onAuthorizationChanged", arguments: locationManager.authorizationStatus.rawValue)
        }
    }

    // 定位权限状态改变时回调函数 ios13及之前
    func amapLocationManager(_ manager: AMapLocationManager!, didChange status: CLAuthorizationStatus) {
        channel.invokeMethod("onAuthorizationChanged", arguments: status.rawValue)
    }

    // 当定位发生错误时，会调用代理的此方法。
    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error?) {
        channel.invokeMethod("onLocationFailed", arguments: [
            "errorInfo": error?.localizedDescription,
            "errorCode": (error as? NSError)?.code as Any?,
        ])
    }
}

extension Dictionary {
    mutating func merge<S>(_ other: S)
        where S: Sequence, S.Iterator.Element == (key: Key, value: Value)
    {
        for (k, v) in other {
            self[k] = v
        }
    }
}

extension CLLocation {
    var data: [String: Any?] {
        var map = ["latitude": coordinate.latitude,
                   "longitude": coordinate.longitude,
                   "horizontalAccuracy": horizontalAccuracy,
                   "verticalAccuracy": verticalAccuracy,
                   "altitude": altitude,
                   "speed": speed,
                   "speedAccuracy": speedAccuracy,
                   "course": course,
                   "floor": floor?.level,
                   "timestamp": timestamp.timeIntervalSince1970] as [String: Any?]
        if #available(iOS 13.4, *) {
            map["courseAccuracy"] = courseAccuracy
        }
        if #available(iOS 15.0, *) {
            map["isSimulatedBySoftware"] = sourceInformation?.isSimulatedBySoftware
            map["isProducedByAccessory"] = sourceInformation?.isProducedByAccessory
        }

        return map
    }
}

extension AMapLocationReGeocode {
    var data: [String: Any?] {
        ["formattedAddress": formattedAddress,
         "country": country,
         "province": province,
         "city": city,
         "district": district,
         "cityCode": city,
         "adCode": adcode,
         "street": street,
         "number": number,
         "poiName": poiName,
         "aoiName": aoiName]
    }
}
