//
//  SwipeViewController.swift
//

struct MatchCardModel {
    let id: String
    let title: String
    let imageUrl: String
    let location: String
    let date: String
}

import UIKit

class SwipeViewController: BaseClassVc {
    
    // MARK: - Outlets
    @IBOutlet weak var tinderVw: UIView!
    @IBOutlet weak var gradientView: UIView! // 👈 NEW
    private var cards: [MatchCardModel] = []
    private var visibleCards: [MatchCardView] = []
    
    private let maxVisibleCards = 3
    
    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        tinderVw.isHidden = true
//        fetchCards()
    }
    
    
    // MARK: - API
    private func fetchCards() {
        // Replace with real API
        cards = [
            MatchCardModel(id: "1", title: "Tokyo Adventure Squad", imageUrl: "https://picsum.photos/400/600", location: "Tokyo", date: "Apr 15"),
            MatchCardModel(id: "2", title: "Beach Party", imageUrl: "https://picsum.photos/401/600", location: "Bali", date: "Apr 20"),
            MatchCardModel(id: "3", title: "Mountain Trip", imageUrl: "https://picsum.photos/402/600", location: "Swiss", date: "May 1"),
            MatchCardModel(id: "4", title: "Desert Ride", imageUrl: "https://picsum.photos/403/600", location: "Dubai", date: "May 10")
        ]
        
        setupInitialCards()
    }
    
    // MARK: - Setup Stack
    private func setupInitialCards() {
        let count = min(maxVisibleCards, cards.count)
        
        for i in 0..<count {
            addCard(at: i)
        }
    }
    
    private func addCard(at index: Int) {
        let card = MatchCardView(frame: frameForCard())
        card.model = cards[index]
        
        // stack effect
        let scale = 1 - CGFloat(index) * 0.05
        let yOffset = CGFloat(index) * 10
        
        card.transform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: 0, y: yOffset)
        
        view.addSubview(card)
        view.sendSubviewToBack(card)
        
        visibleCards.append(card)
        
        if index == 0 {
            attachGesture(to: card)
        }
    }
    
    private func frameForCard() -> CGRect {
        return CGRect(x: 20,
                      y: 150,
                      width: view.frame.width - 40,
                      height: 500)
    }
    
    // MARK: - Gesture
    private var originalCenter: CGPoint = .zero
    
    private func attachGesture(to card: MatchCardView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        card.addGestureRecognizer(pan)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view as? MatchCardView else { return }
        
        let translation = gesture.translation(in: view)
        let percent = translation.x / view.bounds.width
        
        switch gesture.state {
            
        case .began:
            originalCenter = card.center
            
        case .changed:
            card.center = CGPoint(
                x: originalCenter.x + translation.x,
                y: originalCenter.y + translation.y
            )
            
            card.transform = CGAffineTransform(rotationAngle: percent * 0.4)
            
        case .ended:
            let velocity = gesture.velocity(in: view)
            
            if abs(translation.x) > 120 || abs(velocity.x) > 500 {
                swipe(card: card, toRight: translation.x > 0)
            } else {
                reset(card: card)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Swipe Logic
    private func swipe(card: MatchCardView, toRight: Bool) {
        let offX = toRight ? view.frame.width * 2 : -view.frame.width * 2
        
        UIView.animate(withDuration: 0.3, animations: {
            card.center.x = offX
            card.alpha = 0
        }) { _ in
            self.removeTopCard()
        }
    }
    
    private func reset(card: MatchCardView) {
        UIView.animate(withDuration: 0.25) {
            card.center = self.originalCenter
            card.transform = .identity
        }
    }
    
    private func removeTopCard() {
        guard !visibleCards.isEmpty else { return }
        
        let removed = visibleCards.removeFirst()
        removed.removeFromSuperview()
        
        // shift remaining cards
        for (index, card) in visibleCards.enumerated() {
            UIView.animate(withDuration: 0.2) {
                let scale = 1 - CGFloat(index) * 0.05
                let yOffset = CGFloat(index) * 10
                
                card.transform = CGAffineTransform(scaleX: scale, y: scale)
                    .translatedBy(x: 0, y: yOffset)
            }
        }
        
        // add next card from API
        let nextIndex = visibleCards.count
        if cards.count > nextIndex {
            addCard(at: nextIndex)
        }
        
        // reattach gesture to new top card
        if let top = visibleCards.first {
            attachGesture(to: top)
        }
        
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


class MatchCardView: UIView {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    var model: MatchCardModel? {
        didSet { configure() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 20
        clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        addSubview(titleLabel)
        
        imageView.frame = bounds
        titleLabel.frame = CGRect(x: 16, y: bounds.height - 60, width: bounds.width - 32, height: 40)
        titleLabel.textColor = .white
    }
    
    private func configure() {
        guard let model = model else { return }
        titleLabel.text = model.title
        
        // Load image (use SDWebImage / Kingfisher in real app)
        DispatchQueue.global().async {
            if let url = URL(string: model.imageUrl),
               let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }
    }
}
