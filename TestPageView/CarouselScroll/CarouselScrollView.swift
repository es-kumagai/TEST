//
//  CarouselScrollView.swift
//  TestPageView
//  
//  Created by Tomohiro Kumagai on 2024/10/04
//  
//

import UIKit

final class CarouselScrollView: UIScrollView {
    
    /// セルの間隔です。Storyboard からも設定できるように NSNumber で保持しています。
    @IBOutlet var cellMargin: NSNumber?
    
    private var surfaceSnapshotViewForAnimating = UIImageView()
    private var behindSnapshotViewForAnimating = UIImageView()
    
    /// 無限スクロールで使うアイテムです。
    /// 初期状態として、先頭のアイテムが中央に表示されます。
    var items: [Item] = [] {
        
        didSet {
            focusedItemIndex = 0
            setNeedsDisplay()
        }
    }
    
    /// 中央に表示するアイテムのインデックスです。
    var focusedItemIndex = 0 {

        willSet (newIndex) {
            assert(items.indices.contains(newIndex), "Index out of bounds")
        }

        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 内部で使用するセルです。
    /// ５つのセルを繰り返し利用します。
    private let cells = [
        Cell(frame: .zero),
        Cell(frame: .zero),
        Cell(frame: .zero),
        Cell(frame: .zero),
        Cell(frame: .zero),
    ]
    
    /// コードからの初期化で使用するイニシャライザーです。
    /// - Parameters:
    ///   - frame: ビューのフレームサイズです。
    ///   - cellMargin: セルの間隔です。
    init(frame: CGRect, cellMargin: CGFloat) {
        
        self.cellMargin = cellMargin as NSNumber

        super.init(frame: frame)
        customizeViewStates()
    }
    
    /// Storyboard からの初期化で使用するイニシャライザーです。
    /// - Parameter coder: デコードで使用するコーダーです。
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customizeViewStates()
    }
    
    /// スクロールビューの内部領域のサイズです。
    override var contentSize: CGSize {
        
        get {
            super.contentSize
        }
        
        set {
            super.contentSize = newValue
            surfaceSnapshotViewForAnimating.bounds.size = newValue
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 初期位置とスクロールの幅を考慮して、コンテンツを少しはみ出すように配置します。
        contentSize = CGSize(width: cellOuterFrameWidth * CGFloat(cells.count), height: cellOuterFrameHeight)
        contentOffset.x = cellOuterFrameWidth * CGFloat(centerCellIndex) - oneSideCellMargin * 2
        
        // スクロールアニメーション中に使用するビューを初期化します。
        behindSnapshotViewForAnimating.frame = bounds
        surfaceSnapshotViewForAnimating.frame.origin = .zero
        
        addSubview(behindSnapshotViewForAnimating)
        addSubview(surfaceSnapshotViewForAnimating)
        
        // スクロール時に最新コンテンツを隠すための背後の描画を保存します。
        // NOTE: スクロール直前まで背後の描画が変化する場合は、スクロール直前にスナップショットを取る必要があります。
        behindSnapshotViewForAnimating.image = behindContentSnapshot()

        // 内部配置用のセルを所定の場所に配置します。
        for cellIndex in cells.indices {
            
            let cell = cells[cellIndex]
            let offsetX = cellOuterFrameWidth * CGFloat(cellIndex) + bothSidesCellMargin
            cell.frame = CGRect(x: offsetX, y: 0, width: cellInnerContentWidth, height: cellInnerContentHeight)
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        applyItemsToCells()
    }
}

extension CarouselScrollView : UIScrollViewDelegate {
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        
        guard let direction = AnimationDirection(gesture.direction) else {
            return
        }
        
        // 現在の描画状態を保存し、それをスクロールしている間に裏で次の状態に更新します。
        
        surfaceSnapshotViewForAnimating.frame.origin.x = 0
        surfaceSnapshotViewForAnimating.image = contentSnapshot()

        let animationDistance: CGFloat
        
        var modifiedStates: [any RestorableStateProtocol] = [
            
            restorableAssign(false, to: \.isUserInteractionEnabled),
            surfaceSnapshotViewForAnimating.restorableAssign(false, to: \.isHidden),
            behindSnapshotViewForAnimating.restorableAssign(false, to: \.isHidden)
        ]
        
        switch direction {
            
        case .next:
            moveToNextItem()
            animationDistance = -cellOuterFrameWidth
            
        case .previous:
            moveToPreviousItem()
            animationDistance = +cellOuterFrameWidth
        }
        
        UIView.animate(withDuration: 0.3) { [self] in
            surfaceSnapshotViewForAnimating.frame.origin.x += animationDistance
        } completion: { finished in
            modifiedStates.restoreAll()
        }
    }
}

private extension CarouselScrollView {
    
    func customizeViewStates() {
        
        isPagingEnabled = false
        isScrollEnabled = false
        
        behindSnapshotViewForAnimating.isHidden = true
        surfaceSnapshotViewForAnimating.isHidden = true
        
        cells.forEach(addSubview)
                
        updateContentOffset()
        addSwipeGestureRecognizers()
    }
    
    func addSwipeGestureRecognizers() {
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipeGesture.direction = .left
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipeGesture.direction = .right

        addGestureRecognizer(leftSwipeGesture)
        addGestureRecognizer(rightSwipeGesture)
    }
    
    /// 次のアイテムにフォーカスを移動します。末尾を超えたときは先頭に戻ります。
    func moveToNextItem() {
        let nextIndex = focusedItemIndex + 1
        focusedItemIndex = (nextIndex > items.indices.last! ? items.indices.first! : nextIndex)
    }
    
    /// 前のアイテムにフォーカスを移動します。先頭を超えたときは末尾に戻ります。
    func moveToPreviousItem() {
        let previousIndex = focusedItemIndex - 1
        focusedItemIndex = (previousIndex < items.indices.first! ? items.indices.last! : previousIndex)
    }
    
    /// 内部配置用セルの、中央表示用に使うセルのインデックスです。
    var centerCellIndex: Int {
        cells.count / 2
    }
    
    /// 表示コンテンツの片側余白です。
    var oneSideCellMargin: CGFloat {
        cellMargin?.doubleValue ?? 0
    }
    
    /// 表示コンテンツの両側余白です。
    var bothSidesCellMargin: CGFloat {
        oneSideCellMargin * 2
    }
    
    /// 内部表示用セルの幅です。はみ出し部分も加味しています。
    var cellOuterFrameWidth: CGFloat {
        bounds.width - bothSidesCellMargin * 3
    }
    
    /// 内部表示用セルの高さです。
    var cellOuterFrameHeight: CGFloat {
        bounds.height
    }
    
    /// 内部表示用セルのコンテンツ幅です。
    var cellInnerContentWidth: CGFloat {
        cellOuterFrameWidth - bothSidesCellMargin
    }

    /// 内部表示用セルのコンテンツ高さです。
    var cellInnerContentHeight: CGFloat {
        cellOuterFrameHeight
    }
    
    /// 内部配置用セルのインデックス範囲を取得します。
    private var cellIndices: Range<Int> {
        cells.indices
    }
    
    /// 内部配置用セルに対応する、表示アイテムのインデックスを配列で取得します。
    private var itemIndicesForCells: [Int] {
        cellIndices.map { cellIndex in
            itemIndex(forCellIndex: cellIndex)
        }
    }
    
    /// 指定した内部表示用セルの配置位置に対応する、表示アイテムのインデックスを取得します。
    /// - Parameter cellIndex: 内部表示用セルのインデックスです。
    /// - Returns: 対応する表示アイテムのインデックスです。
    func itemIndex(forCellIndex cellIndex: Int) -> Int {

        let itemIndex =  cellIndex - centerCellIndex + focusedItemIndex
        return (itemIndex >= 0 ? itemIndex : items.count + itemIndex) % items.count
    }
    
    /// 現在フォーカスされているアイテムに従って、内部配置用の各セルに適切なアイテムを反映します。
    func applyItemsToCells() {
        
        for (cellIndex, itemIndex) in zip(cellIndices, itemIndicesForCells) {
            cells[cellIndex].item = items[itemIndex]
        }
    }
    
    /// コンテンツの表示位置を更新します。
    /// アニメーションは行わずに瞬時に切り替えます。スクロールアニメーションは、各種スナップショット画像を使って実現します。
    func updateContentOffset() {
        
        contentOffset = CGPoint(x: cellOuterFrameWidth * CGFloat(centerCellIndex) - oneSideCellMargin, y: 0)
    }

    /// 現在表示されているコンテンツのスナップショットを取得します。
    /// - Returns: 描画されているコンテンツのスナップショット画像です。
    func contentSnapshot() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(contentSize, false, 0)
        
        @RestorableState(for: self, \.clipsToBounds)
        var clipsToBounds: Bool = false
        
        defer {
            $clipsToBounds.restore()
            UIGraphicsEndImageContext()
        }
        
        layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    /// コンテンツの背後にある描画のスナップショットを取得します。
    /// - Returns: 背後の描画スナップショット画像です。
    func behindContentSnapshot() -> UIImage {
        
        func snapshot(of targetView: UIView) -> UIImage {
            
            // すべての描画を取得するために、大元のビューまで辿ってから画像化します。
            if let targetSuperview = targetView.superview {
                return snapshot(of: targetSuperview)
            }
            
            // 大元のビューから見た、コンテンツの背後を画像化します。
            let targetRect = convert(bounds, to: targetView)
            
            UIGraphicsBeginImageContextWithOptions(targetRect.size, false, 0)
            
            @RestorableState(for: self, \.isHidden)
            var isHidden = true
            
            defer {
                $isHidden.restore()
                UIGraphicsEndImageContext()
            }
            
            let context = UIGraphicsGetCurrentContext()!
            
            context.translateBy(x: -targetRect.origin.x, y: -targetRect.origin.y)
            targetView.layer.render(in: context)
            
            return UIGraphicsGetImageFromCurrentImageContext()!
        }
        
        return snapshot(of: self)
    }
}
