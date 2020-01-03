//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/3/20.
//

import Foundation

public class AtomicMutablePointer<Wrapped> {
    
    public var syncPointee: Wrapped {
        get {
            var v: Wrapped!
            queue.sync {
                v = value
            }
            return v
        }
        set {
            queue.sync {
                self.value = newValue
            }
        }
    }
    
    private var value: Wrapped
    
    private let queue = DispatchQueue(label: String(describing: Wrapped.self) + "_atomic", attributes: [])
    
    init(_ value: Wrapped) {
        self.value = value
    }
    func get (_ completion: @escaping (Wrapped) -> Void ) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            completion(self.value)
        }
    }
    func set (value: Wrapped, _ completion: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.value = value
            completion()
        }
    }
}
