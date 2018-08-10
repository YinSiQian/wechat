//
//  FriendMomentInputView.swift
//  WeChat
//
//  Created by ABJ on 2018/8/10.
//  Copyright © 2018年 ysq. All rights reserved.
//

import UIKit

class FriendMomentInputView: UIView {
    
    typealias complection = (_ text: String) -> Void
    
    var complectionHandler: complection!

    var placeholder: String?
    
    var currentTextViewHeight: CGFloat = 33
    
    var draft: String? {
        didSet {
            textView.text = draft
        }
    }
    
    private var placeholderLable: UILabel!
    
    private var textView: UITextView!
    
    var originY: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = #colorLiteral(red: 0.9208731393, green: 0.9492385787, blue: 0.8798525198, alpha: 1)
        originY = self.minY
        setupSubviews()
        addObserver()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(frame: CGRect, placeholder: String) {
        self.init(frame: frame)
        self.placeholder = placeholder
    }
    
    convenience init(frame: CGRect, placeholder: String, complectionHandler: @escaping complection) {
        self.init(frame: frame, placeholder: placeholder)
        self.complectionHandler = complectionHandler
    }
    
    private func setupSubviews() {
        
        textView = UITextView(frame: CGRect(x: 20, y: 5, width: self.width - 40, height: 30))
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textColor = UIColor.black
        textView.returnKeyType = .send
        textView.layer.cornerRadius = 4
        textView.layer.masksToBounds = true
        textView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        textView.layer.borderWidth = 0.5
        textView.delegate = self
        self.addSubview(textView)
        
        placeholderLable = UILabel(frame: CGRect(x: 3, y: 0, width: self.width, height: 30))
        placeholderLable.textColor = UIColor.lightText
        placeholderLable.font = UIFont.systemFont(ofSize: 14)
        placeholderLable.text = placeholder
        textView.addSubview(placeholderLable)
        
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(FriendMomentInputView.keyboardWillShow(noti:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FriendMomentInputView.keyboardWillHide(noti:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FriendMomentInputView.keyboardFrameChanged(noti:)), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FriendMomentInputView.textViewDidChanged(noti:)), name: NSNotification.Name.UITextViewTextDidChange, object: nil)
    }
    
    @objc private func textViewDidChanged(noti: Notification) {
        let maxHeight: CGFloat = 120
        let object = noti.object as! UITextView
        let rect = object.frame
        let constraintSize = CGSize(width: rect.size.width, height: CGFloat(MAXFLOAT))
        var size = object.sizeThatFits(constraintSize)
        let detla = size.height - currentTextViewHeight

        if size.height >= maxHeight {
            size.height = maxHeight
            object.isScrollEnabled = true
        } else {
            object.isScrollEnabled = false
        }
        if size.height < maxHeight {
            UIView.animate(withDuration: 0.2) {
                self.frame = CGRect(x: 0, y: self.originY - detla , width: self.width, height: size.height + 10)
            }
        }
        UIView.animate(withDuration: 0.2) {
            object.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: size.height)
        }
        
    }
    
    @objc private func keyboardWillShow(noti: Notification) {
        let rect = noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        UIView.animate(withDuration: 0.25) {
            self.minY = rect.origin.y - self.height
            self.originY = rect.origin.y - self.height
        }
        
    }
    
    @objc private func keyboardWillHide(noti: NSNotification) {
        let rect = noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        UIView.animate(withDuration: 0.25) {
            self.minY = rect.origin.y - self.height
            self.originY = rect.origin.y - self.height
        }
        currentTextViewHeight = self.textView.height
    }
    
    @objc private func keyboardFrameChanged(noti: NSNotification) {
        let rect = noti.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        UIView.animate(withDuration: 0.25) {
            self.minY = rect.origin.y - self.height
            self.originY = rect.origin.y - self.height
        }
    }
    
}

extension FriendMomentInputView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLable.isHidden = textView.text.count > 0
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            complectionHandler?(textView.text)
        }
        return true
    }
}