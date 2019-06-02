//
//  ViewController.swift
//  iSimDevTest
//
//  Created by Vladimir Ilic on 31/05/19.
//  Copyright © 2019 Vladimir Ilic. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation


typealias Command = String
typealias ErrorMessage = String

enum MessageName: String {
    case Image
}

enum ImageCommand: Command {
    case TakeNew
}

class ViewController: UIViewController {
    // MARK: - Configuration
    lazy var webViewConfig: WKWebViewConfiguration = {
        let wkUserController = WKUserContentController()
        wkUserController.add(self, name: MessageName.Image.rawValue)
        
        let wkConfig = WKWebViewConfiguration()
        wkConfig.userContentController = wkUserController
        
        return wkConfig
    }()
    
    lazy var webView = WKWebView(frame: .zero, configuration: webViewConfig)
    
    // MARK: - Overrides
    override func loadView() {
        self.view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.displayWebUI()
    }
    
    // MARK: - Funcs
    func displayWebUI() {
        guard let indexURL = Bundle.main.url(forResource: "www/index", withExtension: "html") else {
            return
        }
        
        self.webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }
    
    func showError(message: ErrorMessage) {
        let js = "showError(\"\(message)\")"
        self.webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func toggleBusyIndicator(busy: Bool) {
        self.webView.evaluateJavaScript("toggleBusy(\(busy))", completionHandler: nil)
    }
}

// MARK: - JS Message processing
extension ViewController: WKScriptMessageHandler {
    func processImage(command: Command) {
        switch command {
        case ImageCommand.TakeNew.rawValue:
            self.openCamera()
            return
        default:
            self.showError(message: "Unsupported Image command: \(command)")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let command = message.body as? Command else {
            self.showError(message: "Received malformed command")
            return
        }
        
        switch message.name {
        case MessageName.Image.rawValue:
            self.processImage(command: command)
        default:
            self.showError(message: "Unknown command \(command)")
        }
    }
}

// MARK: - Image Capture
extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            self.showError(message: "The devices camera is unavailable.")
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.presentCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    self.presentCamera()
                }
            }
        case .denied, .restricted:
            self.showError(message: "Please enable camera access for this application in your devices Settings.")
        default:
            return
        }
    }
    
    func presentCamera() {
        let imageController = UIImagePickerController()
        imageController.delegate = self
        imageController.sourceType = .camera
        
        self.present(imageController, animated: true) {
            self.toggleBusyIndicator(busy: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true) { [unowned self] in
            if let image = info[.originalImage] as? UIImage,
                let imageData = image.pngData() {
                let b64Image = imageData.base64EncodedString()
                let js = "setImage(\"\(b64Image)\")"
                
                self.webView.evaluateJavaScript(js, completionHandler: { [unowned self] (result, error) in
                    self.toggleBusyIndicator(busy: false)
                    
                    if let error = error {
                        self.showError(message: error.localizedDescription)
                    }
                })
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.toggleBusyIndicator(busy: false)
        self.dismiss(animated: true, completion: nil)
    }
}
