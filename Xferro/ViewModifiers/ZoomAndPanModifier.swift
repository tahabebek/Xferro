//
//  ZoomAndPanViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

protocol ZoomAndPanViewModel where Self: Observable  {
    var scrollWheelMonitor: Any? { get }
    func setScrollWheelMonitor(_ scrollWheelMonitor: Any?)
}

struct ZoomAndPanModifier: ViewModifier {
    @State var viewModel: ZoomAndPanViewModel
    @Binding var currentOffset: CGPoint
    @Binding var isRecentered: Bool
    @Binding var zoomScale: CGFloat
    @State private var isDragging = false
    @State private var dragStartOffset: CGPoint = .zero
    @State private var isHoveringOnTree: Bool = false

    func body(content: Content) -> some View {
        content
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        zoomScale = scale.magnitude
                    }
            )
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isRecentered = false
                    if !isDragging {
                        isDragging = true
                        NSCursor.pointingHand.push()
                        dragStartOffset = currentOffset
                    }

                    let adjustedTranslation = CGPoint(
                        x: value.translation.width * zoomScale,
                        y: value.translation.height * zoomScale
                    )

                    currentOffset = CGPoint(
                        x: dragStartOffset.x + adjustedTranslation.x,
                        y: dragStartOffset.y + adjustedTranslation.y
                    )
                }
                .onEnded { _ in
                    isDragging = false
                    NSCursor.pop()
                }
            )
            .onHover { inside in
                self.isHoveringOnTree = inside
                if inside {
                    viewModel.setScrollWheelMonitor( NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                        guard isHoveringOnTree else { return nil }
                        zoomScale = max(0.1, zoomScale + event.deltaY * 0.01)
                        return nil
                    })
                } else if let monitor = viewModel.scrollWheelMonitor {
                    NSEvent.removeMonitor(monitor)
                    viewModel.setScrollWheelMonitor(nil)
                }
            }
    }
}

extension View {
    func zoomAndPannable(
        viewModel: ZoomAndPanViewModel,
        currentOffset: Binding<CGPoint>,
        zoomScale: Binding<CGFloat>,
        isRecentered: Binding<Bool>
    ) -> some View {
        modifier(ZoomAndPanModifier(
            viewModel: viewModel,
            currentOffset: currentOffset,
            isRecentered: isRecentered,
            zoomScale: zoomScale
        ))
    }
}
