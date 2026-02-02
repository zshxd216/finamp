import UIKit
import Flutter
import flutter_downloader
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    GeneratedPluginRegistrant.register(with: self)
    FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    if let registrar = self.registrar(forPlugin: "AirPlayRoutePickerView") {
      registrar.register(AirPlayRoutePickerViewFactory(), withId: "airplay_route_picker")
    }
      
    // Exclude the documents folder from iCloud backup since we keep songs there.
    try! setExcludeFromiCloudBackup(isExcluded: true)
    
    return didFinish
  }
}

class AirPlayRoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AirPlayRoutePickerView(frame: frame, args: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class AirPlayRoutePickerView: NSObject, FlutterPlatformView {
  private let routePickerView: AVRoutePickerView

  init(frame: CGRect, args: Any?) {
    routePickerView = AVRoutePickerView(frame: frame)
    super.init()

    routePickerView.backgroundColor = .clear
    routePickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    if #available(iOS 13.0, *) {
      routePickerView.prioritizesVideoDevices = false
    }

    if let dict = args as? [String: Any], let tintColor = dict["tintColor"] as? Int {
      let alpha = CGFloat((tintColor >> 24) & 0xFF) / 255.0
      let red = CGFloat((tintColor >> 16) & 0xFF) / 255.0
      let green = CGFloat((tintColor >> 8) & 0xFF) / 255.0
      let blue = CGFloat(tintColor & 0xFF) / 255.0
      let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
      routePickerView.tintColor = color
      routePickerView.activeTintColor = color
    }
  }

  func view() -> UIView {
    return routePickerView
  }
}

private func setExcludeFromiCloudBackup(isExcluded: Bool) throws {
    var fileOrDirectoryURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = isExcluded
    try fileOrDirectoryURL.setResourceValues(values)
}


private func registerPlugins(registry: FlutterPluginRegistry) { 
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}
