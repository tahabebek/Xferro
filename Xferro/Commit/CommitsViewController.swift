//
//  CommitsViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit

class CommitsViewController: NSViewController {
    private let project: Project
    private var outlineView: NSOutlineView!

    init(project: Project) {
        self.project = project
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let scrollView = NSScrollView()
        outlineView = NSOutlineView()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("commits"))
        outlineView.addTableColumn(column)

        outlineView.headerView = nil
        outlineView.allowsColumnReordering = false
        outlineView.allowsColumnResizing = false
        outlineView.allowsColumnSelection = false
        outlineView.allowsEmptySelection = false
        outlineView.allowsMultipleSelection = false
        outlineView.allowsTypeSelect = false
        outlineView.registerForDraggedTypes([])

        outlineView.style = .plain
        outlineView.rowSizeStyle = .custom
        outlineView.rowHeight = 40
        outlineView.indentationPerLevel = 0
        outlineView.gridStyleMask = []

        outlineView.delegate = self
        outlineView.dataSource = self

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let label = NSTextField(labelWithString: "Commits")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.black

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        scrollView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true

        view = scrollView
    }
}

extension CommitsViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0 {
            print("row selected \(selectedRow)")
//            let item = outlineView.item(atRow: selectedRow)
//            updateDetailViews(for: item)
        }
    }
}

extension CommitsViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
//        if let group = item as? CommitGroup {
//            return group.commits.count
//        }
//        return groups.count
        2
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
//        if let group = item as? CommitGroup {
//            return group.commits[index]
//        }
//        return groups[index]
        3
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
//        return item is CommitGroup
        false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
//        let cell = CommitCellView()
//
//        if let group = item as? CommitGroup {
//            // Create a "fake" commit for the group header
//            let groupCommit = Commit(
//                message: "\(group.title) (\(group.commits.count))",
//                timestamp: Date(),
//                files: []
//            )
//            cell.configure(with: groupCommit, isGroupItem: true)
//        } else if let commit = item as? Commit {
//            cell.configure(with: commit, isGroupItem: false)
//        }
//
//        return cell
        NSView()
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRow row: Int) -> CGFloat {
//        let item = outlineView.item(atRow: row)
//        return item is CommitGroup ? 30 : 40
        40
    }

    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        // Hide the disclosure triangle since we're handling indentation ourselves
        return false
    }
}
