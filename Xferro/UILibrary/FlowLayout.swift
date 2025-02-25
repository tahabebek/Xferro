//
//  FlowLayout.swift
//  SwiftUILayouts
//
//  Created by T Brennan on 11/6/2022.
//

import SwiftUI

public struct FlowLayout: Layout {
    var alignment: Alignment
    var spacingX: Double
    var spacingY: Double
    // All items in line offered the height of the largest item
    var fillLineHeight: Bool
    
   public init(alignment: Alignment = .leading, spacingX: Double = 10, spacingY: Double = 10, fillLineHeight: Bool = false) {
        self.alignment = alignment
        self.spacingX = spacingX
        self.spacingY = spacingY
        self.fillLineHeight = fillLineHeight
    }
    
    public struct LayoutCache {
        // If this changes invalidate the cache
        var targetContainerWidth: Double
        var items: [Int: CacheItem] = [:]
        var size: CGSize = .zero
        
        func ifValidForSize(_ width: Double) -> Self? {
            guard targetContainerWidth == width else { return nil }
            return self
        }
    }
    struct Line {
        var y: Double
        var height: Double = 0
        var width: Double = 0
        var maxY: Double { y + height }
        var items: [Int: CacheItem] = [:]
        
        mutating func applyAlignment(_ alignment: Alignment, layoutWidth: Double, fillLineHeight: Bool) {
            if fillLineHeight {
                for (index, _) in items {
                    items[index]?.position.y = y
                    items[index]?.size.height = height
                }
            } else {
                switch alignment.vertical {
                case .center:
                    let centerY = y + (height / 2)
                    for (index, item) in items {
                        items[index]?.position.y = centerY - item.size.height / 2
                    }
                case .bottom:
                    let bottomY = y + height
                    for (index, item) in items {
                        items[index]?.position.y = bottomY - item.size.height
                    }
                default: break
                }
            }
            switch alignment.horizontal {
            case .center:
                let xOffset = (layoutWidth - width) / 2
                for index in items.keys {
                    items[index]?.position.x += xOffset
                }
            case .trailing:
                let xOffset = (layoutWidth - width)
                for index in items.keys {
                    items[index]?.position.x += xOffset
                }
            default: break
            }
        }
    }
    struct CacheItem {
        var position: CGPoint
        var size: CGSize
    }
    
    public func makeCache(subviews: Subviews) -> LayoutCache? {
        return nil
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout LayoutCache?) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let calc = layout(subviews: subviews, containerWidth: containerWidth)
        cache = calc
        return calc.size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout LayoutCache?) {
        let calc = cache?.ifValidForSize(proposal.replacingUnspecifiedDimensions().width) ?? layout(subviews: subviews, containerWidth: bounds.width)
        for (index, subview) in zip(subviews.indices, subviews) {
            if let value = calc.items[index] {
                subview.place(at: bounds.origin + value.position,
                              proposal: .init(value.size))
            }
        }
    }
    
    func layout(subviews: Subviews, containerWidth: CGFloat) -> LayoutCache {
        var result: LayoutCache = .init(targetContainerWidth: containerWidth)
        var currentPosition: CGPoint = .zero
        var currentLineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        var lines: [Line] = [Line(y: 0)]
        for (index, subview) in zip(subviews.indices, subviews) {
            let size = subview.sizeThatFits(.init(width: containerWidth, height: nil))
            if currentPosition.x + spacingX + size.width > containerWidth {
                currentLineHeight = 0
                currentPosition.x = 0
                currentPosition.y += lines[lines.endIndex - 1].height + spacingY
                lines.append(Line(y: currentPosition.y))
            } else if lines.last?.items.isEmpty != true {
                currentPosition.x += spacingX
            }
            lines[lines.endIndex - 1].items[index] = .init(position: currentPosition, size: size)
            currentPosition.x += size.width
            maxX = min(containerWidth, max(maxX, currentPosition.x))
            currentLineHeight = max(currentLineHeight, size.height)
            lines[lines.endIndex - 1].width = currentPosition.x
            lines[lines.endIndex - 1].height = currentLineHeight
        }
        for index in lines.indices {
            lines[index].applyAlignment(alignment, layoutWidth: maxX, fillLineHeight: fillLineHeight)
        }
        result.size = CGSize(width: maxX, height: lines.last?.maxY ?? 0)
        result.items = lines.reduce(into: [Int: CacheItem](), { partialResult, line in
            partialResult.merge(line.items, uniquingKeysWith: {$1})
        })
        return result
    }
    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .horizontal
        return properties
    }
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

struct FlowTestView: View {
    @State var testContent = ["Hello World", "Custom layouts in SwiftUI wow!", "This is a very long string that takes up multiple lines in portrait mode", "String with\nline break", "Short text"]
    @State var horizontalAlignment: HorizontalAlignment = .leading
    @State var verticalAlignment: VerticalAlignment = .top

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                    ForEach(testContent, id: \.self) { i in
                        Text(i)
                            .padding(6)
                            .frame(maxHeight: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
//                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }.padding(10)
                Divider()
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
            .animation(.default, value: testContent)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                picker.pickerStyle(.menu)
                Spacer()
                Button("Shuffle") {
                    testContent.shuffle()
                }
            }.padding().background(.thinMaterial)
        }
        .navigationTitle("Flow Layout")
    }
    var picker: some View {
        Picker("Alignment", selection: $horizontalAlignment) {
            Text("Leading").tag(HorizontalAlignment.leading)
            Text("Center").tag(HorizontalAlignment.center)
            Text("Trailing").tag(HorizontalAlignment.trailing)
        }.pickerStyle(.segmented)
    }
}

extension HorizontalAlignment: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: self))
    }
}


struct FlowTestView_Previews: PreviewProvider {
    static var previews: some View {
        FlowTestView()
    }
}
