//
//  FAPanel.swift
//  FAPanels
//
//  Created by Fahid Attique on 10/06/2017.
//  Copyright © 2017 Fahid Attique. All rights reserved.
//

import UIKit

// FAPanel Delegate

public protocol FAPanelStateDelegate: class {

    func centerPanelWillBecomeActive()
    func leftPanelWillBecomeActive()
    func rightPanelWillBecomeActive()

    func centerPanelDidBecomeActive()
    func leftPanelDidBecomeActive()
    func rightPanelDidBecomeActive()

    func didUnloadLeftPanelView()
    func didUnloadRightPanelView()
}

public extension FAPanelStateDelegate {

    func centerPanelWillBecomeActive() {}
    func leftPanelWillBecomeActive() {}
    func rightPanelWillBecomeActive() {}

    func centerPanelDidBecomeActive() {}
    func leftPanelDidBecomeActive() {}
    func rightPanelDidBecomeActive() {}

    func didUnloadLeftPanelView() {}
    func didUnloadRightPanelView() {}
}


// Left Panel Position

public enum FASidePanelPosition: Int {
    case front = 0, back
}


// FAPanel Controller

open class FAPanelController: UIViewController {

    // MARK: - Open

    open var configs = FAPanelConfigurations()

    open func center( _ controller: UIViewController, afterThat completion: (() -> Void)?) {
        setCenterPanelVC(controller, afterThat: completion)
    }

    @discardableResult open func center( _ controller: UIViewController) -> FAPanelController {
        centerPanelVC = controller
        return self
    }

    @discardableResult open func left( _ controller: UIViewController?) -> FAPanelController {
        leftPanelVC = controller
        return self
    }

    @discardableResult open func right( _ controller: UIViewController?) -> FAPanelController {
        rightPanelVC = controller
        return self
    }

    open func openLeft(animated: Bool) {
        openLeft(animated: animated, shouldBounce: configs.bounceOnLeftPanelOpen)
    }

    open func openRight(animated: Bool) {
        openRight(animated: animated, shouldBounce: configs.bounceOnRightPanelOpen)
    }

    open func openCenter(animated: Bool) {     //  Can be used for the same menu option selected
        if centerPanelHidden {
            centerPanelHidden = false
            unhideCenterPanel()
        }
        openCenter(animated: animated, shouldBounce: configs.bounceOnCenterPanelOpen, afterThat: nil)
    }

    open func closeLeft() {
        if isLeftPanelOnFront {
            slideLeftPanelOut(animated: true, afterThat: nil)
        } else {
            openCenter(animated: true)
        }
    }

    open func closeRight() {
        if isRightPanelOnFront {
            slideRightPanelOut(animated: true, afterThat: nil)
        } else {
            openCenter(animated: true)
        }
    }

    // MARK: - Life Cycle

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        viewConfigurations()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.isMovingToParentViewController {
            layoutSideContainers(withDuration: 0.0, animated: false)
            layoutSidePanelVCs()
            centerPanelContainer.frame = updateCenterPanelSlidingFrame()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCenterPanelSlidingFrame()
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if configs.showShadowUnderSidePanels {
            var shadowPath = UIBezierPath(rect: leftPanelContainer.bounds)
            leftPanelContainer.layer.masksToBounds = false
            leftPanelContainer.layer.shadowColor = configs.shadowColor
            leftPanelContainer.layer.shadowOffset = configs.shadowOffset
            leftPanelContainer.layer.shadowOpacity = configs.shadowOpacity
            leftPanelContainer.layer.shadowPath = shadowPath.cgPath

            shadowPath = UIBezierPath(rect: rightPanelContainer.bounds)
            rightPanelContainer.layer.masksToBounds = leftPanelContainer.layer.masksToBounds
            rightPanelContainer.layer.shadowColor = leftPanelContainer.layer.shadowColor
            rightPanelContainer.layer.shadowOffset = CGSize(width: -configs.shadowOffset.width,
                                                            height: configs.shadowOffset.height)
            rightPanelContainer.layer.shadowOpacity = leftPanelContainer.layer.shadowOpacity
            rightPanelContainer.layer.shadowPath = shadowPath.cgPath
        }
    }

    deinit {
        if centerPanelVC != nil {
            centerPanelVC!.removeObserver(self, forKeyPath: keyPathOfView)
        }
    }

    private func viewConfigurations() {
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        centerPanelContainer = UIView(frame: view.bounds)
        centeralPanelSlidingFrame = self.centerPanelContainer.frame
        centerPanelHidden = false
        leftPanelContainer = UIView(frame: view.bounds)
        layoutLeftContainer()
        leftPanelContainer.isHidden = true
        rightPanelContainer = UIView(frame: view.bounds)
        layoutRightContainer()
        rightPanelContainer.isHidden = true
        containersConfigurations()
        view.addSubview(centerPanelContainer)
        view.addSubview(leftPanelContainer)
        view.addSubview(rightPanelContainer)
        state = .center
        swapCenter(animated: false, FromVC: nil, withVC: centerPanelVC)
        view.bringSubview(toFront: centerPanelContainer)
    }

    private func containersConfigurations() {
        leftPanelContainer.autoresizingMask   = [.flexibleHeight, .flexibleRightMargin]
        rightPanelContainer.autoresizingMask  = [.flexibleHeight, .flexibleLeftMargin]
        centerPanelContainer.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        centerPanelContainer.frame =  view.bounds
    }


    // MARK: - internal Properties

    internal var leftPanelContainer: UIView!
    internal var rightPanelContainer: UIView!
    internal var centerPanelContainer: UIView!

    internal var visiblePanelVC: UIViewController!
    internal var centeralPanelSlidingFrame: CGRect   = CGRect.zero
    internal var centerPanelOriginBeforePan: CGPoint = CGPoint.zero
    internal var leftPanelOriginBeforePan: CGPoint   = CGPoint.zero
    internal var rightPanelOriginBeforePan: CGPoint   = CGPoint.zero

    internal let keyPathOfView = "view"
    internal static var kvoContext: Character!

    internal var _leftPanelPosition: FASidePanelPosition = .back {
        didSet {

            if _leftPanelPosition == .front {
                configs.resizeLeftPanel = false
            }

            layoutLeftContainer()
        }
    }

    internal var isLeftPanelOnFront: Bool {
        return leftPanelPosition == .front
    }

    open var leftPanelPosition: FASidePanelPosition {
        get {
            return _leftPanelPosition
        }
        set {
            _leftPanelPosition = newValue
        }
    }

    internal var _rightPanelPosition: FASidePanelPosition = .back {
        didSet {

            if _rightPanelPosition == .front {
                configs.resizeRightPanel = true
            }

            layoutRightContainer()
            layoutSidePanelVCs()
        }
    }

    internal var isRightPanelOnFront: Bool {
        return rightPanelPosition == .front
    }

    open var rightPanelPosition: FASidePanelPosition {
        get {
            return _rightPanelPosition
        }
        set {
            _rightPanelPosition = newValue
        }
    }

    internal enum GestureStartDirection: UInt { case left = 0, right, none }
    internal var paningStartDirection: GestureStartDirection = .none

    internal var _leftPanelVC: UIViewController?
    internal var leftPanelVC: UIViewController? {
        get {
            return _leftPanelVC
        }
        set {

            if newValue != _leftPanelVC {

                _leftPanelVC?.willMove(toParentViewController: nil)
                _leftPanelVC?.view.removeFromSuperview()
                _leftPanelVC?.removeFromParentViewController()

                _leftPanelVC = newValue
                if _leftPanelVC != nil {
                    addChildViewController(_leftPanelVC!)
                    _leftPanelVC!.didMove(toParentViewController: self)
                } else {
                    leftPanelContainer.isHidden = true
                }
                if state == .left {
                    visiblePanelVC = _leftPanelVC
                }
            }
        }
    }

    open var left: UIViewController? {
        return leftPanelVC
    }

    internal var _rightPanelVC: UIViewController?
    internal var rightPanelVC: UIViewController? {
        get {
            return _rightPanelVC
        }
        set {

            if newValue != _rightPanelVC {

                _rightPanelVC?.willMove(toParentViewController: nil)
                _rightPanelVC?.view.removeFromSuperview()
                _rightPanelVC?.removeFromParentViewController()

                _rightPanelVC = newValue
                if _rightPanelVC != nil {
                    addChildViewController(_rightPanelVC!)
                    _rightPanelVC?.didMove(toParentViewController: self)
                } else {
                    rightPanelContainer.isHidden = true
                }
                if state == .right {
                    visiblePanelVC = _rightPanelVC
                }
            }
        }
    }

    open var right: UIViewController? {
        return rightPanelVC
    }

    internal var _centerPanelVC: UIViewController?
    internal var centerPanelVC: UIViewController? {
        get {
            return _centerPanelVC
        }
        set {
            setCenterPanelVC(newValue, afterThat: nil)
        }
    }

    open var center: UIViewController? {
        return centerPanelVC
    }

    internal func setCenterPanelVC( _ newValue: UIViewController?, afterThat completion: (() -> Void)? = nil) {
        let previousVC: UIViewController? = _centerPanelVC

        if _centerPanelVC != newValue {
            _centerPanelVC?.removeObserver(self, forKeyPath: keyPathOfView)
            _centerPanelVC = newValue
            _centerPanelVC!.addObserver(self,
                                        forKeyPath: keyPathOfView,
                                        options: NSKeyValueObservingOptions.initial,
                                        context: &FAPanelController.kvoContext)
            if state == .center {
                visiblePanelVC = _centerPanelVC
            }
        }

        if isViewLoaded && state == .center {
            swapCenter(animated: configs.changeCenterPanelAnimated, FromVC: previousVC, withVC: _centerPanelVC!)
        } else if self.isViewLoaded {
            if state == .left {
                if isLeftPanelOnFront {
                    swapCenter(animated: false, FromVC: previousVC, withVC: self._centerPanelVC)
                    slideLeftPanelOut(animated: true, afterThat: completion)
                    return
                }
            } else if state == .right {
                if isRightPanelOnFront {
                    swapCenter(animated: false, FromVC: previousVC, withVC: self._centerPanelVC)
                    slideRightPanelOut(animated: true, afterThat: completion)
                    return
                }
            }

            UIView.animate(withDuration: 0.2, animations: {
                if self.configs.bounceOnCenterPanelChange {
                    let x: CGFloat  = (self.state == .left) ? self.view.bounds.size.width : -self.view.bounds.size.width
                    self.centeralPanelSlidingFrame.origin.x = x
                }

                self.centerPanelContainer.frame = self.centeralPanelSlidingFrame

            }, completion: { (finised) in
                self.swapCenter(animated: false, FromVC: previousVC, withVC: self._centerPanelVC)
                self.openCenter(animated: true, shouldBounce: false, afterThat: completion)
            })
        }
    }

    //  Left panel frame on basis of its position type i.e: front or back

    internal func layoutLeftContainer() {
        if isLeftPanelOnFront {
            if leftPanelContainer != nil {
                var frame = leftPanelContainer.frame
                frame.size.width = widthForLeftPanelVC
                frame.origin.x = -widthForLeftPanelVC
                leftPanelContainer.frame = frame
            }
        } else {
            if leftPanelContainer != nil {
                leftPanelContainer.frame = view.bounds
            }
        }
    }

    internal func layoutRightContainer() {
        if isRightPanelOnFront {
            if rightPanelContainer != nil {
                var frame = rightPanelContainer.frame
                frame.size.width = widthForRightPanelVC
                frame.origin.x =  view.frame.size.width
                rightPanelContainer.frame = frame
            }
        } else {

            if rightPanelContainer != nil {
                rightPanelContainer.frame = view.bounds
            }
        }
    }

    //  tap view on centeral panel, to dismiss side panels if visible

    internal var _tapView: UIView?
    internal var tapView: UIView? {
        get {
            return _tapView
        }
        set {
            if newValue != _tapView {
                _tapView?.removeFromSuperview()
                _tapView = newValue
                if _tapView != nil {

                    if configs.showDarkOverlayUnderLeftPanelOnTop && leftPanelPosition == .front && state == .left {
                        _tapView?.backgroundColor = configs.darkOverlayUnderLeftPanelOnTopColor
                    } else if configs.showDarkOverlayUnderRightPanelOnTop && rightPanelPosition == .front && state == .right {
                        _tapView?.backgroundColor = configs.darkOverlayUnderRightPanelOnTopColor
                    }

                    _tapView?.frame = centerPanelContainer.bounds
                    _tapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    addTapGestureToView(view: _tapView!)
                    if configs.canRecognizePanGesture { addPanGesture(toView: _tapView!) }
                    centerPanelContainer.addSubview(_tapView!)
                }
            }
        }
    }

    //  visible widths for side panels

    internal var widthForLeftPanelVC: CGFloat {
        if centerPanelHidden && configs.resizeLeftPanel {
            return view.bounds.size.width
        } else {
            return configs.leftPanelWidth == 0.0 ? floor(view.bounds.size.width * configs.leftPanelGapPercentage) : configs.leftPanelWidth
        }
    }

    internal var widthForRightPanelVC: CGFloat {
        if centerPanelHidden && configs.resizeRightPanel {
            return view.bounds.size.width
        } else {
            return configs.rightPanelWidth == 0 ? floor(view.bounds.size.width * configs.rightPanelGapPercentage) : configs.rightPanelWidth
        }
    }

    //  style for panels

    internal func applyStyle(onView: UIView) {
        onView.layer.cornerRadius = configs.cornerRadius
        onView.clipsToBounds = true
    }

    //  Panel States

    open weak var panelStateDelegate: FAPanelStateDelegate?

    internal  var _state: FAPanelVisibleState = .center {
        willSet {
            switch newValue {
            case .center:
                panelStateDelegate?.centerPanelWillBecomeActive()

            case .left:
                panelStateDelegate?.leftPanelWillBecomeActive()

            case .right:
                panelStateDelegate?.rightPanelWillBecomeActive()
            }
        }

        didSet {

            switch _state {
            case .center:
                panelStateDelegate?.centerPanelDidBecomeActive()

            case .left:
                panelStateDelegate?.leftPanelDidBecomeActive()

            case .right:
                panelStateDelegate?.rightPanelDidBecomeActive()
            }
        }
    }

    internal  var  state: FAPanelVisibleState {
        get {
            return _state
        }
        set {
            if _state != newValue {
                _state = newValue
                switch _state {

                case .center:
                    visiblePanelVC = centerPanelVC
                    leftPanelContainer.isUserInteractionEnabled  = false
                    rightPanelContainer.isUserInteractionEnabled = false

                case .left:
                    visiblePanelVC = leftPanelVC
                    leftPanelContainer.isUserInteractionEnabled   = true

                case .right:
                    visiblePanelVC = rightPanelVC
                    rightPanelContainer.isUserInteractionEnabled  = true
                }

                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    //  Center Panel Hiding Functions

    internal var _centerPanelHidden: Bool = false
    internal var centerPanelHidden: Bool {
        get {
            return _centerPanelHidden
        }
        set {
            setCenterPanelHidden(newValue, animated: false, duration: 0.0)
        }
    }

    internal func setCenterPanelHidden(_ hidden: Bool, animated: Bool, duration: TimeInterval) {

        if hidden != _centerPanelHidden && state != .center {
            _centerPanelHidden = hidden
            let animationDuration = animated ? duration : 0.0
            if hidden {

                UIView.animate(withDuration: animationDuration, animations: {

                    var frame: CGRect = self.centerPanelContainer.frame
                    frame.origin.x = self.state == .left ? self.centerPanelContainer.frame.size.width : -self.centerPanelContainer.frame.size.width
                    self.centerPanelContainer.frame = frame
                    self.layoutSideContainers(withDuration: 0.0, animated: false)

                    if self.configs.resizeLeftPanel || self.configs.resizeRightPanel {
                        self.layoutSidePanelVCs()
                    }
                }, completion: { (finished) in

                    if self._centerPanelHidden {
                        self.hideCenterPanel()
                    }
                })

            } else {
                unhideCenterPanel()

                UIView.animate(withDuration: animationDuration, animations: {

                    if self.state == .left {
                        self.openLeft(animated: false)
                    } else {
                        self.openRight(animated: false)
                    }
                    if self.configs.resizeLeftPanel || self.configs.resizeRightPanel {
                        self.layoutSidePanelVCs()
                    }
                })
            }
        }
    }
}
