//
//  PreciseLineHeightText.swift
//  Xferro
//
//  Created by Taha Bebek on 3/13/25.
//

import SwiftUI

struct PreciseLineHeightText: NSViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let lineHeight: CGFloat

    init(
        text: String,
        fontSize: CGFloat = NSFont.preferredFont(forTextStyle: .body).pointSize,
        lineHeight: CGFloat = 20.0
    ) {
        self.text = text
        self.fontSize = fontSize
        self.lineHeight = lineHeight
    }

    func makeNSView(context: Context) -> NSTextView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer()
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isFieldEditor = false
        textView.drawsBackground = false
        textView.isRichText = false
        textView.usesFontPanel = false
        textView.allowsDocumentBackgroundColorChange = false
        
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.3),
            .foregroundColor: NSColor.selectedTextColor
        ]

        updateTextView(textView)
        return textView
    }

    func updateNSView(_ textView: NSTextView, context: Context) {
        textView.isSelectable = true
        updateTextView(textView)
    }

    private func updateTextView(_ textView: NSTextView) {
        let monoFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: monoFont,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: NSColor.white
            ]
        )

        textView.textStorage?.setAttributedString(attributedString)
        textView.selectedTextAttributes = [
            .backgroundColor: Color.accentColor.nsColor.withAlphaComponent(0.3),
            .foregroundColor: NSColor.white
        ]
    }
}
