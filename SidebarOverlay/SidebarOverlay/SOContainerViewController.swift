//
//  SOContainerViewController.swift
//  SidebarOverlay
//
//  Created by Alex Krzyżanowski on 12/23/15.
//  Copyright © 2015 Alex Krzyżanowski. All rights reserved.
//

import UIKit


public extension UIViewController {
    
    ///
    /// Use this computed property to access the container view controller from any view controller.
    ///
    /// - returns: An instance of `SOContainerViewController` that holds current view controller
    ///     or `nil` if there is not container view controller.
    var so_containerViewController: SOContainerViewController? {
        if self is SOContainerViewController {
            return self as? SOContainerViewController
        }
        if let parentVC = self.parentViewController {
            return parentVC.so_containerViewController
        }
        return nil
    }
    
}


public class SOContainerViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let LeftViewControllerRightIndent: CGFloat = 56.0
    let LeftViewControllerOpenedLeftOffset: CGFloat = 0.0
    let SideViewControllerOpenAnimationDuration: NSTimeInterval = 0.24
    
    var _topViewController: UIViewController?
    var _leftViewController: UIViewController?
    
    public var topViewController: UIViewController? {
        get {
            return _topViewController
        }
        set {
            _topViewController?.view.removeFromSuperview()
            _topViewController?.removeFromParentViewController()
            
            _topViewController = newValue
            
            if let vc = _topViewController {
                vc.willMoveToParentViewController(self)
                self.addChildViewController(vc)
                self.view.addSubview(vc.view)
                vc.didMoveToParentViewController(self)
                
                vc.view.addGestureRecognizer(self.createPanGestureRecognizer())
            }
            
            self.brindLeftViewToFront()
        }
    }
    
    public var leftViewController: UIViewController? {
        get {
            return _leftViewController
        }
        set {
            _leftViewController?.view.removeFromSuperview()
            _leftViewController?.removeFromParentViewController()
            
            _leftViewController = newValue
            
            if let vc = _leftViewController {
                vc.willMoveToParentViewController(self)
                self.addChildViewController(vc)
                self.view.addSubview(vc.view)
                vc.didMoveToParentViewController(self)
                
                vc.view.addGestureRecognizer(self.createPanGestureRecognizer())
                
                var menuFrame = vc.view.frame
                menuFrame.size.width = self.view.frame.size.width - LeftViewControllerRightIndent
                menuFrame.origin.x = -menuFrame.size.width
                vc.view.frame = menuFrame
            }
            
            self.brindLeftViewToFront()
        }
    }
    
    public var isLeftViewControllerPresented: Bool {
        get {
            guard let leftVC = self.leftViewController else {
                return false
            }
            
            return leftVC.view.frame.origin.x == LeftViewControllerOpenedLeftOffset
        }
        set {
            guard let leftVC = self.leftViewController else {
                return
            }
            
            var frame = leftVC.view.frame
            frame.origin.x = newValue ? LeftViewControllerOpenedLeftOffset : -frame.size.width
            
            let animations = { () -> () in
                leftVC.view.frame = frame
            }
            
            UIView.animateWithDuration(SideViewControllerOpenAnimationDuration, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: animations, completion: nil)
        }
    }
    
    public func moveMenu(panGesture: UIPanGestureRecognizer) {
        panGesture.view?.layer.removeAllAnimations()
        
        let translatedPoint = panGesture.translationInView(self.view)
        
        if panGesture.state == UIGestureRecognizerState.Changed {
            if let sidebarView = self.leftViewController?.view {
                self.moveSidebarToVector(sidebarView, vector: translatedPoint)
            }
            
            panGesture.setTranslation(CGPointMake(0, 0), inView: self.view)
        }
        else if panGesture.state == UIGestureRecognizerState.Ended {
            if let sidebar = self.leftViewController {
                self.isLeftViewControllerPresented = self.viewPulledOutMoreThanHalfOfItsWidth(sidebar)
            }
        }
    }
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
        let translation = panGestureRecognizer.translationInView(self.view)
        return self.vectorIsMoreHorizontal(translation)
    }
    
    //
    // MARK: Internal usage
    
    func brindLeftViewToFront() {
        if let vc = self.leftViewController {
            self.view.bringSubviewToFront(vc.view)
        }
    }
    
    func createPanGestureRecognizer() -> UIPanGestureRecognizer! {
        return UIPanGestureRecognizer.init(target: self, action: "moveMenu:")
    }
    
    func vectorIsMoreHorizontal(point: CGPoint) -> Bool {
        if fabs(point.x) > fabs(point.y) {
            return true
        }
        return false
    }
    
    func viewPulledOutMoreThanHalfOfItsWidth(viewController: UIViewController) -> Bool {
        let frame = viewController.view.frame
        return fabs(frame.origin.x) < frame.size.width / 2
    }
    
    func moveSidebarToVector(sidebar: UIView, vector: CGPoint) {
        let calculatedXPosition = min(sidebar.frame.size.width / 2.0, sidebar.center.x + vector.x)
        sidebar.center = CGPointMake(calculatedXPosition, sidebar.center.y)
    }
    
}
