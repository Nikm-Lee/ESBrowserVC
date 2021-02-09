//
//  JSWebBrowser.swift
//  MesseEsang
//
//  Created by esmnc1 on 2020/01/21.
//  Copyright © 2020 MesseEsang. All rights reserved.
//


import UIKit
import WebKit
import SJFullscreenPopGesture
import RxSwift
import RxCocoa

var process = 0
public enum TransitionType {
    case root
    case push
    case modal
    case fixedModal
    case embed
}
/**
public class JSWebBrowserTransitionManager {
    
    
    public static var shared: JSWebBrowserTransitionManager = {
        let instance = JSWebBrowserTransitionManager()
        return instance
    }()
    
    private init(){}
    
    public var transitionType: TransitionType = .fixedModal
    
  
}
*/
public class JSWebBrowserManager {
    
    public var preference: WKPreferences = {
        let preference = WKPreferences()
        preference.javaScriptEnabled = true
        preference.javaScriptCanOpenWindowsAutomatically = true
        return preference
    }()
    
    
    public var contentController: WKUserContentController
    public var configuration: WKWebViewConfiguration
    public var appendingUserAgent: String?
    
    public init(preference: WKPreferences? = nil, contentController: WKUserContentController, configuration: WKWebViewConfiguration, userAgent: String? = nil) {
        if let preference = preference {
            self.preference = preference
        }
        
        self.contentController = contentController
        self.configuration = configuration
        self.configuration.userContentController = self.contentController
        self.appendingUserAgent = userAgent
        
    }
}

public protocol JSWebBrowserDelegate: WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate {
  
    
    
}

public protocol JSWebBrowserNavigation {
    
    var loadPackage: BehaviorSubject<JSRequestPackage> {get set}
    var navigationDisposeBag: DisposeBag {get set}
}


public class JSWebBrowserController: UIViewController, JSWebBrowserNavigation, Loading {
    
    

    
    
    
    //MARK: UI
    private let container: UIView = {
        let container = UIView()
        container.backgroundColor = .white
        
        return container
    }()
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: browserManager.configuration)
        
        return webView
    }()
    
    private let refreshController = UIRefreshControl()
    private let progressBar = UIProgressView()
  
    
    
    
    //MARK: WKWebView Manager
    public var browserManager: JSWebBrowserManager
    
    //MARK: Transition Manager
//    public var transitionManager: JSWebBrowserTransitionManager?
    public var transitionType: TransitionType = .fixedModal
    
    //MARK: WebView Navigation
    public var loadPackage: BehaviorSubject<JSRequestPackage>
    public var navigationDisposeBag: DisposeBag
    
    //MARK: WKWebView Delegate
    public var delegateUI: WKUIDelegate?
    public var delegateNavigation: WKNavigationDelegate?

    
    private var previousVC: UIViewController?
    
    //TODO: UI
    /**
     1. close button
     2. navigation bar(title, leftitems, rightitems)
     3. close button image
     4. close button title
     5. progress color
     6. refresher color
     7. indicator
     */
    
    //MARK: Navigation Bar
    public var navigationBar: UINavigationBar? = {
        let bar = UINavigationBar()
        bar.isHidden = true
        bar.tintColor = .black
        bar.barTintColor = .black
        bar.backgroundColor = .white
        bar.barStyle = .default
        return bar
    }()
    
    private var _navigationItem: UINavigationItem? = {
        let item = UINavigationItem()
        return item
    }()
    
    public var navigationBarTitle: String? = nil {
        didSet {
            navigationBar?.isHidden = false
            _navigationItem?.title = navigationBarTitle
            navigationBar?.setItems([_navigationItem!], animated: true)
            
        }
    }
    
    
    
    public var navigationBarPrefersLargeTitles: Bool = false {
        didSet {
            navigationBar?.isHidden = false
            if #available(iOS 11.0, *) {
                navigationBar?.prefersLargeTitles = navigationBarPrefersLargeTitles
            }
        }
    }
    
    private lazy var closeButtonItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem()
        buttonItem.customView = closeButton
   
        
        return buttonItem
    }()
    
    private lazy var closeButton: UIButton = {
        let close = UIButton()
        close.setImage(UIImage(named: "Cross"), for: .normal)

        return close
    }()
    
    public var closeButtonTitle: String? = nil {
        didSet{
            closeButton.setTitle(closeButtonTitle, for: .normal)
        }
    }
    
    public var closeButtonBackgroundColor: UIColor? = .clear {
        didSet{
            closeButton.backgroundColor = closeButtonBackgroundColor
        }
    }
    
    public var closeButtonTitleColor: UIColor? = .black {
        didSet{
            closeButton.setTitleColor(closeButtonTitleColor, for: .normal)
        }
    }
    
    public var closeButtonImage: UIImage? = nil {
        didSet{
            closeButton.setImage(closeButtonImage, for: .normal)
        }
    }
    
    
    public var closeButtonEnable: Bool = false {
        didSet{
            guard transitionType == .modal || transitionType == .fixedModal else {return}
            
            navigationBar?.isHidden = !closeButtonEnable
            _navigationItem?.leftBarButtonItem = closeButtonItem
        }
    }
    
    
    
    //MARK: Progress Bar
    public var progressBarHeight: CGFloat = 3.0
    
    public var progressBarTintColor: UIColor? = .systemPink {
        didSet {
            progressBar.tintColor = progressBarTintColor
        }
    }
    
    //MARK: Refresh Controller
    public var refresherTintColor: UIColor? = .systemPink {
        didSet{
            refreshController.tintColor = refresherTintColor
        }
    }
    
    
    //MARK: Loading Indicator
    public var indicatorEnable: Bool = false
    public var indicatorBackgroundEnable: Bool = false
    public var indicatorTintColor: UIColor? = .red
    
    
    
    
    public init(manager: JSWebBrowserManager) {
        
        
        self.browserManager = manager
        self.loadPackage = BehaviorSubject<JSRequestPackage>(value: JSRequestPackage())
        self.navigationDisposeBag = DisposeBag()
        
        super.init(nibName: nil, bundle: nil)
        
    }
  

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setLayout()
        pageInit()
        bind()
    }
    
    
    
    private func pageInit(){
        
        
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
     
        
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView,
                let userAgent = result as? String,
                let appendString = self.browserManager.appendingUserAgent {
                webView.customUserAgent = userAgent + appendString
            }
                
                // * Navigation Anim Library 등록
                self.sj_considerWebView = webView
                
                webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: &process)

            
        }
        

        
        refreshController.tintColor = refresherTintColor
        progressBar.tintColor = progressBarTintColor
        
    }
    
    
    private func bind(){
        
        //MARK: WebView Load
        loadPackage
            .subscribe(onNext: { [weak self] package in
                guard let request = package.loadRequest else {return}
                self?.webView.load(request)
            })
            .disposed(by: navigationDisposeBag)
        
        
        refreshController.rx.controlEvent(.valueChanged)
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.webView.reload()
            })
            .disposed(by: navigationDisposeBag)
        
        
        
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.dismissBrowser()
            })
            .disposed(by: navigationDisposeBag)
    }
    
    
    
    //TODO: layout
    private func setLayout(){
        
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            
        } else {
            // Fallback on earlier versions
            container.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            
        }
        
        
        container.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        
        if let naviBar = navigationBar, !naviBar.isHidden {
            container.addSubview(naviBar)
            naviBar.translatesAutoresizingMaskIntoConstraints = false
            naviBar.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            naviBar.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            naviBar.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
            
            webView.topAnchor.constraint(equalTo: naviBar.bottomAnchor).isActive = true
        }else{
        
            webView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        }
        
        
        webView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        
        
        
        
        container.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: progressBarHeight).isActive = true
        
        
        webView.scrollView.addSubview(refreshController)

        
    }
    

    
    //MARK: progress tracking
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let change = change else { return }
        
        if keyPath == "estimatedProgress" {
            if let progress = (change[NSKeyValueChangeKey.newKey] as AnyObject).floatValue {
               self.progressBar.setProgress(progress, animated: true)
            }
            return
        }
    }
    
    
    
    public func show(fromVC: UIViewController, package: JSRequestPackage? = nil, handler: JSWebBrowserDelegate? = nil, animated: Bool = true, completion:(()->Void)? = nil){
        
        
        if let _handler = handler {
            self.delegateUI = _handler
            self.delegateNavigation = _handler
        }
        
        
          
        if transitionType == .push {
            if let navigation = fromVC.navigationController {
                navigation.pushViewController(self, animated: animated)
            }
        }else if transitionType == .root {
            if let window = UIApplication.shared.keyWindow {
                window.rootViewController = self
                //이전에 띄웠던 viewcontroller
                if let navVC = fromVC.navigationController {
                    previousVC = navVC
                }else if let tabVC = fromVC.tabBarController {
                    previousVC = tabVC
                }else {
                    previousVC = fromVC
                }
            }
        }else if transitionType == .embed {
            
            fromVC.view.addSubview(self.view)
        }else{
            if #available(iOS 13.0, *) {
                self.isModalInPresentation = transitionType == .fixedModal
            }
            fromVC.present(self, animated: animated, completion: completion)
        }
        
        if let package = package {
            self.loadPackage.onNext(package)
        }
    }
    
    
    private func loading(loading: Bool){
        if loading {
            if indicatorEnable {startLoading(color: indicatorTintColor)}
            if indicatorBackgroundEnable {startLoadingWithBackground(color: indicatorTintColor)}
        }else{
            stopLoading()
        }
    }
    
    
    
    private func dismissBrowser(){
        
        
        if transitionType == .embed {
            self.view.removeFromSuperview()
        }else if transitionType == .push {
            self.navigationController?.popViewController(animated: true)
        }else if transitionType == .root {
            if let window = UIApplication.shared.keyWindow {
                window.rootViewController = previousVC
                previousVC = nil
            }
        }else{
            self.dismiss(animated: true, completion: nil)
        }
        
    }
}

extension JSWebBrowserController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    }
    
}


extension JSWebBrowserController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("start ")
        progressBar.isHidden = false
        refreshController.beginRefreshing()
        
        loading(loading: true)
        
        delegateNavigation?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("finish")
        self.progressBar.progress = 0.0
        progressBar.isHidden = true
        refreshController.endRefreshing()
        
        loading(loading: false)
        delegateNavigation?.webView?(webView, didFinish: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail: ", error.localizedDescription)
        self.progressBar.progress = 0.0
        progressBar.isHidden = true
        refreshController.endRefreshing()
        
        loading(loading: false)
        
        delegateNavigation?.webView?(webView, didFail: navigation, withError: error)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation: ", error.localizedDescription)
        self.progressBar.progress = 0.0
        progressBar.isHidden = true
        refreshController.endRefreshing()
        
        loading(loading: false)
        
        delegateNavigation?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        delegateNavigation?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
    
 
  
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        delegateNavigation?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
    }
    
}

extension JSWebBrowserController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        delegateUI?.webView?(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        delegateUI?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        delegateUI?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        delegateUI?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
    }
}




