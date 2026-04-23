//
//  ChatVc.swift
//  TravelDate
//

import UIKit

class ChatVc: BaseClassVc {
    
    @IBOutlet weak var tblVw: UITableView!
    @IBOutlet weak var btnSegment: UISegmentedControl!
    
    private var segmentSetupDone = false

    // MARK: - ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNib()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupSegmentUI()
    }
    
    func registerNib() {
        tblVw.register(ChatTableViewCell.self)
    }
    
    func setupSegmentUI() {
        guard !segmentSetupDone else { return }
        segmentSetupDone = true

        let height      = btnSegment.bounds.height
        let width       = btnSegment.bounds.width
        let inset: CGFloat = 4
        let pillH       = height - (inset * 2)
        let pillW       = (width / CGFloat(btnSegment.numberOfSegments)) - (inset * 2)

        // ── Outer container ──────────────────────────────────────
        btnSegment.backgroundColor  = UIColor.white.withAlphaComponent(0.08)
        btnSegment.layer.cornerRadius  = height / 2          // perfect pill
        btnSegment.layer.masksToBounds = true

        // Remove ALL Apple default chrome
        btnSegment.setBackgroundImage(
            UIImage(), for: .normal,   barMetrics: .default)
        btnSegment.setBackgroundImage(
            UIImage(), for: .selected, barMetrics: .default)
        btnSegment.setBackgroundImage(
            UIImage(), for: .highlighted, barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .normal,
            barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .selected,
            rightSegmentState: .normal,
            barMetrics: .default)
        btnSegment.setDividerImage(
            UIImage(),
            forLeftSegmentState: .normal,
            rightSegmentState: .selected,
            barMetrics: .default)

        // ── Orange pill (selected) ────────────────────────────────
        // Draw pill with EQUAL corner radius on both sides
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pillW, height: pillH))
        let pillImage = renderer.image { ctx in
            let path = UIBezierPath(
                roundedRect: CGRect(x: 0, y: 0, width: pillW, height: pillH),
                cornerRadius: pillH / 2          // ← full round both ends
            )
            UIColor.themeOrange.setFill()
            path.fill()
        }

        // Make it stretchable — preserve both rounded caps
        let cap = pillH / 2
        let stretchable = pillImage.resizableImage(
            withCapInsets: UIEdgeInsets(top: cap, left: cap, bottom: cap, right: cap),
            resizingMode: .stretch
        )

        btnSegment.setBackgroundImage(stretchable, for: .selected, barMetrics: .default)

        // ── Segment content insets (keeps pill away from container edge) ──
        for i in 0..<btnSegment.numberOfSegments {
            btnSegment.setWidth(width / CGFloat(btnSegment.numberOfSegments), forSegmentAt: i)
        }

        // ── Typography ───────────────────────────────────────────
        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ], for: .normal)

        btnSegment.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ], for: .selected)

        // ── Default selection ─────────────────────────────────────
        btnSegment.selectedSegmentIndex = 0   // "My group" selected
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView)
    }
}

// MARK: - TableViewDelegate
extension ChatVc: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int { 4 }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChatTableViewCell = tableView.dequeue(
            ChatTableViewCell.self, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { 80 }
}

extension ChatVc {
    @IBAction func btnBack(_ sender: UIButton) {
        super.backTapped()
    }
}
