//
//  TreeView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

struct TreeView: View {
    struct TreeBounds: Equatable {
        let minX: CGFloat
        let maxX: CGFloat
        let minY: CGFloat
        let maxY: CGFloat
        
        init(minX: CGFloat = 0, maxX: CGFloat = 0, minY: CGFloat = 0, maxY: CGFloat = 0) {
            self.minX = minX
            self.maxX = maxX
            self.minY = minY
            self.maxY = maxY
        }
    }
    
    let tree: CommitTree
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let onManualCommitTapped: (AnyCommit) -> Void
    let onAutoCommitTapped: (AnyCommit) -> Void
    private let treeBounds: TreeBounds
    private let heightOffset: CGFloat

    @Environment(\.windowInfo) var windowInfo

    init(
        tree: CommitTree,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat,
        onManualCommitTapped: @escaping (AnyCommit) -> Void,
        onAutoCommitTapped: @escaping (AnyCommit) -> Void
    ) {
        self.tree = tree
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.onManualCommitTapped = onManualCommitTapped
        self.onAutoCommitTapped = onAutoCommitTapped
        tree.positionTree()

        self.treeBounds = Self.calculateTreeBounds(
            tree: tree,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        self.heightOffset = abs(treeBounds.minY) + abs(treeBounds.maxY)
    }
    
    private static func calculateTreeBounds(
        tree: CommitTree,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> TreeBounds {
        let positions = tree.nodes.map { $0.positionAsFloat(scaleX: horizontalSpacing, scaleY: verticalSpacing) }
        let maxX = positions.map { $0.0 }.max() ?? 0
        let maxY = positions.map { $0.1 }.max() ?? 0
        let minX = positions.map { $0.0 }.min() ?? 0
        let minY = positions.map { $0.1 }.min() ?? 0
        return TreeBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    private func adjustedPosition(_ size: (CGFloat, CGFloat)) -> (CGFloat, CGFloat) {
        (size.0 + Dimensions.commitsViewWidth / 2.0, size.1 + windowInfo.height / 2.0)
    }

    var body: some View {
        ZStack {
            TreeLinesView(
                nodes: tree.nodes,
                heightOffset: heightOffset,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                adjustedPosition: adjustedPosition
            )
            .drawingGroup(opaque: true)

            TreeNodesView(
                nodes: tree.nodes,
                heightOffset: heightOffset,
                horizontalSpacing: horizontalSpacing,
                verticalSpacing: verticalSpacing,
                onManualCommitTapped: onManualCommitTapped,
                onAutoCommitTapped: onAutoCommitTapped,
                adjustedPosition: adjustedPosition
            )
        }
    }
}

struct TreeLinesView: View {
    let nodes: [Node]
    let heightOffset: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let adjustedPosition: ((CGFloat, CGFloat)) -> (CGFloat, CGFloat)

    var body: some View {
        ForEach(nodes, id: \.nodeData.id) { node in
            let parentPos = adjustedPosition(node.positionAsFloat(scaleX: horizontalSpacing, scaleY: verticalSpacing))

            ForEach(node.children, id: \.nodeData.id) { child in
                let childPos = adjustedPosition(child.positionAsFloat(scaleX: horizontalSpacing, scaleY: verticalSpacing))
                let from = CGPoint(x: parentPos.0, y: parentPos.1 + heightOffset)
                let to = CGPoint(x: childPos.0, y: childPos.1 + heightOffset)
                TreeLineView(from: from, to: to)
            }
        }
    }
}

struct TreeNodesView: View {
    let nodes: [Node]
    let heightOffset: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let onManualCommitTapped: (AnyCommit) -> Void
    let onAutoCommitTapped: (AnyCommit) -> Void
    let adjustedPosition: ((CGFloat, CGFloat)) -> (CGFloat, CGFloat)

    var body: some View {
        ForEach(nodes, id: \.nodeData.id) { node in
            let position = adjustedPosition(node.positionAsFloat(scaleX: horizontalSpacing, scaleY: verticalSpacing))
            ZStack {
                if let nodeData = node.nodeData as? AutoCommitNodeData {
                    AutoCommitNodeView(
                        nodeData: nodeData,
                        onTap: onAutoCommitTapped
                    )
                } else if let nodeData = node.nodeData as? ManualCommitNodeData {
                    ManualCommitNodeView(
                        nodeData: nodeData
                    )
                    .onTapGesture {
                        onManualCommitTapped(nodeData.commit)
                    }
                } else {
                    fatalError()
                }
            }
            .position(x: position.0, y: position.1 + heightOffset)
            .preference(key: NodePositionsKey.self, value: [node.nodeData.id: CGPoint(x: position.0, y: position.1 + heightOffset)])
        }
    }
}

struct NodePositionsKey: PreferenceKey {
   static var defaultValue: [String: CGPoint] = [:]
   static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
       value.merge(nextValue()) { current, _ in current }
   }
}

struct TreeLineView: View, Equatable {
    let from: CGPoint
    let to: CGPoint
    let stroke: Color
    let lineWidth: CGFloat
    let opacity: Double

    init(
        from: CGPoint,
        to: CGPoint,
        stroke: Color = .gray,
        lineWidth: CGFloat = 1.0,
        opacity: Double = 0.3
    ) {
        self.from = from
        self.to = to
        self.stroke = stroke
        self.lineWidth = lineWidth
        self.opacity = opacity
    }

    static func == (lhs: TreeLineView, rhs: TreeLineView) -> Bool {
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.stroke == rhs.stroke &&
        lhs.lineWidth == rhs.lineWidth &&
        lhs.opacity == rhs.opacity
    }

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(stroke, lineWidth: lineWidth)
        .opacity(opacity)
    }
}
