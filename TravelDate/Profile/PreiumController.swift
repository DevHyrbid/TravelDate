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
import StoreKit
class PreiumController: BaseClassVc,SubscriptionView {
    
    // MARK: - IBoutlet
    @IBOutlet weak var lblWeek:UILabel!
    @IBOutlet weak var lblMonth:UILabel!
    @IBOutlet weak var lblYear:UILabel!
    @IBOutlet weak var vwWeek:UIView!
    @IBOutlet weak var vwMonth:UIView!
    @IBOutlet weak var vwYear:UIView!
    @IBOutlet weak var btnContinue:UIButton!
    @IBOutlet weak var btnCancel:UIButton!
    @IBOutlet weak var btnCancelHeight:NSLayoutConstraint!
    @IBOutlet weak var btnContinueHeight:NSLayoutConstraint!
    @IBOutlet weak var btnContinueTop:NSLayoutConstraint!
    
    // MARK: - Properties
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
            view?.layer.cornerRadius = 19
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

//    private func selectPlan(_ plan: SubscriptionType) {
//
//        selectedPlan = plan
//
//        resetView(vwWeek)
//        resetView(vwMonth)
//        resetView(vwYear)
//
//        let subscriptionTier: SubscriptionTier
//
//        switch plan {
//
//        case .weekly:
//            highlightView(vwWeek)
//            subscriptionTier = .weekly
//
//        case .monthly:
//            highlightView(vwMonth)
//            subscriptionTier = .monthly
//
//        case .yearly:
//            highlightView(vwYear)
//            subscriptionTier = .yearly
//        }
//
//        if let selected = presenter.plans.first(where: { $0.tier == subscriptionTier }) {
//
//            if isSubscriptionActive(),
//               let currentPlan = currentSubscriptionType(),
//               currentPlan == plan {
//
//                btnContinue.isHidden = true
//                btnContinue.isEnabled = false
//                btnContinue.alpha = 0.5
//                btnCancelHeight.constant = 50
//
//            } else {
//                btnContinue.isHidden = false
//                btnContinue.setTitle("Continue - \(selected.priceText)", for: .normal)
//                btnContinue.isEnabled = true
//                btnContinue.alpha = 1.0
//                btnCancelHeight.constant = 0
//            }
//
//        } else {
//            btnContinue.isHidden = false
//            btnCancelHeight.constant = 0
//            btnContinue.setTitle("Continue", for: .normal)
//        }
//    }
    
    
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

        let hasActiveSubscription = isSubscriptionActive()
        let currentPlan = currentSubscriptionType()

        // If any subscription is active, show Cancel Plan.
        if hasActiveSubscription {
            btnContinue.isHidden = true
            btnContinue.isEnabled = false

            btnCancel.isHidden = false
            btnCancel.isEnabled = true
            btnCancelHeight.constant = 40
            btnContinueHeight.constant = 0
            btnContinueTop.constant = 0

            // Optional: visually highlight the active subscription.
            if currentPlan == .weekly {
                highlightView(vwWeek)
            } else if currentPlan == .monthly {
                highlightView(vwMonth)
            } else if currentPlan == .yearly {
                highlightView(vwYear)
            }

            return
        }

        // No active subscription: show Continue.
        btnCancel.isHidden = true
        btnCancel.isEnabled = false
        btnCancelHeight.constant = 0

        btnContinue.isHidden = false
        btnContinue.isEnabled = true
        btnContinue.alpha = 1.0

        if let selected = presenter.plans.first(where: {
            $0.tier == subscriptionTier
        }) {
            btnContinue.setTitle(
                "Continue - \(selected.priceText)",
                for: .normal
            )
        } else {
            btnContinue.setTitle("Continue", for: .normal)
        }
    }


    private func highlightView(_ view: UIView) {
        view.layer.borderColor = UIColor.appOrange.cgColor
        view.layer.borderWidth = 1.0
        view.backgroundColor = UIColor.appOrange.withAlphaComponent(0.12)
    }

    private func resetView(_ view: UIView) {
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.borderWidth = 0
        view.backgroundColor = UIColor(hex: "151718")
    }
    
    
    func loadPrice() {

        for plan in presenter.plans {

            switch plan.tier {

            case .weekly:
                lblWeek.text = plan.priceText.replacing("US", with: "")

            case .monthly:
                lblMonth.text = plan.priceText.replacing("US", with: "")

            case .yearly:
                lblYear.text = plan.priceText.replacing("US", with: "")
            }
        }
    }
}


extension PreiumController {

    @IBAction func btnBack(_ sender:UIButton) {
        super.backTapped()
    }
    
    @IBAction func btnContinue(_ sender: UIButton) {
        if sender.tag == 1001 {
            guard let windowScene = view.window?.windowScene else { return }

               Task { @MainActor in
                   do {
                       try await AppStore.showManageSubscriptions(in: windowScene)
                   } catch {
                       print(error.localizedDescription)
                   }
               }
        } else {
            presenter.purchaseSelectedPlan()
        }
            
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
                lblWeek.text = plan.priceText.replacing("US", with: "")

            case .monthly:
                lblMonth.text = plan.priceText.replacing("US", with: "")

            case .yearly:
                lblYear.text = plan.priceText.replacing("US", with: "")
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
    
    private func currentSubscriptionType() -> SubscriptionType? {

        guard let plan = User.curentUser?.plan else { return nil }

        switch plan {
        case "com.ios.trips.weekly":
            return .weekly

        case "com.ios.travel.monhtly":
            return .monthly

        case "com.ios.travel.yearly":
            return .yearly

        default:
            return nil
        }
    }
    
    
    private func isSubscriptionActive() -> Bool {

        guard let startDateString = User.curentUser?.planStartDate else {
            return false
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startDate = formatter.date(from: startDateString),
              let currentPlan = currentSubscriptionType() else {
            return false
        }

        var components = DateComponents()

        switch currentPlan {
        case .weekly:
            components.day = 7

        case .monthly:
            components.month = 1

        case .yearly:
            components.year = 1
        }

        guard let expiryDate = Calendar.current.date(byAdding: components, to: startDate) else {
            return false
        }

        return Date() < expiryDate
    }
    
}


extension PreiumController {
    @IBAction func btnLegalTapped(_ sender:UIButton) {
        let legalVC = LegalViewController()

        let nav = UINavigationController(
            rootViewController: legalVC
        )

        present(nav, animated: true)
    }
}
