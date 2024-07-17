//
//  ViewController.swift
//  
//  
//  Created by Tomohiro Kumagai on 2024/07/17
//  
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet @ViewLoading var scrollView: UIScrollView
    var currentPage: Int = 0
    var totalPages: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let colors: [UIColor] = [.red, .green, .blue, .yellow]
        
        let width: CGFloat = 320
        let height: CGFloat = 449
        let margin: CGFloat = 20
        
        scrollView.contentSize = .init(width: (width + margin) * CGFloat(colors.count) - margin, height: height)
        scrollView.isScrollEnabled = false
        
        for (offset, color) in colors.enumerated() {
            
            let itemView = UIView(frame: .init(x: (width + margin) * CGFloat(offset), y: 0, width: width, height: height))
            itemView.backgroundColor = color
            
            scrollView.addSubview(itemView)
            print(scrollView.contentSize.width, itemView.frame.maxX)
        }
        
        currentPage = 0
        totalPages = colors.count
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipeGesture.direction = .left
        self.view.addGestureRecognizer(leftSwipeGesture)
        
        // 右スワイプジェスチャーの追加
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipeGesture.direction = .right
        self.view.addGestureRecognizer(rightSwipeGesture)
    }
}

extension ViewController : UIScrollViewDelegate {
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        print("Swipe")
        if gesture.direction == .left {
            // 左スワイプの場合、次のページへ
            if currentPage < totalPages - 1 {
                currentPage += 1
            }
        } else if gesture.direction == .right {
            // 右スワイプの場合、前のページへ
            if currentPage > 0 {
                currentPage -= 1
            }
        }
        
        // 指定されたページ位置にスクロール
        let offsetX = CGFloat(currentPage) * (320 + 20)
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // X方向のスクロール制限
        if scrollView.contentOffset.x < 0 {
            scrollView.contentOffset.x = 0
        } else if scrollView.contentOffset.x > scrollView.contentSize.width - scrollView.frame.width {
            scrollView.contentOffset.x = scrollView.contentSize.width - scrollView.frame.width
        }
        
        // Y方向のスクロール制限
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        } else if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height {
            scrollView.contentOffset.y = scrollView.contentSize.height - scrollView.frame.height
        }
    }
}
