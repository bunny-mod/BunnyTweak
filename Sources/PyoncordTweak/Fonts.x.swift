import PyoncordTweakC
import Orion
import UIKit
import os
import Foundation

// This is not the full implementation, we only take what we need in here
// For full definition, find it from the core codebase (JS side)
struct FontDefinition: Codable {
  let name: String
  let main: [String: String]?
}

var fontMap: [String: String] = [:]

class FontsHook: ClassHook<UIFont> {
  class func fontWithName(_ name: String, size: CGFloat) -> UIFont {
    if let replacementName = fontMap[name] {
      return UIFont(name: replacementName, size: size)!
    }

    return orig.fontWithName(name, size: size)
  }
  class func fontWithDescriptor(_ descriptor: UIFontDescriptor, size: CGFloat) -> UIFont {
    if let replacementName = fontMap[descriptor.postscriptName] {
      let replacementDescriptor = UIFontDescriptor(name: replacementName, size: size)
        .addingAttributes(descriptor.fontAttributes)

      return orig.fontWithDescriptor(replacementDescriptor, size: size)
    }
    
    return orig.fontWithDescriptor(descriptor, size: size)
  }
}

func patchFonts(_ main: [String: String], fontDefName: String) {
  for (fontName, url) in main {
    os_log("Replacing font %{public}@ with URL: %{public}@", log: pyoncordLog, type: .info, fontName, url)

    let fontExtension = URL(string: url)!.pathExtension
    let fontCachePath = pyoncordDirectory
        .appendingPathComponent("downloads", isDirectory: true)
        .appendingPathComponent("fonts", isDirectory: true)
        .appendingPathComponent(fontDefName, isDirectory: true)
        .appendingPathComponent("\(fontName).\(fontExtension)")

    do {
      os_log("Attempting to register font %{public}@ from %{public}@", log: pyoncordLog, type: .info, fontName, url)

      let parent = fontCachePath.deletingLastPathComponent()
      if !FileManager.default.fileExists(atPath: parent.path) {
        os_log("Creating parent directory: %{public}@", log: pyoncordLog, type: .debug, parent.path)
        try FileManager.default.createDirectory(
          at: parent, withIntermediateDirectories: true, attributes: nil)
      }

      // JS side should download these already, but just in case...
      if !FileManager.default.fileExists(atPath: fontCachePath.path) {
        os_log("Downloading font %{public}@ from %{public}@", log: pyoncordLog, type: .debug, fontName, url)
        if let data = try? Data(contentsOf: URL(string: url)!) {
          os_log("Writing font data to: %{public}@", log: pyoncordLog, type: .debug, fontCachePath.path)
          try? data.write(to: fontCachePath)
        }
      }

      if let data = try? Data(contentsOf: fontCachePath) {
        os_log("Registering font %{public}@ with provider", log: pyoncordLog, type: .debug, fontName)
        let provider = CGDataProvider(data: data as CFData)
        let font = CGFont(provider!)
        var error: Unmanaged<CFError>?

        // This does not work with system/app fonts unfortunately. Throws a CTFontManagerError.systemRequired
        if let existingFont = CGFont(font!.postScriptName!) {
          var unregisterError: Unmanaged<CFError>?
          if !CTFontManagerUnregisterGraphicsFont(existingFont, &unregisterError) {
            os_log("Failed to deregister font %{public}@: %{public}@", log: pyoncordLog, type: .error, 
              font!.postScriptName! as String,
              String(describing: unregisterError!.takeUnretainedValue()))
          }
        }

        if CTFontManagerRegisterGraphicsFont(font!, &error) {
          fontMap[fontName] = font!.postScriptName! as String
          os_log("Successfully registered font %{public}@ to %{public}@", log: pyoncordLog, type: .info, fontName, font!.postScriptName! as String)
        } else {
          os_log("Failed to register font %{public}@: %{public}@", log: pyoncordLog, type: .error, fontName, String(describing: error!.takeUnretainedValue()))
        }
      } else {
        os_log("Failed to read font data from: %{public}@", log: pyoncordLog, type: .error, fontCachePath.path)
      }
    } catch {
      os_log("Failed to register font %{public}@: %{public}@", log: pyoncordLog, type: .error, fontName, error.localizedDescription)
    }
  }
}