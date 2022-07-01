import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // For Rust
      let dummy = dummy_method_to_enforce_bundling()
      print(dummy)
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let punctuatorChannel = FlutterMethodChannel(name: "minutes/punctuator",
                                                binaryMessenger: controller.binaryMessenger)
      punctuatorChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        // This method is invoked on the UI thread.
          switch call.method {
          case "punctuateText":
              guard let args = call.arguments as? [String: [Int]],
                    let tokens = args["tokens"] else {
                  print("INVALID INPUT: \(String(describing: call.arguments))")
                  return
              }
              
              self?.punctuateText(tokens: tokens, result: result)
          case "autoCorrectText":
              guard let args = call.arguments as? [String: [Int]],
                    let tokens = args["tokens"],
                    let targets = args["targets"] else {
                  print("INVALID INPUT: \(String(describing: call.arguments))")
                  return
              }
              self?.autoCorrectText(tokens: tokens, targets: targets, result: result)
          default:
              result(FlutterMethodNotImplemented)
          }
      })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    private func punctuateText(tokens: [Int], result: FlutterResult) {
        do {
            let myModel = try PunctuatorModel()
            let punctuator = AlbertPunctuator(model: myModel)
            let (softMaxScores, words, mask) = punctuator.punctuate(tokens: tokens)
            result(["scores" : softMaxScores, "words" : words, "mask" : mask])
        } catch let error {
            print(error.localizedDescription)
            result(FlutterError(code: "An error occured", message: error.localizedDescription, details: nil))
        }
    }
    
    private func autoCorrectText(tokens: [Int], targets: [Int], result: FlutterResult) {
        do {
            let myModel = try AutoCorrectModel()
            let autoCorrector = AlbertAutoCorrector(model: myModel)
            let softMaxScores = autoCorrector.autoCorrect(tokens: tokens, targets: targets)
            result(["scores" : softMaxScores])
        } catch let error {
            print(error.localizedDescription)
            result(FlutterError(code: "An error occured", message: error.localizedDescription, details: nil))
        }
    }
}
