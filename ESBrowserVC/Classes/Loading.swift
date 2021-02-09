//
//  Loading.swift
//  MesseEsang
//
//  Created by esmnc1 on 2019/12/30.
//  Copyright © 2019 MesseEsang. All rights reserved.
//

import UIKit



public protocol Loading: UIViewController {
    
    
    func startLoading(color: UIColor?)
    func startLoadingWithBackground(color: UIColor?)
    func startLoadingWithBackground(anchorView: UIView, color: UIColor?)
    func stopLoading()
    
}

extension Loading {
    
  
    private var tag: Int {
        return 12345
    }
    
    public func startLoading(color: UIColor? = .lightGray){
        
      
        
        let indicator = UIActivityIndicatorView(frame: .zero)
                                                
        indicator.color = color
        
        indicator.tag = tag
    
        
        if let oldThing = self.view.viewWithTag(tag) {
            oldThing.removeFromSuperview()
        }
        
        
        self.view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 70).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        
        
        indicator.startAnimating()
        
    }
    
    public func startLoadingWithBackground(color: UIColor? = .lightGray){
        startLoadingWithBackground(anchorView: self.view, color: color)
    }
    
    public func startLoadingWithBackground(anchorView: UIView, color: UIColor? = .lightGray){
        
        
        let background = UIView(frame: .zero)
        background.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        background.tag = tag
        
        
         
        let indicator = UIActivityIndicatorView(frame: .zero)
        
        indicator.color = color
        indicator.tag = tag
        
        
        
        
        if let oldThing = anchorView.viewWithTag(tag) {
            oldThing.removeFromSuperview()
        }
        
        
        anchorView.addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.topAnchor.constraint(equalTo: anchorView.topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor).isActive = true
        background.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor).isActive = true
        background.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor).isActive = true
        
        
        
        background.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: background.centerYAnchor).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 70).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        
        
        indicator.startAnimating()
    }
    
    
    public func stopLoading(){
        
        if let indicator = self.view.viewWithTag(tag) {
            indicator.removeFromSuperview()
        }
        
        if let background = self.view.viewWithTag(tag) {
            background.removeFromSuperview()
        }
    }
    
}
