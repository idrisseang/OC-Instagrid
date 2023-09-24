//
//  Disposition.swift
//  Instagrid
//
//  Created by Idrisse Angama on 15/09/2023.
//

import Foundation
import UIKit

class Disposition {
    
    let view: UIView /// The main view, with a blue background, representing the layout
    var mainStackView: UIStackView {
        self.view.subviews[0] as! UIStackView /// The main stackView contained within the layout, used to store the two sub-StackViews
    }
    var stackViews: [UIStackView] {
        if let stacks = self.mainStackView.arrangedSubviews as? [UIStackView] {
            return stacks
        } else {
            return []
        } /// The two previously mentioned stackViews
    }
    var delegate: DispositionDelegate? /// Delegate of the Disposition class
    
    var photoViews: [UIButton] {
        self.stackViews.flatMap { $0.arrangedSubviews as! [UIButton] } /// The views in which we place the photos
    }
    
    init(view: UIView) {
        self.view = view /// Links the 'view' attribute of the Disposition class with the 'mainView' in the ViewController
    }
    
    /// Function that returns the initial layout with 4 squares
    private func getInitialDisposition() {
        for stackview in self.stackViews { /// Iterate through the two stackViews
            var stackWithRectangle: UIStackView? /// Optional variable that stores, if it exists, the stackView containing the rectangle
            if stackview.arrangedSubviews.count == 1 {
                stackWithRectangle =  stackview /// If the stackView contains only one element, it is the stackView with the rectangle
            }
            
            /// If we have found the stackView with the rectangle, we retrieve the rectangle, which is the view inside this stackView
            if let stackWithRectangle {
                let rectanglePhotoView = stackWithRectangle.arrangedSubviews[0]
                /// Since there is only the rectangle logically, that's why we directly use index 0
                
                rectanglePhotoView.constraints.forEach { constraint in
                    if constraint.firstAttribute == .width {
                        constraint.constant = 120
                    }
                } /// Modifies the width constraint of the rectangle to turn it into a 120x120 square
                
                /// Creating another square view
                let photoView = UIButton()
                photoView.setImage(UIImage(named: "Plus"), for: .normal)
                photoView.backgroundColor = .white
                photoView.isHidden = false
                
                /// Adding constraints to the square for the correct dimensions
                NSLayoutConstraint.activate([
                    photoView.widthAnchor.constraint(equalToConstant: 120),
                    photoView.heightAnchor.constraint(equalToConstant: 120),
                ])
                
                /// Since we have just created this photoView and it is not in the base storyboard, we need to manually add the tapGesture so that it can be clickable
                /// When you click on this photoView, the 'didTouchPhotoView' function of the delegate will be called
                photoView.addTarget(delegate, action: #selector(delegate?.didTouchPhotoView(_:)), for: .touchUpInside)
                
                // Add the square to the stackView to complete the layout with 4 squares
                stackWithRectangle.addArrangedSubview(photoView)
            }
        }
    }
    
    
    /// Function that transforms a layout
    /// - Parameter stackview: StackView in which we will remove one of the squares and then modify the other one to turn it into a rectangle
    private func transformStackView(_ stackview: UIStackView?) {
        if let stackview {
            let photoViews = stackview.arrangedSubviews
            // Remove one of the two present photoViews
            photoViews[0].removeFromSuperview()
            
            /// Modify the width constraint of the remaining photoView to turn it into a rectangle
            photoViews[1].constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.constant = 260
                }
            }
        }
    }
    
    /// Function that changes the layout based on the user's choice
    /// - Parameter selectedDisposition: Index of the layout chosen by the user
    func setDisposition(_ selectedDisposition: Int) {
        switch selectedDisposition {
        case 0: // Here we set the default layout, the one with 4 squares
            self.getInitialDisposition()
            
        case 1:
            self.getInitialDisposition()
            /// Here, the selected layout is the one with 2 squares at the top and 1 rectangle at the bottom
            /// Since the rectangle is at the bottom, the stackView that needs modification is the last one
            let stackView = self.mainStackView.arrangedSubviews.last as! UIStackView
            transformStackView(stackView)
            
        case 2:
            self.getInitialDisposition()
            let stackView = self.mainStackView.arrangedSubviews.first as! UIStackView
            transformStackView(stackView)
            
            /// Here, the selected layout is the one with a rectangle at the top and 2 squares at the bottom
            /// The principle is exactly the same as for the layout above, except that the rectangle is at the top, so the stackView to be modified will be the first one
        default:
            break
            
        }
    }
    
    /// Function that converts the layout into an image
    /// - Returns: An image corresponding to the created photo montage
    func getTheFinalImage() -> UIImage {
        var renderedImage = UIImage()
        /// Set the size of the image, here it's the size of the main view with the blue background that we take
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        renderedImage = renderer.image { context in
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        }
        return renderedImage /// Return the generated image
    }
}

/// Delegate with a function that allows delegation of responsibility when a photoView is touched
@objc protocol DispositionDelegate {
    func didTouchPhotoView(_ sender: UIButton)
}
