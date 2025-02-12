//
//  GitStrArray.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

extension git_strarray {
    func filter(_ isIncluded: (String) -> Bool) -> [String] {
        return map { $0 }.filter(isIncluded)
    }

    func map<T>(_ transform: (String) -> T) -> [T] {
        return (0..<self.count).map {
            let string = String(validatingCString: self.strings[$0]!)!
            return transform(string)
        }
    }
}
