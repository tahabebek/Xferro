//
//  XMLElement++.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

extension XMLElement {
    /// Returns the element's attributes as a dictionary.
    func attributesDict() -> [String: String] {
        guard let attributes = attributes
        else { return [:] }

        var result = [String: String]()

        for attribute in attributes {
            guard let name = attribute.name,
                  let value = attribute.stringValue
            else { continue }

            result[name] = value
        }
        return result
    }

    /// Returns a list of attribute values of all children, matching the given
    /// attribute name.
    func childrenAttributes(_ name: String) -> [String] {
        children?.compactMap {
            ($0 as? XMLElement)?.attribute(forName: name)?.stringValue
        } ?? []
    }
}
