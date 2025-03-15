//
//  Combine++.swift
//  Xferro
//
//  Created by Taha Bebek on 3/15/25.
//

import Combine
import Foundation

extension Publisher where Self.Failure == Never {
    func sinkOnMainQueue(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
    }
}
