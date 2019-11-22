//
//  RSDScrollingOverviewStepViewController.swift
//  ResearchUI (iOS)
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/// The scrolling overview step view controller is a custom subclass of the overview step view controller
/// that uses a scrollview to allow showing detailed overview instructions.
open class RSDScrollingOverviewStepViewController: RSDOverviewStepViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    /// The constraint that sets the scroll bar's top background view's height.
    @IBOutlet
    open weak var scrollViewBackgroundHeightConstraint: NSLayoutConstraint!

    /// The constraint that sets the distance between the title and the image.
    @IBOutlet
    var titleTopConstraint: NSLayoutConstraint!
    
    /// The collection view cell re-usable identifiers
    let iconCollectionHeaderTitleCellResuableCellId = "HeaderTitleCell"
    let iconCollectionViewCellResuableCellId = "IconCollectionCell"

    /// The collection view associated with this view controller.
    @IBOutlet
    open var iconCollectionView: RSDVerticalGridCollectionView!
    @IBOutlet
    open var iconCollectionViewHeight: NSLayoutConstraint!

    /// The scroll view that contains the elements which scroll.
    @IBOutlet
    open var scrollView: UIScrollView!

    /// The constraint that sets the heigh of the learn more button.
    @IBOutlet
    var learnMoreHeightConstraint: NSLayoutConstraint!

    /// The overview step for this view controller
    open var overviewStep: RSDOverviewStep? {
        return self.step as? RSDOverviewStep
    }

    open var iconCollectionViewHeaderTitle: String {
         return Localization.localizedString("OVERVIEW_WHAT_YOU_NEED")
    }
    
    open var iconCollectionViewHeaderHeight: CGFloat {
        // Create the label to size it correctly dynamically
        let label = RSDTitleHeaderCollectionViewHeader.createTitleLabel()
        label.frame = CGRect(x: 0, y: 0, width: iconCollectionView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        //here, be sure you set the font type and size that matches the one set in the storyboard label
        if let system = self.designSystem {
            label.font = RSDTitleHeaderCollectionViewHeader.titleLabelFont(for: system)
        }
        label.text = self.iconCollectionViewHeaderTitle
        label.sizeToFit()
        return label.frame.height + (RSDTitleHeaderCollectionViewHeader.kCollectionHeaderTopMargin + RSDTitleHeaderCollectionViewHeader.kCollectionHeaderBottomMargin)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()
    }

    /// Overrides viewWillAppear to add an info button, display the icons, to save
    /// the current Date to UserDefaults, and to use the saved date to decide whether
    /// or not to show the full task info or an abbreviated screen.
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let overviewStep = self.overviewStep,
            let icons = overviewStep.icons, icons.count == 0 {
            self.iconCollectionViewHeight.constant = 0.0
            self.iconCollectionView.removeFromSuperview()
        }

        // Hide learn more action if it is not provided by the step json
        if self.stepViewModel.shouldHideAction(for: .navigation(.learnMore)) {
            self.learnMoreButton?.setTitle(nil, for: .normal)
            self.learnMoreButton?.isHidden = true
            self.learnMoreHeightConstraint.constant = 0
        }

        // Update the image placement constraint based on the status bar height.
        updateImagePlacementConstraints()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.forceFullHeightForCollectionView()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let shouldShowInfo = !(self.stepViewModel.rootPathComponent.shouldShowAbbreviatedInstructions ?? false)
        if shouldShowInfo {
            self._scrollToBottom()
            self._stopAnimating()
        } else if let titleLabel = self.stepTitleLabel {
            // We add a 30 pixel margin to the bottom of the title label so it isn't squished
            // up against the bottom of the scroll view.
            let frame = titleLabel.frame.offsetBy(dx: 0, dy: 30)
            // On the SE this fixes the title label being chopped off, on larger screens this is
            // expected to do nothing.
            self.scrollView.scrollRectToVisible(frame, animated: false)
        }
    }

    /// Sets the height of the scroll views top background view depending on
    /// the image placement type from this step.
    open func updateImagePlacementConstraints() {
        guard let placementType = self.imageTheme?.placementType else { return }
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        self.scrollViewBackgroundHeightConstraint.constant = (placementType == .topMarginBackground) ? statusBarHeight : CGFloat(0)
    }

    override open func setColorStyle(for placement: RSDColorPlacement, background: RSDColorTile) {
        super.setColorStyle(for: placement, background: background)

        if placement == .body {
            scrollView.backgroundColor = background.color
        }
    }

    /// Stops the animation view from animating.
    private func _stopAnimating() {
        /// The image view that is used to show the animation.
        let animationView = (self.navigationHeader as? RSDStepHeaderView)?.imageView
        animationView?.stopAnimating()
    }

    // Makes the scroll view scroll all the way down.
    private func _scrollToBottom() {
        let frame = self.scrollView.convert(self.iconCollectionView.bounds, from: self.iconCollectionView)
        let shiftedFrame = frame.offsetBy(dx: 0, dy: 20)
        self.scrollView.scrollRectToVisible(shiftedFrame, animated: false)
    }

    // MARK: UICollectionView setup and delegates

    fileprivate func setupCollectionView() {
        
        self.iconCollectionView.gridLayout.columnCount = 3
        self.iconCollectionView.gridLayout.cellSpacing = 8
        self.iconCollectionView.gridLayout.cellHeight = 120
        self.iconCollectionView.gridLayout.itemCount = self.overviewStep?.icons?.count ?? 0
        
        if let flowLayout = self.iconCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.headerReferenceSize = CGSize(width: iconCollectionView.bounds.width, height: self.iconCollectionViewHeaderHeight)
        }
        
        self.iconCollectionView.register(RSDTitleHeaderCollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: iconCollectionHeaderTitleCellResuableCellId)
        
        self.iconCollectionView.register(RSDOverviewCollectionViewCell.self, forCellWithReuseIdentifier: iconCollectionViewCellResuableCellId)
        
        self.iconCollectionView.reloadData()
    }

    /// Look at the collection view content height and make the height constraint equal to it
    fileprivate func forceFullHeightForCollectionView() {
        // Make collectionview the full height of its content
        self.iconCollectionViewHeight.constant = self.iconCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.iconCollectionView.collectionViewLayout.invalidateLayout()
        // Disable user interection so that the scrollview can properly scroll
        self.iconCollectionView.isUserInteractionEnabled = false
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.iconCollectionView.gridLayout.cellSize(for: indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.iconCollectionView.gridLayout.itemCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = self.iconCollectionView.dequeueReusableCell(withReuseIdentifier: iconCollectionViewCellResuableCellId, for: indexPath)

        if let overviewCell = cell as? RSDOverviewCollectionViewCell {
                        
            // Center the content horizontally with layout margins
            let horizontalOffsets = self.iconCollectionView.gridLayout.horizontalPaddingToCenter(for: indexPath.row)
            overviewCell.setLeadingTrailingPadding(leadingPadding: horizontalOffsets.leading, trailingPadding: horizontalOffsets.trailing)
            
            overviewCell.setDesignSystem(self.designSystem, with: self.backgroundColor(for: .body))
            if let icons = self.overviewStep?.icons,
                indexPath.row < icons.count {
                let icon = icons[indexPath.row]
                overviewCell.imageView?.image = icon.icon?.embeddedImage()
                overviewCell.titleLabel?.text = icon.title
            }
        }

        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        return CGSize(width: iconCollectionView.bounds.width, height: self.iconCollectionViewHeaderHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: iconCollectionHeaderTitleCellResuableCellId, for: indexPath)

            if let rsdCell = headerCell as? RSDTitleHeaderCollectionViewHeader {
                rsdCell.setDesignSystem(self.designSystem, with: self.backgroundColor(for: .header))
                rsdCell.titleLabel?.text = self.iconCollectionViewHeaderTitle
            }
            
            return headerCell
        }
        return UICollectionReusableView()
    }

    // MARK: Initialization

    /// The default nib name to use when instantiating the view controller using `init(step:)`.
    override open class var nibName: String {
        return String(describing: RSDScrollingOverviewStepViewController.self)
    }

    /// The default bundle to use when instantiating the view controller using `init(step:)`.
    override open class var bundle: Bundle {
        return Bundle(for: RSDScrollingOverviewStepViewController.self)
    }
}

public class RSDTitleHeaderCollectionViewHeader: RSDCollectionViewCell {
    
    static let kCollectionHeaderTopMargin: CGFloat = 8.0
    static let kCollectionHeaderBottomMargin: CGFloat = 8.0
    
    @IBOutlet public var titleLabel: UILabel?

    fileprivate static var titleTextType: RSDDesignSystem.TextType = .mediumHeader

    public override init(frame: CGRect) {
        super.init(frame:frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        commonInit()
    }

    func updateColorsAndFonts() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let background = self.backgroundColorTile ?? RSDGrayScale().white
        let contentTile = designSystem.colorRules.tableCellBackground(on: background, isSelected: isSelected)

        contentView.backgroundColor = UIColor.red//contentTile.color
        titleLabel?.textColor = designSystem.colorRules.textColor(on: contentTile, for: RSDTitleHeaderCollectionViewHeader.titleTextType)
        titleLabel?.font = RSDTitleHeaderCollectionViewHeader.titleLabelFont(for: designSystem)
    }
    
    fileprivate static func titleLabelFont(for designSystem: RSDDesignSystem) -> UIFont {
        return designSystem.fontRules.font(for: RSDTitleHeaderCollectionViewHeader.titleTextType)
    }

    override open func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        updateColorsAndFonts()
    }

    private func commonInit() {
        // Add the title label
        titleLabel = RSDTitleHeaderCollectionViewHeader.createTitleLabel()
        contentView.addSubview(titleLabel!)

        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel!.rsd_alignCenterHorizontal(padding: 0.0)
        titleLabel!.rsd_alignToSuperview([.top], padding: RSDTitleHeaderCollectionViewHeader.kCollectionHeaderTopMargin)
        titleLabel!.rsd_alignToSuperview([.bottom], padding: RSDTitleHeaderCollectionViewHeader.kCollectionHeaderBottomMargin)

        updateColorsAndFonts()
        setNeedsUpdateConstraints()
    }
    
    fileprivate static func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }
}

/// `RSDSelectionTableViewCell` is the base implementation for a selection collection view cell.
@IBDesignable open class RSDOverviewCollectionViewCell: RSDCollectionViewCell, RSDGridCollectionViewCell {

    @IBOutlet public var titleLabel: UILabel?
    @IBOutlet public var imageView: UIImageView?
    
    var titleLeadingTrailingConstraints: [NSLayoutConstraint]!
    var imageLeadingTrailingConstraints: [NSLayoutConstraint]!

    open private(set) var titleTextType: RSDDesignSystem.TextType = .small

    public override init(frame: CGRect) {
        super.init(frame:frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        commonInit()
    }

    func updateColorsAndFonts() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let background = self.backgroundColorTile ?? RSDGrayScale().white
        let contentTile = designSystem.colorRules.tableCellBackground(on: background, isSelected: isSelected)

        contentView.backgroundColor = UIColor.red// contentTile.color
        titleLabel?.textColor = designSystem.colorRules.textColor(on: contentTile, for: titleTextType)
        titleLabel?.font = designSystem.fontRules.font(for: titleTextType, compatibleWith: traitCollection)
    }

    override open func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        updateColorsAndFonts()
    }

    private func commonInit() {
        self.backgroundColor = UIColor.white

        // Add the title label
        titleLabel = UILabel()
        contentView.addSubview(titleLabel!)
        
        titleLabel!.translatesAutoresizingMaskIntoConstraints = false
        titleLabel!.numberOfLines = 0
        titleLabel!.textAlignment = .center
        titleLeadingTrailingConstraints = titleLabel!.rsd_alignToSuperview([.leading, .trailing], padding: kCollectionCellSideMargin)
        titleLabel!.rsd_alignToSuperview([.bottom], padding: kCollectionCellBottomMargin)
        titleLabel?.backgroundColor = UIColor.green

        // Add the image view
        imageView = UIImageView()
        contentView.addSubview(imageView!)

        imageView!.contentMode = .scaleAspectFit
        imageView!.translatesAutoresizingMaskIntoConstraints = false
        imageLeadingTrailingConstraints = imageView!.rsd_alignToSuperview([.leading, .trailing], padding: 0)
        imageView!.rsd_alignToSuperview([.top], padding: 0)
        imageView!.rsd_alignAbove(view: titleLabel!, padding: 0)
        imageView?.backgroundColor = UIColor.yellow

        updateColorsAndFonts()
        setNeedsUpdateConstraints()
    }
    
    public func setLeadingTrailingPadding(leadingPadding: CGFloat, trailingPadding: CGFloat) {
        // Re-assert the leading/trailing constraints to scale the cells all the same
        titleLeadingTrailingConstraints[0].constant = leadingPadding
        titleLeadingTrailingConstraints[1].constant = -trailingPadding
        imageLeadingTrailingConstraints[0].constant = leadingPadding
        imageLeadingTrailingConstraints[1].constant = -trailingPadding
        setNeedsUpdateConstraints()
    }
}
