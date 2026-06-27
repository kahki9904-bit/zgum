import Flutter
import GoogleMaps
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let photoSaveChannelName = "com.zgum.app/photo_save"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBsuBqQ8gyJk_2nPiICjDW2p0pmViApnnc")
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      registerPhotoSaveChannel(binaryMessenger: controller.binaryMessenger)
    }
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ZGumPhotoSavePlugin") {
      registerPhotoSaveChannel(binaryMessenger: registrar.messenger())
    }
  }

  private func registerPhotoSaveChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: photoSaveChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "saveImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let data = args["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "EMPTY_IMAGE", message: "Image bytes are empty", details: nil))
        return
      }
      self?.saveImageToLibrary(data.data, result: result)
    }
  }

  private func saveImageToLibrary(_ data: Data, result: @escaping FlutterResult) {
    let save = {
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: data, options: nil)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(FlutterError(
              code: "SAVE_FAILED",
              message: error?.localizedDescription ?? "Photo save failed",
              details: nil
            ))
          }
        }
      }
    }

    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      if status == .authorized || status == .limited {
        save()
      } else {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
          if newStatus == .authorized || newStatus == .limited {
            save()
          } else {
            DispatchQueue.main.async {
              result(FlutterError(code: "PERMISSION_DENIED", message: "Photo permission denied", details: nil))
            }
          }
        }
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      if status == .authorized {
        save()
      } else {
        PHPhotoLibrary.requestAuthorization { newStatus in
          if newStatus == .authorized {
            save()
          } else {
            DispatchQueue.main.async {
              result(FlutterError(code: "PERMISSION_DENIED", message: "Photo permission denied", details: nil))
            }
          }
        }
      }
    }
  }
}
