//
//  GalleriesTableViewController.swift
//  
//
//  Created by Ksenia Surikova on 17.09.2021.
//

import UIKit

class GalleriesTableViewController: UITableViewController {

    // no more need in iOS14, because causes navigation to selected Gallery once again (even we come back to primary table controller from Gallery)
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //        if let currentIndex = lastIndexPath {
    //            selectRow(at: currentIndex)
    //        } else
    //        {
    //            selectRow(at: IndexPath(row: 0, section: 0))
    //        }
    //    }

    // MARK: - Model

    var imageGallery: [Gallery] =
    [Gallery(name: "Sample gallery", images:
                [ImageElement( aspectRatio: 0.67, imageUrl: URL(string: "http://www.planetware.com/photos-large/F/france-paris-eiffel-tower.jpg")!),
                 ImageElement( aspectRatio: 1.5, imageUrl: URL(string: "https://adriatic-lines.com/wp-content/uploads/2015/04/canal-of-Venice.jpg")!),
                 ImageElement( aspectRatio: 0.8, imageUrl: URL(string: "http://www.picture-newsletter.com/arctic/arctic-12.jpg")!)
                ]
            ),
     Gallery(name: "Empty gallery")]

    private var deletedImageGallery: [Gallery] = [Gallery]()

    private var lastIndexPath: IndexPath?

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return imageGallery.count
        case 1: return deletedImageGallery.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "GalleryCell", for: indexPath)
            if let galleryCell = cell as? TitleEditableTableViewCell {
                galleryCell.textField?.text = imageGallery[indexPath.row].name
                galleryCell.resignationHandler = { [weak self, unowned galleryCell] in
                    guard let self = self else { return }
                    if let newTitle = galleryCell.textField.text {
                        self.imageGallery[indexPath.row].name = newTitle
                        self.tableView.reloadData()
                        self.selectRow(at: IndexPath(row: indexPath.row, section: indexPath.section))
                    }
                }
                galleryCell.singleTapHandle = {[weak self] in
                    guard let self = self else { return }
                    self.selectRow(at: indexPath, withDelay: 0)
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath)
            cell.textLabel?.text = deletedImageGallery[indexPath.row].name
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return ""
        case 1: return NSLocalizedString("Recently Deleted", comment: "Recently Deleted")
        default: return ""
        }
    }

    // MARK: - TableView actions

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 {
            let undeleteAction = UIContextualAction(style: .normal,
                                                    title: "Undelete") { [self] (_, _, boolValue) in
                boolValue(true) // pass true if you want the handler to allow the action
                // Move to normal section
                tableView.performBatchUpdates({
                    let galleryInfo = self.deletedImageGallery.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    let newIndexPath = IndexPath(row: imageGallery.endIndex, section: 0)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                    imageGallery.insert(galleryInfo, at: imageGallery.endIndex)
                }, completion: { _ in
                    self.selectRow(at: IndexPath(row: self.imageGallery.endIndex - 1, section: 0),
                                   withDelay: TimeInterval(Utilities.selectingRowDelay))
                })
            }
            let swipeActions = UISwipeActionsConfiguration(actions: [undeleteAction])
            return swipeActions
        } else {
            return nil
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.section == 0 {
                // Move to another section - Recently Deleted
                tableView.performBatchUpdates({
                    let galleryInfo = imageGallery.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    let newIndexPath = IndexPath(row: deletedImageGallery.endIndex, section: 1)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                    deletedImageGallery.insert(galleryInfo, at: deletedImageGallery.endIndex)
                }, completion:
                { _ in
                    // need to calculate delay because completion will call after block straight, but there is animation there
                    self.selectRow(at: IndexPath(row: self.deletedImageGallery.endIndex - 1, section: 1),
                                   withDelay: TimeInterval(Utilities.selectingRowDelay))
                })
            }
            if indexPath.section == 1 {
                // permanently delete
                tableView.performBatchUpdates({
                    _ = deletedImageGallery.remove(at: indexPath.item)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }, completion:
                { _ in
                    self.selectRow(at: IndexPath(row: 0, section: 0), withDelay: TimeInterval(Utilities.selectingRowDelay))
                })
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    private func selectRow(at indexPath: IndexPath, withDelay delay: TimeInterval = TimeInterval(0)) {
        if tableView(self.tableView,
                     numberOfRowsInSection: indexPath.section) >= indexPath.row {
            Timer.scheduledTimer(
                withTimeInterval: delay,
                repeats: false,
                block: { _ in
                    self.tableView.selectRow(at: indexPath,
                                             animated: false,
                                             scrollPosition: .none)
                    // no more call it
                    // self.tableView(self.tableView, didSelectRowAt: indexPath)
                    // instead do it right now
                    // need to check if we move cell to "recently deleted" section
                    if indexPath.section == 0 {
                        self.performSegue(withIdentifier: "show gallery", sender: indexPath)
                    }
                }
            )
        }
    }

    // MARK: - Table view delegate
    // no more do it, because now we hadle single and double tap in cell,
    // in other way double tap hadling works uncorrectly in iOS14
    //    override func tableView(_ tableView: UITableView,
    //                            didSelectRowAt indexPath: IndexPath) {
    //        // segue only for usual galleries, no recently deleted
    //        if indexPath.section == 0 {
    //            performSegue(withIdentifier: "show gallery", sender: indexPath)
    //        }
    //    }

    // MARK: Insert new gallery item
    @IBAction func addGallery(_ sender: UIBarButtonItem) {
        imageGallery.append(Gallery(name: "New gallery".madeUnique(withRespectTo: imageGallery.map { $0.name })))
        tableView.reloadData()
        selectRow(at: IndexPath(row: self.imageGallery.endIndex - 1, section: 0))
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "show gallery":
                if
                    let indexPath = sender as? IndexPath,
                    let vc = segue.destination.contents as? GalleryCollectionViewController {
                    if indexPath.section == 0 {
                        vc.imageGallery = imageGallery[indexPath.item]
                        vc.title = imageGallery[indexPath.item].name
                        vc.collectionView?.isUserInteractionEnabled = true
                        // no more need in iOS 14 and higher
                        // vc.navigationItem.leftBarButtonItem = //splitViewController?.displayModeButtonItem
                        self.lastIndexPath = indexPath
                    }
                }
            default: break
            }
        }
    }
}
