//
//  Cell.swift
//  TestPageView
//  
//  Created by Tomohiro Kumagai on 2024/10/04
//  
//

import UIKit

extension CarouselScrollView {
    
    final class Cell: UILabel {
        
        var item: Item? {
            
            didSet {
                text = item?.name
                backgroundColor = item?.color
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            customizeViewStates()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            customizeViewStates()
        }
    }
}

private extension CarouselScrollView.Cell {
    
    func customizeViewStates() {
        autoresizesSubviews = false
        textAlignment = .center
    }
}
