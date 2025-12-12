import CarPlay
import Flutter

@available(iOS 12.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, 
                                didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        // Create root template
        let rootTemplate = createRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)
        
        // Notify Flutter about CarPlay connection
        notifyFlutter(event: "carplay_connected")
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, 
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        
        // Notify Flutter about CarPlay disconnection
        notifyFlutter(event: "carplay_disconnected")
    }
    
    private func createRootTemplate() -> CPTabBarTemplate {
        // Browse tab
        let browseTemplate = CPListTemplate(title: "Browse", sections: [])
        browseTemplate.tabImage = UIImage(systemName: "music.note.list")
        
        // Now Playing tab
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.tabImage = UIImage(systemName: "play.circle")
        
        // Search tab
        let searchTemplate = CPListTemplate(title: "Search", sections: [])
        searchTemplate.tabImage = UIImage(systemName: "magnifyingglass")
        
        return CPTabBarTemplate(templates: [browseTemplate, nowPlayingTemplate, searchTemplate])
    }
    
    private func notifyFlutter(event: String) {
        guard let flutterViewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(name: "finamp/carplay", binaryMessenger: flutterViewController.binaryMessenger)
        channel.invokeMethod(event, arguments: nil)
    }
}
