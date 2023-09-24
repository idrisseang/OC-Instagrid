//
//  ViewController.swift
//  Instagrid
//
//  Created by Idrisse Angama on 26/08/2023.
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    

    // MARK: - @IBOutlet Connections
    @IBOutlet weak var label: UILabel! /// The label in the storyboard "Swipe up / left to share"
    @IBOutlet weak var isSelectedView: UIImageView! /// The view to add when a layout is selected
    @IBOutlet var dispositionChoices: [UIButton]! /// An array containing all the buttons to set the 3 layouts
    @IBOutlet weak var mainView: UIView! /// The main view we want to render at the end
    
    // MARK: - Some private variables
    private var selectedPhotoView: Int?
    private var limited: Bool = false
    private var disposition: Disposition {
        return Disposition(view: self.mainView)
    }
    
    private var dispositionMainStackView: UIStackView {
        return self.disposition.view.subviews[0] as! UIStackView
    }
    private var stackViews : [UIStackView] {
        return self.dispositionMainStackView.arrangedSubviews as! [UIStackView]
    }
    private var photoViews: [UIButton] {
        self.stackViews.flatMap { $0.arrangedSubviews as! [UIButton] }
    }
    private var selectedDisposition: Int = 0
    private var selectedImages = [UIImage]()
    var limitedSelectedImage = UIImage()
    private var currentDeviceOrientation = UIDevice.current.orientation
    
   
    //MARK: - Load the view
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDispositionVisibility(selectedDisposition: selectedDisposition)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
        self.disposition.delegate = self
        self.triggerDidTouchForPhotoViews()
        
    }
    
    // MARK: - Orientation Change ?
    
    /// Function called when the iPhone's orientation changes
    @objc func orientationDidChange() {
        self.setSwipeGesture()
    }
    
    //MARK: - PhotoViews Touch
    
    /// Function that triggers the tap on the photoView
    private func triggerDidTouchForPhotoViews() {
        self.photoViews.forEach { photoView in
            photoView.addTarget(self, action: #selector(didTouchPhotoView(_:)), for: .touchUpInside)
        }
    }
    
    //MARK: - Picker Section
    
    /// Function that sets up the photo picker
    /// - Parameters:
    ///   - selectedPhotoView: Index of the selected photo frame
    ///   - limited: Indicates if the picker is in limited mode or not
    private func presentPickerView(selectedPhotoView: Int, limited: Bool) {
        DispatchQueue.main.async {
            self.selectedPhotoView = selectedPhotoView
            self.limited = limited
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images /// Filter to retrieve only images from the photo library
            configuration.selectionLimit = limited ? 3 : 1 /// Set a selection limit for the number of images

            let picker = PHPickerViewController(configuration: configuration) /// Configure the PHPicker
            picker.delegate = self
            self.present(picker, animated: true) /// Display the picker to the user
        }
    }
    
    // MARK: - Handle Swipe Gestures
    
    /// Function to check if all frames are filled with different photos than the "Plus" placeholder
    /// - Returns: True or false based on the above check
    private func isAllPhotoViewsFilled() -> Bool {
        return self.photoViews.allSatisfy { $0.imageView?.image?.pngData() != UIImage(named: "Plus")?.pngData()}
    }
    
    /// Function to set up the swipe gesture on the screen
    /// - Parameter direction: Swipe direction (up, down...)
    private func setupSwipeGesture(forDirection direction: UISwipeGestureRecognizer.Direction) {
        removeAllExistingSwipeGestures()
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe))
        swipe.direction = direction
        view.addGestureRecognizer(swipe)
    }

    
    /// Configure the swipe direction based on the device's orientation
    private func setSwipeGesture() {
        switch UIDevice.current.orientation {
        case .portrait:
            setupSwipeGesture(forDirection: .up)
        case .landscapeRight:
            setupSwipeGesture(forDirection: .left)
        default:
            break
        }
    }
    
    /// Trigger certain actions on swipe
    /// - Parameter gesture: Represents the swipe performed by the user
    @objc private func onSwipe(_ gesture: UISwipeGestureRecognizer) {
        if self.isAllPhotoViewsFilled() { /// If all frames are filled with different photos than "Plus"
            switch gesture.direction {
            case .up: /// If the swipe is upward
                animateDisposition(translationX: 0, y: -self.view.frame.height) /// Animate the view by moving it upward
            case .left: /// If the swipe is to the left
                animateDisposition(translationX: -self.view.frame.width, y: 0) /// Animate the view by sliding it to the left
            default:
                break
            }
            self.presentShareView() /// Once the view disappears, display the shareView for sharing the image
        } else { /// Otherwise, display an alert indicating that there are still frames containing "Plus" placeholders
            let okButton = UIAlertAction(title: "OK", style: .default)
            let actions = [okButton]
            showAlert(
                title: "Sharing not possible!",
                message: "You can't share your layout yet because some frames are still empty. Fill all the frames to continue.",
                actions: actions)
        }
    }
    
    private func removeAllExistingSwipeGestures() {
        self.view.gestureRecognizers?.forEach({ gesture in
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                self.view.removeGestureRecognizer(swipeGesture)
            }
        })
    }
    
    // MARK: - Animation
    
    private func animateDisposition(translationX: CGFloat, y: CGFloat) {
        UIView.animate(withDuration: 0.5, animations: {
            self.disposition.view.transform = CGAffineTransform(translationX: translationX, y: y)
        }) { (_) in
            self.presentShareView()
        }
    }
    
    // MARK: - Alerts section
    
    /// Create and display an alert to the user
    /// - Parameters:
    ///   - title: Title of the alert
    ///   - message: Message of the alert explicitly describing why we're showing the alert to the user
    ///   - actions: Actions present in the alert (OK, go to settings)
    private func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    private func showAccessDeniedAlert() {
        
        let goToSettingsButton = UIAlertAction(title: "Go to settings", style: .default) { (action) in
            DispatchQueue.main.async {
                let url = URL(string: UIApplication.openSettingsURLString)!
                UIApplication.shared.open(url)
            }
        }
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        
        let actions = [goToSettingsButton, cancelButton]
        showAlert(
            title: "Access Denied!",
            message: "Access to photos denied! Please update your Settings if you want to add a photo.",
            actions: actions)
        
    }
    

    // MARK: - Handle Dispositions
    @IBAction func didChooseDisposition(_ sender: UIButton) {
        if let selectedDisposition = dispositionChoices.firstIndex(of: sender) {
            self.selectedDisposition = selectedDisposition
            updateDispositionVisibility(selectedDisposition: selectedDisposition)
            self.disposition.setDisposition(selectedDisposition)
        }
    }
    
    private func updateDispositionVisibility(selectedDisposition: Int) {
        isSelectedView.frame = self.dispositionChoices[self.selectedDisposition].bounds
        self.dispositionChoices[self.selectedDisposition].addSubview(isSelectedView)
        isSelectedView.isHidden = false
    }
    
    //MARK: - ShareView - UIActivityController
    /// Allows you to view the view to share the final photo
    private func presentShareView() {
        let image = self.disposition.getTheFinalImage()
        let shareViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil)
        shareViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            UIView.animate(withDuration: 0.3) {
                self.disposition.view.transform = .identity
            }
        }
        self.present(shareViewController, animated: true)
    }
    
    // MARK: - Segue preparation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLimitedPhotosView" {
            let VCDestination = segue.destination as! LimitedPhotosViewController
            VCDestination.limitedPhotos = self.selectedImages
            VCDestination.delegate = self
        }
    }
}

//MARK: - ImagePicker Delegate

extension ViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let group = DispatchGroup()
        if !self.limited { /// If we have access to all photos
            results.forEach { result in
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let selectedPhotoView = self.selectedPhotoView {
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.photoViews[selectedPhotoView].imageEdgeInsets = UIEdgeInsets.zero
                                self.photoViews[selectedPhotoView].imageView?.contentMode = .scaleToFill
                                self.photoViews[selectedPhotoView].setImage(image, for: .normal)
                            }
                        }
                    }
                }
            }
            dismiss(animated: true)
        } else {
            /// If we are in a limited photo selection case
            results.forEach { result in
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        self.selectedImages.append(image) /// Each selected image is added to an array of images
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                self.dismiss(animated: true) {
                    /// Display the segue with the images in the array
                    self.performSegue(withIdentifier: "showLimitedPhotosView", sender: nil)
                }
            }
        }
    }
}

// MARK: - Manage Image selection in LimitedPhotosViewController

extension ViewController: LimitedPhotosViewControllerDelegate {
    func didSelectImage(_ image: UIImage) {
        self.limitedSelectedImage = image
        if let selectedPhotoView = self.selectedPhotoView {
            self.photoViews[selectedPhotoView].imageEdgeInsets = UIEdgeInsets.zero
            self.photoViews[selectedPhotoView].imageView?.contentMode = .scaleToFill
            self.photoViews[selectedPhotoView].setImage(image, for: .normal)
        }
    }
}


// MARK: -  Manage Image Selection

extension ViewController: DispositionDelegate {
    @objc func didTouchPhotoView(_ sender: UIButton) {
            if let selectedPhotoView = self.photoViews.firstIndex(of: sender) {
                self.selectedPhotoView = selectedPhotoView

                PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
                    switch status {
                    case .restricted:
                        let okButton = UIAlertAction(title: "OK", style: .default)
                            let actions = [okButton]
                        self.showAlert(
                                title: "Photo Library Access Restricted",
                                message: "You cannot access to your photo library.",
                                actions: actions
                        )
                    case .denied:
                        self.showAccessDeniedAlert()
                    case .authorized:
                        self.presentPickerView(selectedPhotoView: selectedPhotoView, limited: false)
                    case .limited:
                        if self.selectedImages.isEmpty { /// If the selected images array is empty, present the picker
                            self.presentPickerView(selectedPhotoView: selectedPhotoView, limited: true)
                        } else {
                            /// Otherwise, it means that the user has already selected some images, so show the segue with the images
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "showLimitedPhotosView", sender: nil)
                            }
                        }
                    default:
                        break
                    }
                }
            }
    }
}
