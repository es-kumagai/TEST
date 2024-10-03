//
//  AnimationDirection.swift
//  TestPageView
//  
//  Created by Tomohiro Kumagai on 2024/10/04
//  
//

import UIKit

extension CarouselScrollView {
    
    /// コンテンツのスワイプ方向です。
    enum AnimationDirection {
        
        case previous
        case next
    }
}

extension CarouselScrollView.AnimationDirection {
    
    /// 画面上の各方向へのスワイプから、コンテンツのスワイプ方向へ変換します。
    init?(_ direction: UISwipeGestureRecognizer.Direction) {

        switch direction {

        case .left:
            self = .next
            
        case .right:
            self = .previous
            
        default:
            return nil
        }
    }
}
