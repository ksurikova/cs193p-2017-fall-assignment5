//
//  StaticsAndExtensions.swift
//  SimpleImageGallery
//
//  Created by Ksenia Surikova on 17.08.2021.
//

import UIKit
import Foundation

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? self
        } else {
            return self
        }
    }
}

extension URL {
    var imageURL: URL {
        if let url = UIImage.urlToStoreLocallyAsJPEG(named: self.path) {
            // this was created using UIImage.storeLocallyAsJPEG
            return url
        } else {
            // check to see if there is an embedded imgurl reference
            for query in query?.components(separatedBy: "&") ?? [] {
                let queryComponents = query.components(separatedBy: "=")
                if queryComponents.count == 2 {
                    if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                        return url
                    }
                }
            }
            return self.baseURL ?? self
        }
    }
}

extension UIImage {
    private static let localImagesDirectory = "UIImage.storeLocallyAsJPEG"

    static func urlToStoreLocallyAsJPEG(named: String) -> URL? {
        var name = named
        let pathComponents = named.components(separatedBy: "/")
        if pathComponents.count > 1 {
            if pathComponents[pathComponents.count-2] == localImagesDirectory {
                name = pathComponents.last!
            } else {
                return nil
            }
        }
        if var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            url = url.appendingPathComponent(localImagesDirectory)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                url = url.appendingPathComponent(name)
                if url.pathExtension != "jpg" {
                    url = url.appendingPathExtension("jpg")
                }
                return url
            } catch let error {
                print("UIImage.urlToStoreLocallyAsJPEG \(error)")
            }
        }
        return nil
    }

    func storeLocallyAsJPEG(named name: String) -> URL? {
        if let imageData = self.jpegData(compressionQuality: 1.0) {
            if let url = UIImage.urlToStoreLocallyAsJPEG(named: name) {
                do {
                    try imageData.write(to: url)
                    return url
                } catch let error {
                    print("UIImage.storeLocallyAsJPEG \(error)")
                }
            }
        }
        return nil
    }

    func scaled(by factor: CGFloat) -> UIImage? {
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        UIGraphicsBeginImageContext(newSize)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension String {
    func emojiToImage(size: CGFloat) -> UIImage {

            let outputImageSize = CGSize.init(width: size, height: size)
            let fontSize = outputImageSize.width / 4
            let font = UIFont.systemFont(ofSize: fontSize)
            let textSize = self.boundingRect(with: CGSize(width: outputImageSize.width, height: outputImageSize.height),
                                             options: .usesLineFragmentOrigin,
                                             attributes: [.font: font], context: nil).size

            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            style.lineBreakMode = NSLineBreakMode.byClipping

        let attr: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font,
                                                     NSAttributedString.Key.paragraphStyle: style,
                                                     NSAttributedString.Key.backgroundColor: UIColor.clear ]

            UIGraphicsBeginImageContextWithOptions(outputImageSize, false, 0)
            self.draw(in: CGRect(x: (size - textSize.width) / 2,
                                 y: (size - textSize.height) / 2,
                                 width: textSize.width,
                                 height: textSize.height),
                                 withAttributes: attr)
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return image
        }
        func madeUnique(withRespectTo otherStrings: [String]) -> String {
            var possiblyUnique = self
            var uniqueNumber = 1
            while otherStrings.contains(possiblyUnique) {
                possiblyUnique = self + " \(uniqueNumber)"
                uniqueNumber += 1
            }
            return possiblyUnique
        }
}

struct Utilities {
    static let defaultScale: CGFloat = 1.0
    static let minimumZoomScale: CGFloat = 1/25
    static let maximumZoomScale: CGFloat  = 5.0
    static let imageElementWidth: CGFloat  = 150
    static let imageNotFetchedEmoji: String = "😩"
    static let imageInLineCount: CGFloat = 5
    static let selectingRowDelay: Double = 0.5
}
