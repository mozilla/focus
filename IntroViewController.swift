/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Foundation

struct IntroViewControllerUX {
    static let Width = 302
    static let Height = 460
    static let MinimumFontScale: CGFloat = 0.5

    static let CardSlides = ["onboarding_1", "onboarding_2", "onboarding_3"]

    static let PagerCenterOffsetFromScrollViewBottom = 24

    static let StartBrowsingButtonColor = UIColor(rgb: 0x4990E2)
    static let StartBrowsingButtonHeight = 56

    static let CardTextLineHeight = UIScreen.main.bounds.width <= 320 ? CGFloat(2) : CGFloat(6)
    static let CardTextWidth = UIScreen.main.bounds.width <= 320 ? 240 : 280
    static let CardTitleHeight = 50

    static let FadeDuration = 0.25
}

class IntroViewController: UIViewController {
    
    let pageControl = UIPageControl()
    let containerView = UIView()
    let skipButton = UIButton()
    let background = GradientBackgroundView(alpha: 0.7)
    
    var pageViewController: ScrollViewController = ScrollViewController() {
        didSet {
            pageViewController.scrollViewControllerDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }
        
        pageViewController = ScrollViewController()
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        
        pageControl.backgroundColor = .clear
        pageControl.isUserInteractionEnabled = false
        pageControl.snp.makeConstraints { make in
            make.top.equalTo(pageViewController.view.snp.centerY).offset(IntroViewControllerUX.Height/2 + IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
            make.width.equalTo(20)
            make.height.equalTo(6)
            make.centerX.equalTo(self.view)
        }
        
        skipButton.backgroundColor = .clear
        skipButton.setTitle(UIConstants.strings.SkipIntroButtonTitle, for: .normal)
        skipButton.titleLabel?.font = UIConstants.fonts.aboutText
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.addTarget(self, action: #selector(IntroViewController.didTapSkipButton), for: UIControlEvents.touchUpInside)
        
        skipButton.snp.makeConstraints { make in
            make.bottom.equalTo(pageViewController.view.snp.centerY).offset(-IntroViewControllerUX.Height/2 - IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
            make.leading.equalTo(self.view.snp.centerX).offset(-IntroViewControllerUX.Width/2)
//            make.width.equalTo(60)
        }
    }
    
    @objc func didTapSkipButton(sender: UIButton) {
        background.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
}

extension IntroViewController: ScrollViewControllerDelegate {
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
}

class ScrollViewController: UIPageViewController {
    private var slides = [UIImage]()
    private var orderedViewControllers: [UIViewController] = []
    weak var scrollViewControllerDelegate: ScrollViewControllerDelegate?
    
    override init(transitionStyle style: UIPageViewControllerTransitionStyle, navigationOrientation: UIPageViewControllerNavigationOrientation, options: [String : Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        for slideName in IntroViewControllerUX.CardSlides {
            slides.append(UIImage(named: slideName)!)
        }
        
        addCard(title: UIConstants.strings.CardTitleWelcome, text: UIConstants.strings.CardTextWelcome, viewController: UIViewController(), image: UIImageView(image: slides[0]))
        addCard(title: UIConstants.strings.CardTitleSearch, text: UIConstants.strings.CardTextSearch, viewController: UIViewController(), image: UIImageView(image: slides[1]))
        addCard(title: UIConstants.strings.CardTitleHistory, text: UIConstants.strings.CardTextHistory, viewController: UIViewController(), image: UIImageView(image: slides[2]))
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true,completion: nil)
        }
        
        scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageCount: orderedViewControllers.count)
    }
    
    func addCard(title: String, text: String, viewController: UIViewController, image: UIImageView) {
        let introView = UIView()
        viewController.view.backgroundColor = .clear
        viewController.view.addSubview(introView)
        
        introView.backgroundColor = .white
        introView.layer.shadowRadius = 12
//        introView.layer.shadowOffset = CGSize(
//        introView.layer.sha
        introView.layer.shadowOpacity = 0.5
        introView.layer.cornerRadius = 6
        
        introView.addSubview(image)
        image.snp.makeConstraints { make in
            make.top.equalTo(introView)
            make.centerX.equalTo(introView)
            make.width.equalTo(280)
            make.height.equalTo(212)
        }
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = IntroViewControllerUX.MinimumFontScale
        titleLabel.textColor = UIConstants.colors.firstRunTitle
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.text = title
        titleLabel.font = UIConstants.fonts.firstRunTitle
        
        introView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make ) -> Void in
            make.top.equalTo(image.snp.bottom)
            make.leading.equalTo(introView).offset(24)
            make.trailing.equalTo(introView).inset(24)
            make.centerX.equalTo(introView)
            make.height.equalTo(IntroViewControllerUX.CardTitleHeight)
            make.width.equalTo(IntroViewControllerUX.CardTextWidth)
        }
        
        let textLabel = UILabel()
        textLabel.numberOfLines = 5
        textLabel.attributedText = attributedStringForLabel(text)
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = IntroViewControllerUX.MinimumFontScale
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textColor = UIConstants.colors.firstRunMessage
        textLabel.font = UIConstants.fonts.firstRunMessage
        
        introView.addSubview(textLabel)
        textLabel.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalTo(introView)
            make.leading.equalTo(introView).offset(24)
            make.trailing.equalTo(introView).inset(24)
        })
        
        introView.snp.makeConstraints { (make) -> Void in
            make.center.equalTo(viewController.view)
            make.width.equalTo(IntroViewControllerUX.Width)
            make.height.equalTo(IntroViewControllerUX.Height)
        }
        
        let cardButton = UIButton()

        if orderedViewControllers.count == slides.count - 1 {
            cardButton.setTitle(UIConstants.strings.firstRunButton, for: .normal)
            cardButton.setTitleColor(UIConstants.colors.firstRunNextButton, for: .normal)
            cardButton.titleLabel?.font = UIConstants.fonts.firstRunButton
            cardButton.addTarget(self, action: #selector(ScrollViewController.didTapStartBrowsingButton), for: UIControlEvents.touchUpInside)
        } else {
            cardButton.setTitle(UIConstants.strings.NextIntroButtonTitle, for: .normal)
            cardButton.setTitleColor(UIConstants.colors.firstRunNextButton, for: .normal)
            cardButton.titleLabel?.font = UIConstants.fonts.firstRunButton
            cardButton.addTarget(self, action: #selector(ScrollViewController.didTapNextButton), for: UIControlEvents.touchUpInside)
        }
            
        introView.addSubview(cardButton)
        introView.bringSubview(toFront: cardButton)
        cardButton.snp.makeConstraints { make in
            make.bottom.equalTo(introView).offset(-24)
            make.centerX.equalTo(introView)
        }
        orderedViewControllers.append(viewController)
    }
    
    @objc func didTapStartBrowsingButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapNextButton() {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
        guard let viewControllerIndex = orderedViewControllers.index(of: nextViewController) else { return }
        scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageIndex: viewControllerIndex)
    }
    
    fileprivate func attributedStringForLabel(_ text: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = IntroViewControllerUX.CardTextLineHeight
        paragraphStyle.alignment = .center
        
        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))
        return string
    }
}

extension ScrollViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.index(of: firstViewController) {
            scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageIndex: index)
        }
    }
}

extension ScrollViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }

        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1

        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return orderedViewControllers[nextIndex]
    }
}

protocol ScrollViewControllerDelegate: class {
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageCount count: Int)
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageIndex index: Int)
}
