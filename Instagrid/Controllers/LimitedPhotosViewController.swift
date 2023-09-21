//
//  LimitedPhotosViewController.swift
//  Instagrid
//
//  Created by Idrisse Angama on 09/18/2023.
//

import UIKit

class LimitedPhotosViewController: UIViewController {

    var limitedPhotos = [UIImage]() /// Variable that stores the user-selected private images
    var delegate: LimitedPhotosViewControllerDelegate? /// Variable that stores the delegate of this class
    
    @IBOutlet weak var stackView: UIStackView! /// StackView containing the selected photos
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configurePhotoViews()
        
    }
    
    /// Function that assigns each selected photo to an imageView
    private func configurePhotoViews() {
        for (index, photoView) in self.stackView.arrangedSubviews.enumerated() {
            if index < self.limitedPhotos.count {
                if let photoView = photoView as? UIImageView {
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidSelectImage))
                    photoView.image = self.limitedPhotos[index]
                    photoView.contentMode = .scaleToFill
                    photoView.isUserInteractionEnabled = true
                    photoView.addGestureRecognizer(tapGesture)
                }
            }
        }
    }
    
    /// Function that calls the didSelectImage method of the class's delegate
    /// - Parameter sender: PhotoView that was clicked
    @objc func userDidSelectImage(_ sender: UITapGestureRecognizer) {
        if let tappedImageView = sender.view as? UIImageView {
            if let image = tappedImageView.image {
                delegate?.didSelectImage(image)
            }
        }
        self.dismiss(animated: true)
    }

}

protocol LimitedPhotosViewControllerDelegate {
    func didSelectImage(_ image: UIImage)
}
