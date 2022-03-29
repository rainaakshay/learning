import Flutter
import UIKit
import MLKitEntityExtraction

public class SwiftLearningEntityExtractionPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "LearningEntityExtraction", binaryMessenger: registrar.messenger())
    let instance = SwiftLearningEntityExtractionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      instance.setModelManager(registrar: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "extract" {
      extract(call, result: result)
    } else if call.method == "dispose" {
      dispose(result: result)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  func extract(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String
    let text: String? = args["text"] as? String

    if modelIdentifier == nil || text == nil {
      result(FlutterError(
        code: "NOTEXT", 
        message: "No argument text",
        details: nil))
      return
    }

      let options = EntityExtractorOptions(modelIdentifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!) )
    let extractor = EntityExtractor.entityExtractor(options: options)
    
      extractor.downloadModelIfNeeded(completion: { data in
      extractor.annotateText(
        text ?? "",
        params: EntityExtractionParams(),
        completion: { annotations, error in
          if error != nil {
            result(FlutterError(
              code: "FAILED", 
              message: "Entity extraction failed with error: \(error!)",
              details: error))
            return
          }
      result(annotations)
//            let result : [Entity] = annotations?.first?.entities ?? []
//            [EntityAnnotation]
//          for annotation in (annotations ?? []) {
//
//            let item = [
//                "annotation": annotation.entities,
//                "start": annotation.range.lowerBound,
//                "end": annotation.range.upperBound
//            ] as [String : Any]
//
//            let entities = annotation.entities
//
//            for entity in entities {
//
//            }
//          }
        }
      )
    })
  }

  func dispose(result: @escaping FlutterResult) {
    result(true)
  }

  func setModelManager(registrar: FlutterPluginRegistrar) {
    let modelManagerChannel = FlutterMethodChannel(
      name: "LearningEntityModelManager", binaryMessenger: registrar.messenger())
    
    modelManagerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "list" {
            self.listModel(result: result)
        } else if call.method == "download" {
            self.downloadModel(call: call, result: result)
        } else if call.method == "check" {
            self.checkModel(call: call, result: result)
        } else if call.method == "delete" {
            self.deleteModel(call: call, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
    })
  }

  func listModel(result: @escaping FlutterResult) {
    let modelManager = ModelManager.modelManager()
    let models = modelManager.downloadedEntityExtractionModels.map { $0.modelIdentifier }
    result(models)
  }

  func checkModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let modelManager = ModelManager.modelManager()
    let downloadedModels = Set(modelManager.downloadedEntityExtractionModels.map { $0.modelIdentifier })
    let isDownloaded = downloadedModels.contains(EntityExtractionModelIdentifier(rawValue: modelIdentifier!))

    result(isDownloaded)
  }

  func downloadModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String
    let isRequireWifi: Bool = (args["isRequireWifi"] as? Bool) ?? true

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let model = EntityExtractorRemoteModel.entityExtractorRemoteModel(identifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!))
    let modelManager = ModelManager.modelManager()
    let conditions = ModelDownloadConditions(
      allowsCellularAccess: !isRequireWifi,
      allowsBackgroundDownloading: true
    )
    modelManager.download(model, conditions: conditions)
    result(true)
  }

  func deleteModel(call: FlutterMethodCall, result:  @escaping FlutterResult) {
    guard let args = call.arguments as? Dictionary<String, AnyObject> else {
      result(FlutterError(
        code: "NOARGUMENTS", 
        message: "No arguments",
        details: nil))
      return
    }

    let modelIdentifier: String? = args["model"] as? String

    if modelIdentifier == nil {
      result(FlutterError(
        code: "INCARGUMENTS", 
        message: "Incomplete arguments",
        details: nil))
      return
    }

    let model = EntityExtractorRemoteModel.entityExtractorRemoteModel(identifier: EntityExtractionModelIdentifier(rawValue: modelIdentifier!))
    let modelManager = ModelManager.modelManager()
    
    modelManager.deleteDownloadedModel(model) { error in 
      result(true)
    }
  }
}

