//
//  SwipeViewController.swift
//

import UIKit

class SwipeViewController: BaseClassVc {
    
    // MARK: - Outlets
    @IBOutlet weak var tinderVw: UIView!
    @IBOutlet weak var gradientView: UIView! // 👈 NEW
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradient()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        tinderVw.layer.cornerRadius = 30
        tinderVw.clipsToBounds = true
    }
    
    // MARK: - Gradient
    private func applyGradient() {
        tinderVw.layer.borderWidth = 0.5
//        tinderVw.layer.borderColor = UIColor.red as! CGColor
        gradientLayer?.removeFromSuperlayer()
        
        let gradient = CAGradientLayer()
        gradient.frame = gradientView.bounds
        
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.themeOrange.withAlphaComponent(0.6).cgColor,
            UIColor.themeOrange.withAlphaComponent(0.8).cgColor
        ]
        
        gradient.locations = [0.5, 0.8, 1.0]
        
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        gradientView.layer.addSublayer(gradient)
        gradientLayer = gradient
    }
}
