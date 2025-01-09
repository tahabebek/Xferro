//
//  RepositoryViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa

class RepositoryViewController: NSViewController {
    private var outlineView: NSOutlineView!
    private var splitView: NSSplitView!

    private var commitDetailViewController: CommitDetailViewController?
    private var fileDetailViewController: FileDetailViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Xferro"
    }

    override func loadView() {
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.wantsLayer = true
        splitView.layer?.backgroundColor = NSColor.white.cgColor

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

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

        let commitDetailPlaceholder = NSView()
        let fileDetailPlaceholder = NSView()

        splitView.addSubview(scrollView)
        splitView.addSubview(commitDetailPlaceholder)
        splitView.addSubview(fileDetailPlaceholder)

        splitView.setHoldingPriority(NSLayoutConstraint.Priority(253), forSubviewAt: 0)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(252), forSubviewAt: 1)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 2)
        splitView.setPosition(200, ofDividerAt: 0)
        splitView.setPosition(500, ofDividerAt: 1)

        view = splitView
    }

    private func updateDetailViews(for selectedItem: Any?) {
        // Remove existing view controllers
        commitDetailViewController?.removeFromParent()
        commitDetailViewController?.view.removeFromSuperview()

        fileDetailViewController?.removeFromParent()
        fileDetailViewController?.view.removeFromSuperview()

        // Create new view controllers based on selection
        if let item = selectedItem {
            // Create appropriate view controllers based on the selected item
            let newCommitDetail = createCommitDetailViewController(for: item)
            let newFileDetail = createFileDetailViewController(for: item)

            // Add new view controllers
            addChild(newCommitDetail)
            addChild(newFileDetail)

            splitView.replaceSubview(splitView.subviews[1], with: newCommitDetail.view)
            splitView.replaceSubview(splitView.subviews[2], with: newFileDetail.view)
            commitDetailViewController = newCommitDetail
            fileDetailViewController = newFileDetail
        }
    }

    private func createCommitDetailViewController(for item: Any) -> CommitDetailViewController {
        return CommitDetailViewController()
    }

    private func createFileDetailViewController(for item: Any) -> FileDetailViewController {
        return FileDetailViewController()
    }
}

extension RepositoryViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0 {
            let item = outlineView.item(atRow: selectedRow)
            updateDetailViews(for: item)
        }
    }
}

extension RepositoryViewController: NSOutlineViewDataSource {
//    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
//        if let group = item as? CommitGroup {
//            return group.commits.count
//        }
//        return groups.count
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
//        if let group = item as? CommitGroup {
//            return group.commits[index]
//        }
//        return groups[index]
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
//        return item is CommitGroup
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
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
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, heightOfRow row: Int) -> CGFloat {
//        let item = outlineView.item(atRow: row)
//        return item is CommitGroup ? 30 : 40
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
//        // Hide the disclosure triangle since we're handling indentation ourselves
//        return false
//    }
}
