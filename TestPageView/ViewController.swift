//
//  ViewController.swift
//  
//  
//  Created by Tomohiro Kumagai on 2024/07/17
//  
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet @ViewLoading var carouselView: CarouselScrollView

    var items: [Item] {
        
        get {
            carouselView.items
        }

        set (newItems) {
            carouselView.items = newItems
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        items = [
            Item(name: "A", color: .red),
            Item(name: "B", color: .green),
            Item(name: "C", color: .blue)
        ]
    }
}
