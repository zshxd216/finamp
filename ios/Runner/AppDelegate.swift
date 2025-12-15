import app_links
import UIKit
import Flutter
import CarPlay

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Exclude the documents and support folders from iCloud backup since we keep songs there.
        if let documentsDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            try? setExcludeFromiCloudBackup(documentsDir, isExcluded: true)
        }

        if let appSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            try? setExcludeFromiCloudBackup(appSupportDir, isExcluded: true)
        }

        // Setup CarPlay method channel
        setupCarPlayChannel()

        // Retrieve the link from parameters
        if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
            AppLinks.shared.handleLink(url: url)
            return true
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupCarPlayChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }

        let carPlayChannel = FlutterMethodChannel(name: "finamp/carplay", binaryMessenger: controller.binaryMessenger)

        carPlayChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "updateNowPlaying":
                result(nil)
            case "updateBrowseContent":
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    } // <- This closing brace was missing

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}