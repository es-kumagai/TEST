//
//  RestorableState.swift
//  TestPageView
//  
//  Created by Tomohiro Kumagai on 2024/10/04
//  
//

import UIKit

extension CarouselScrollView {
    
    /// 復元可能なプロパティー管理のできる対象です。
    protocol RestorableStateTaget: AnyObject {}
    
    /// 復元可能なプロパティー情報です。
    protocol RestorableStateProtocol {
        mutating func restore()
    }
    
    /// 復元可能なプロパティーを保持するための変数に使用するプロパティーラッパーです。
    ///
    /// IMPORTANT: ついつい作ってしまいましたが、本来、このような面倒な機能を作らなくても、プロパティーの値を愚直に保存して、終了時に復元れば十分です。
    ///
    /// ```
    /// let keepingIsHidden = contentView.isHidden
    /// contentView.isHidden = false
    ///
    /// defer {
    ///     contentView.isHidden = keepingIsHidden
    /// }
    /// ```
    ///
    ///　このような処理を、このプロパティーラッパーを使えば次のように書けます。
    ///
    /// ```
    /// @RestorableState(for: contentView, \.isHidden)
    /// var isContentViewHidden = true
    ///
    /// defer {
    ///     $isContentViewHidden.restore()
    /// }
    /// ```
    @propertyWrapper
    final class RestorableState<Target: RestorableStateTaget, StateValue>: RestorableStateProtocol {
        
        private(set) unowned var target: Target
        let state: WritableKeyPath<Target, StateValue>
        let keepingValue: StateValue
        
        init(wrappedValue: StateValue, for target: Target, _ state: WritableKeyPath<Target, StateValue>) {
            
            self.target = target
            self.state = state
            self.keepingValue = target[keyPath: state]
            self.wrappedValue = wrappedValue
        }
        
        convenience init(for target: Target, _ state: WritableKeyPath<Target, StateValue>, currentlyAssignedTo value: StateValue) {
            self.init(wrappedValue: value, for: target, state)
        }
        
        var wrappedValue: StateValue {
            
            get {
                target[keyPath: state]
            }
            
            set {
                target[keyPath: state] = newValue
            }
        }
        
        var projectedValue: RestorableState {
            self
        }
        
        func restore() {
            target[keyPath: state] = keepingValue
        }
    }
}

/// UIView を復元可能なプロパティーを扱えるようにします。
extension UIView: CarouselScrollView.RestorableStateTaget {}

extension CarouselScrollView.RestorableStateTaget {
    
    /// 復元可能な情報を保持しながら、プロパティーに値を書き込みます。
    /// プロパティー宣言ができない場面で @RestorableState プロパティーラッパーの代わりに使用します。
    /// - Parameters:
    ///   - value: 新たに設定する値です。
    ///   - state: 設定対象のプロパティーです。
    /// - Returns: 復元可能な情報を返します。復元の際は .restore() を呼び出すようにします。
    func restorableAssign<Value>(_ value: Value, to state: WritableKeyPath<Self, Value>) -> CarouselScrollView.RestorableState<Self, Value> {
        .init(for: self, state, currentlyAssignedTo: value)
    }
}

extension MutableCollection<any CarouselScrollView.RestorableStateProtocol> {
    
    /// 内包している復元可能な対象すべてを復元します。
    mutating func restoreAll() {
        
        for index in indices {
            self[index].restore()
        }
    }
}
