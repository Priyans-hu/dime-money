import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    override func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let flutterEngine = (UIApplication.shared.delegate as? FlutterAppDelegate)?.engine else {
            completionHandler(false)
            return
        }

        let channel = FlutterMethodChannel(
            name: "com.priyanshu.dime_money/quick_actions",
            binaryMessenger: flutterEngine.binaryMessenger
        )
        channel.invokeMethod("quickAction", arguments: shortcutItem.type)
        completionHandler(true)
    }
}
