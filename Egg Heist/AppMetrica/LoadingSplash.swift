import UIKit
import SwiftUI

class LoadingSplash: UIViewController {
    
    let loadingLabel = UILabel()
    let loadingImage = UIImageView(image: UIImage(named: "bgmain"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFlow()
    }
    
    private func setupUI() {
        view.addSubview(loadingImage)
        loadingImage.contentMode = .scaleAspectFill
        loadingImage.clipsToBounds = true

        loadingImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingImage.topAnchor.constraint(equalTo: view.topAnchor),
            loadingImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func showContentView() {
        let hostingController = UIHostingController(rootView: ContentView().preferredColorScheme(.dark))
        hostingController.modalPresentationStyle = .fullScreen

        // Получаем window через connectedScenes — надёжнее, чем self.view.window
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first

        if let window = window {
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
        } else {
            // Последний fallback — модальный показ
            self.present(hostingController, animated: true)
        }
    }

    private func setupFlow() {
        CheckURLService.checkURLStatus { is200 in
            DispatchQueue.main.async {
                if is200 {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.restrictRotation = .all
                    }
                    
                    let link = Constants.baseURL
                    let vc = WebviewVC(url: URL(string: link)!)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                } else {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.restrictRotation = .portrait
                    }
                    self.showContentView()
                }
            }
        }
    }
}
