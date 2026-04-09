import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

 var window: UIWindow?
    
    var restrictRotation: UIInterfaceOrientationMask = .all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return restrictRotation
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initViewController()
        return true
    }
    
    private func initViewController() {
        let controller: UIViewController
        if let lastUrl = SaveService.lastUrl {
            controller = WebviewVC(url: lastUrl)
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = controller
            window?.makeKeyAndVisible()
            print("Saved")
        } else {
            controller = LoadingSplash()
            let navigationController = UINavigationController(rootViewController: controller)
            
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = navigationController
            window?.makeKeyAndVisible()
            print("Not Saved")
        }
    }
}
