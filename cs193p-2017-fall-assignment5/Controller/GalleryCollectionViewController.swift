//
//  GalleryCollectionViewController.swift
//  SimpleImageGallery
//
//  Created by Ksenia Surikova on 17.08.2021.
//

import UIKit

class GalleryCollectionViewController: UICollectionViewController,
                                       UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate,
                                       UICollectionViewDropDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.dropDelegate = self
        collectionView!.dragDelegate = self
        // add pinch gesture
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(zoom(by: )))
        collectionView!.addGestureRecognizer(pinchGestureRecognizer)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        flowLayout?.invalidateLayout()
    }

    // MARK: - For counting image cell size
    var flowLayout: UICollectionViewFlowLayout? {
        collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }

    var scale: CGFloat = Utilities.defaultScale {
        didSet {
            flowLayout?.invalidateLayout()
        }
    }

    var boundsCollectionWidth: CGFloat {
        (collectionView?.bounds.width)!
    }
    var gapItems: CGFloat {
        (flowLayout?.minimumInteritemSpacing)! * (Utilities.imageInLineCount - 1)
    }

    var insets: CGFloat {
        (flowLayout?.sectionInset.left)! +
        (flowLayout?.sectionInset.right)! +
        (collectionView?.contentInset.left)! +
        (collectionView?.contentInset.right)!
    }

    var predefinedWidth: CGFloat {
        let width = floor(
            (boundsCollectionWidth - gapItems - insets)
            / Utilities.imageInLineCount) * scale
        return  min(width, boundsCollectionWidth)
    }

    // MARK: - Pinch gesture handling - zoom
    @objc func zoom(by recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            scale = recognizer.scale
        default:
            break
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier {
            switch identifier {
            case "show image":
                if let imageCell = sender as? ImageCollectionViewCell,
                   let indexPath = collectionView?.indexPath(for: imageCell),
                   let vc = segue.destination as? ImageViewController {
                    vc.imageURL = imageGallery.images[indexPath.item].imageUrl
                }
            default: break
            }
        }
    }

    //
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let cell = sender as? UICollectionViewCell else { return false }
        if let indexPath = collectionView?.indexPath(for: cell) {
            if let fetched = imageGallery.images[indexPath.item].isImageFetched, fetched == false {
                return false
            } else {return true }
        } else { return false }
    }

    // MARK: Model
    var imageGallery: Gallery = Gallery(name: "empty gallery") {
        didSet {
            // same pointer in memory checking
            if !(imageGallery===oldValue) {
                collectionView?.reloadData()
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return imageGallery.images.count
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell =
                collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell",
                                                                   for: indexPath)
            if let imageCell = cell as? ImageCollectionViewCell {
                imageCell.imageURL =
                    imageGallery.images[indexPath.item]
                    .imageUrl
                imageCell.indicateWhatImageIsWrong = {  [weak self] in
                    self?.imageGallery.images[indexPath.item].aspectRatio = 1.0
                    self?.imageGallery.images[indexPath.item].isImageFetched = false
                    self?.flowLayout?.invalidateLayout()
                }
            }
            return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = predefinedWidth
        let aspectRatio = CGFloat(imageGallery.images[indexPath.item].aspectRatio)
        let height = width / aspectRatio
        return CGSize(width: width, height: height)
    }

    // MARK: - UICollectionViewDragDelegate
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }

    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let image = (collectionView?.cellForItem(at: indexPath) as? ImageCollectionViewCell)?.imageView.image {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = image
            return [dragItem]
        } else {
            return []
        }
    }

    // MARK: - UICollectionViewDropDelegate
    func collectionView( _ collectionView: UICollectionView,
                         performDropWith coordinator: UICollectionViewDropCoordinator
    ) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            // move locally
            if let sourceIndexPath = item.sourceIndexPath {
                if (item.dragItem.localObject as? UIImage) != nil {
                    collectionView.performBatchUpdates({
                        let imageInfo = imageGallery.images.remove(at: sourceIndexPath.item)
                        imageGallery.images.insert(imageInfo, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }
            // move from another application
            else {
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(
                        insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                var imageURLLocal: URL?
                var aspectRatioLocal: CGFloat?
                // simultaneously download both image and url
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, _) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            aspectRatioLocal = CGFloat(image.size.width / image.size.height)
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, _) in
                    DispatchQueue.main.async {
                        if let url = provider as? URL {
                            imageURLLocal = url.imageURL
                        }
                        if let imageURL = imageURLLocal, let aspectRatio = aspectRatioLocal {
                            placeholderContext.commitInsertion(
                                dataSourceUpdates: { insertionIndexPath in self.imageGallery.images.insert(
                                    ImageElement(aspectRatio: aspectRatio, imageUrl: imageURL), at: insertionIndexPath.item)
                            })
                        } else { placeholderContext.deletePlaceholder() }
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        //  drag and drop locally - images
        if  (session.localDragSession?.localContext as? UICollectionView) == collectionView {
            return session.canLoadObjects(ofClass: UIImage.self)
        }
        // drag and drop from another applcations - the object should be an image and url at the same time
        else {
            return session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: NSURL.self)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
}
