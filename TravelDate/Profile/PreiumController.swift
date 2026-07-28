//
//  Untitled.swift
//  TravelDate
//
//  Created by Dev CodingZone on 22/07/26.
//
enum SubscriptionType {
      case weekly
      case monthly
      case yearly
  }
import UIKit
class PreiumController: BaseClassVc,SubscriptionView {
    
    @IBOutlet weak var lblWeek:UILabel!
    @IBOutlet weak var lblMonth:UILabel!
    @IBOutlet weak var lblYear:UILabel!
    @IBOutlet weak var vwWeek:UIView!
    @IBOutlet weak var vwMonth:UIView!
    @IBOutlet weak var vwYear:UIView!
    @IBOutlet weak var btnContinue:UIButton!
    
    var selectedPlan: SubscriptionType = .weekly
    lazy var presenter = SubscriptionPresenter(view: self)
    
    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupViews()
        selectPlan(.weekly)
        presenter.load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.applicationDidBecomeActive()
    }

    private func setupViews() {

        vwWeek.tag = 101
        vwMonth.tag = 102
        vwYear.tag = 103

        [vwWeek, vwMonth, vwYear].forEach { view in
            let tap = UITapGestureRecognizer(target: self, action: #selector(vwTap(_:)))
            view?.addGestureRecognizer(tap)
            view?.isUserInteractionEnabled = true
            view?.layer.cornerRadius = 12
        }
    }

    @objc func vwTap(_ tap: UITapGestureRecognizer) {

        guard let tag = tap.view?.tag else { return }

        switch tag {

        case 101:
            presenter.selectPlan(at: 0)
            selectPlan(.weekly)

        case 102:
            presenter.selectPlan(at: 1)
            selectPlan(.monthly)

        case 103:
            presenter.selectPlan(at: 2)
            selectPlan(.yearly)

        default:
            break
        }
    }

    private func selectPlan(_ plan: SubscriptionType) {

        selectedPlan = plan

        resetView(vwWeek)
        resetView(vwMonth)
        resetView(vwYear)

        let subscriptionTier: SubscriptionTier

        switch plan {

        case .weekly:
            highlightView(vwWeek)
            subscriptionTier = .weekly

        case .monthly:
            highlightView(vwMonth)
            subscriptionTier = .monthly

        case .yearly:
            highlightView(vwYear)
            subscriptionTier = .yearly
        }

        if let selected = presenter.plans.first(where: { $0.tier == subscriptionTier }) {
            btnContinue.setTitle("Continue - \(selected.priceText)", for: .normal)
        } else {
            btnContinue.setTitle("Continue", for: .normal)
        }
    }

    private func highlightView(_ view: UIView) {
        view.layer.borderColor = UIColor.appOrange.cgColor
        view.layer.borderWidth = 2.5
        view.backgroundColor = UIColor.appOrange.withAlphaComponent(0.12)
    }

    private func resetView(_ view: UIView) {
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.borderWidth = 0
        view.backgroundColor = .clear
    }
    
    
    func loadPrice() {

        for plan in presenter.plans {

            switch plan.tier {

            case .weekly:
                lblWeek.text = plan.priceText

            case .monthly:
                lblMonth.text = plan.priceText

            case .yearly:
                lblYear.text = plan.priceText
            }
        }
    }
}


extension PreiumController {

    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnContinue(_ sender: UIButton) {
            presenter.purchaseSelectedPlan()
        
//        switch selectedPlan {
//
//        case .weekly:
//            print("Subscribe Weekly")
//
//        case .monthly:
//            print("Subscribe Monthly")
//
//        case .yearly:
//            print("Subscribe Yearly")
//        }
        
    }
}

extension PreiumController {

    func showLoading() {
        // Show loader
    }

    func hideLoading() {
        // Hide loader
    }

    func reloadPlans() {

        for plan in presenter.plans {

            switch plan.tier {

            case .weekly:
                lblWeek.text = plan.priceText

            case .monthly:
                lblMonth.text = plan.priceText

            case .yearly:
                lblYear.text = plan.priceText
            }
        }

        // Refresh button with localized price
        selectPlan(selectedPlan)
    }

    func updateCTA(title: String) {
        btnContinue.setTitle(title, for: .normal)
    }

    func purchaseSucceeded() {
        print("Purchase Success")
    }

    func purchaseFailed(message: String) {
        print(message)
    }

    func subscriptionStatusChanged(isSubscribed: Bool) {
        print("Subscribed: \(isSubscribed)")
    }
}
