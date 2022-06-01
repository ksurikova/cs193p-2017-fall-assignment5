//
//  ImageViewController.swift
//  SimpleImageGallery
//
//  Created by Ksenia Surikova on 15.09.2021.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: Override view cycle methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageView.image == nil {
            fetchImage()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        zoomScaleToFit()
    }
    
    
    // MARK: Storyboard
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = Utilities.minimumZoomScale
            scrollView.maximumZoomScale = Utilities.maximumZoomScale
            scrollView.delegate = self
            scrollView.addSubview(imageView)
        }
    }
    
    // MARK: UIScrollViewDelegate
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // delete autozoom after user zooms with pinch gesture
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        autoZoomed = false
    }


    // MARK: Model
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
            autoZoomed = true
            zoomScaleToFit()
        }
    }
    
    var imageView  = UIImageView()
    
    var autoZoomed = false
    

    // calculate zoom fit to screen size, without empty gaps
    private func zoomScaleToFit()
    {
        guard autoZoomed else {return }
        // if all geometry stuff is loaded, set zoomScale property
        if let sv = scrollView , image != nil && (imageView.bounds.size.width > 0)
            && (scrollView.bounds.size.width > 0){
            let widthRatio = scrollView.bounds.size.width  / imageView.bounds.size.width
            let heightRatio = scrollView.bounds.size.height / self.imageView.bounds.size.height
            sv.zoomScale = (widthRatio > heightRatio) ? widthRatio : heightRatio
            // fit to image's center, define upper left corner
            sv.contentOffset = CGPoint(x: (imageView.frame.size.width - sv.frame.size.width) / 2,
                                       y: (imageView.frame.size.height - sv.frame.size.height) / 2)
        }
    }
    
    private func fetchImage() {
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self?.imageURL {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
  
}
