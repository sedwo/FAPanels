//
//  FAPanel+InterfaceRotation.swift
//  FAPanels
//
//  Created by Fahid Attique on 25/06/2017.
//  Copyright © 2017 Fahid Attique. All rights reserved.
//

import Foundation
import UIKit

extension FAPanelController {

    //  Handling Interface Rotations

    override open var shouldAutorotate: Bool {
            guard let visiblePanel = visiblePanelVC else { return true }

            if configs.handleAutoRotation && visiblePanel.responds(to: #selector(getter: self.shouldAutorotate)) {
                return visiblePanel.shouldAutorotate
            } else {
                return true
            }
        }

    override open func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {

        centerPanelContainer.frame = updateCenterPanelSlidingFrame()
        layoutSideContainers(withDuration: duration, animated: true)
        layoutSidePanelVCs()

        if centerPanelHidden {
            var frame: CGRect  = centerPanelContainer.frame
            frame.origin.x = state == .left ? centerPanelContainer.frame.size.width : -centerPanelContainer.frame.size.width
            centerPanelContainer.frame = frame
        }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        switch state {
        case .center:
            if let centerPanelVC = centerPanelVC {
                return centerPanelVC.preferredStatusBarStyle
            }
        case .left:
            if let leftPanelVC = leftPanelVC {
                return leftPanelVC.preferredStatusBarStyle
            }
        case .right:
            if let rightPanelVC = rightPanelVC {
                return rightPanelVC.preferredStatusBarStyle
            }
        }
        return super.preferredStatusBarStyle
    }

}
