//
//  GalleryModel.swift
//  cs193p-2017-fall-assignment5
//
//  Created by Ksenia Surikova on 17.08.2021.
//

import Foundation
import UIKit

struct ImageElement {
    var aspectRatio: CGFloat
    var imageUrl : URL
    var isImageFetched : Bool?
}

class Gallery {
    var name : String
    var images: [ImageElement]
    
    init(name: String, images: [ImageElement] = [ImageElement]()) {
        self.name = name
        self.images = images
    }
}
