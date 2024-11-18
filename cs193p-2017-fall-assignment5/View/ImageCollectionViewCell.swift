//
//  ImageCollectionViewCell.swift
//  cs193p-2017-fall-assignment5
//
//  Created by Ksenia Surikova on 17.08.2021.
//
import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    var imageURL: URL? {
        didSet {
            fetchImage()
        }
    }

    var indicateWhatImageIsWrong: (() -> Void)?

    private(set) var image: UIImage? {
        get {
            imageView.image
        }
        set {
            imageView.image = newValue
            loadingIndicator?.stopAnimating()
        }
    }

    private func fetchImage() {
        if let url = imageURL {
            loadingIndicator?.startAnimating()
            image = nil
            DispatchQueue.global(qos: .userInitiated).async {
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    // url == self.imageURL - is it still the same cell we want to refresh
                    if url == self.imageURL {
                        if let imageData = urlContents {
                            self.image = UIImage(data: imageData)
                        } else {
                            self.image = Utilities.imageNotFetchedEmoji.emojiToImage(size: Utilities.imageElementWidth)
                            if let notify = self.indicateWhatImageIsWrong {
                                notify()
                            }
                        }
                    }
                }
            }
        }
    }
}
