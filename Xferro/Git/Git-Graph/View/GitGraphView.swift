//
//  GitGraphView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import SwiftUI

struct GitGraphNode: Identifiable {
    let id: String
    let message: String
    let column: Int
    let row: Int
    let commitHash: String
    let branchLabels: [String]
    let connections: [GitGraphConnection]
}

struct GitGraphConnection {
    let fromColumn: Int
    let toColumn: Int
    let fromRow: Int
    let toRow: Int
    let isMerge: Bool
}

struct GitGraphView: View {
    @Environment(GGViewModel.self) var viewModel
    @Environment(\.graphWindowInfo) var graphWindowInfo

    var body: some View {
        GitGraphNodesView(nodes: viewModel.nodes)
    }
}

struct GitGraphNodesView: View {
    let nodes: [GitGraphNode]
    @State private var selectedNode: GitGraphNode?

    // Refined measurements to match screenshot exactly
    private let columnWidth: CGFloat = 16  // Slightly narrower columns
    private let rowHeight: CGFloat = 32    // Adjusted row height
    private let dotRadius: CGFloat = 3     // Smaller dots

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                ForEach(nodes) { node in
                    GitGraphRow(
                        node: node,
                        columnWidth: columnWidth,
                        rowHeight: rowHeight,
                        dotRadius: dotRadius,
                        isSelected: selectedNode?.id == node.id
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct GraphConnectionsView: View {
    let node: GitGraphNode
    let columnWidth: CGFloat
    let rowHeight: CGFloat
    let dotRadius: CGFloat
    let isSelected: Bool

    var body: some View {
        Canvas { context, size in
            // First draw all vertical column lines
            let allColumns = Set([node.column] + node.connections.flatMap { [$0.fromColumn, $0.toColumn] })

            for column in allColumns {
                let x = CGFloat(column) * columnWidth + (columnWidth / 2)
                let verticalLine = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(
                    verticalLine,
                    with: .color(.secondary.opacity(0.3)),
                    lineWidth: 1.0
                )
            }

            // Draw branch/merge connections
            for connection in node.connections {
                if connection.fromColumn != connection.toColumn {
                    let fromX = CGFloat(connection.fromColumn) * columnWidth + (columnWidth / 2)
                    let toX = CGFloat(connection.toColumn) * columnWidth + (columnWidth / 2)
                    let centerY = size.height / 2

                    let branchLine = Path { path in
                        if connection.isMerge {
                            // For merge commits, draw from current node's Y center to top
                            path.move(to: CGPoint(x: fromX, y: centerY))
                            path.addLine(to: CGPoint(x: fromX, y: centerY))
                            path.addLine(to: CGPoint(x: toX, y: 0))
                        } else {
                            // For branch-outs, draw from current node's Y center to bottom
                            path.move(to: CGPoint(x: fromX, y: centerY))
                            path.addLine(to: CGPoint(x: fromX, y: centerY))
                            path.addLine(to: CGPoint(x: toX, y: size.height))
                        }
                    }
                    context.stroke(
                        branchLine,
                        with: .color(.secondary.opacity(0.5)),
                        lineWidth: 1.0
                    )

                    // Draw arrow for non-merge connections
                    if !connection.isMerge {
                        let arrowSize: CGFloat = 4
                        let arrowPath = Path { path in
                            let angle = fromX < toX ? -CGFloat.pi/6 : CGFloat.pi + CGFloat.pi/6
                            let endPoint = CGPoint(x: toX, y: size.height)
                            let point1 = CGPoint(
                                x: endPoint.x + arrowSize * cos(angle),
                                y: endPoint.y + arrowSize * sin(angle)
                            )
                            let point2 = CGPoint(
                                x: endPoint.x + arrowSize * cos(angle + CGFloat.pi/3),
                                y: endPoint.y + arrowSize * sin(angle + CGFloat.pi/3)
                            )

                            path.move(to: endPoint)
                            path.addLine(to: point1)
                            path.move(to: endPoint)
                            path.addLine(to: point2)
                        }
                        context.stroke(
                            arrowPath,
                            with: .color(.secondary.opacity(0.5)),
                            lineWidth: 1.0
                        )
                    }
                }
            }

            // Draw commit dot/circle
            let centerX = CGFloat(node.column) * columnWidth + (columnWidth / 2)
            let centerY = size.height / 2

            if node.connections.count > 1 {
                // Empty circle for merge commits
                let circle = Path(ellipseIn: CGRect(
                    x: centerX - dotRadius,
                    y: centerY - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                context.stroke(
                    circle,
                    with: .color(.secondary),
                    lineWidth: 1.0
                )
            } else {
                // Filled circle for regular commits
                let circle = Path(ellipseIn: CGRect(
                    x: centerX - dotRadius,
                    y: centerY - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                context.fill(
                    circle,
                    with: .color(.secondary)
                )
            }
        }
    }
}

struct GitGraphRow: View {
    let node: GitGraphNode
    let columnWidth: CGFloat
    let rowHeight: CGFloat
    let dotRadius: CGFloat
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Graph visualization
            GraphConnectionsView(
                node: node,
                columnWidth: columnWidth,
                rowHeight: rowHeight,
                dotRadius: dotRadius,
                isSelected: isSelected
            )
            .frame(width: columnWidth * 6)

            // Commit info
            Text(node.commitHash)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

            if !node.branchLabels.isEmpty {
                ForEach(node.branchLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Text(node.message)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .frame(height: rowHeight)
    }
}

struct CommitInfoView: View {
    let node: GitGraphNode

    var body: some View {
        HStack(spacing: 8) {
            // Commit hash with monospaced font
            Text(node.commitHash)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

            // Branch labels with macOS-style appearance
            if !node.branchLabels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(node.branchLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            // Commit message
            Text(node.message)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.leading, 8)
    }
}

#Preview(traits: .modifier(GGPreviewViewModel())) {
    GitGraphView()
        .environment(\.graphWindowInfo, .init(width: Dimensions.commitsViewWidth, height: Dimensions.appHeight))
        .frame(width: Dimensions.commitsViewWidth * 2, height: Dimensions.appHeight)
}
