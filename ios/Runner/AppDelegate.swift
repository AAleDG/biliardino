import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private static let pickerChannel = "com.biliardino.biliardino/backup_file_picker"
  private static let maximumBackupBytes = 10 * 1024 * 1024
  private var backupPickerChannel: FlutterMethodChannel?
  private var pendingPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupFilePicker") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: Self.pickerChannel,
      binaryMessenger: registrar.messenger()
    )
    backupPickerChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickJson" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.openBackupPicker(result: result)
    }
  }

  private func openBackupPicker(result: @escaping FlutterResult) {
    guard pendingPickerResult == nil else {
      result(FlutterError(
        code: "picker_busy",
        message: "A backup picker is already open.",
        details: nil
      ))
      return
    }
    guard let presenter = activeViewController() else {
      result(FlutterError(
        code: "picker_unavailable",
        message: "The document picker cannot be presented.",
        details: nil
      ))
      return
    }
    pendingPickerResult = result
    let picker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true)
  }

  private func activeViewController() -> UIViewController? {
    let windowScenes = UIApplication.shared.connectedScenes.compactMap {
      $0 as? UIWindowScene
    }
    let foregroundWindows = windowScenes
      .filter { $0.activationState == .foregroundActive }
      .flatMap { $0.windows }
    let allWindows = windowScenes.flatMap { $0.windows }
    let activeWindow = foregroundWindows.first(where: { $0.isKeyWindow })
      ?? allWindows.first(where: { $0.isKeyWindow })
      ?? window
    var presenter = activeWindow?.rootViewController
    while let presented = presenter?.presentedViewController {
      presenter = presented
    }
    return presenter
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishPicker(with: nil)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let url = urls.first else {
      finishPicker(with: nil)
      return
    }
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed { url.stopAccessingSecurityScopedResource() }
    }
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey])
      if let size = values.fileSize, size > Self.maximumBackupBytes {
        finishPicker(with: FlutterError(
          code: "backup_too_large",
          message: "The selected backup exceeds 10 MB.",
          details: nil
        ))
        return
      }
      let data = try Data(contentsOf: url, options: [.mappedIfSafe])
      guard data.count <= Self.maximumBackupBytes else {
        finishPicker(with: FlutterError(
          code: "backup_too_large",
          message: "The selected backup exceeds 10 MB.",
          details: nil
        ))
        return
      }
      guard let source = String(data: data, encoding: .utf8) else {
        finishPicker(with: FlutterError(
          code: "invalid_encoding",
          message: "The selected backup is not valid UTF-8 text.",
          details: nil
        ))
        return
      }
      finishPicker(with: source)
    } catch {
      finishPicker(with: FlutterError(
        code: "backup_read_failed",
        message: "Unable to read the selected backup.",
        details: error.localizedDescription
      ))
    }
  }

  private func finishPicker(with value: Any?) {
    let result = pendingPickerResult
    pendingPickerResult = nil
    result?(value)
  }
}
