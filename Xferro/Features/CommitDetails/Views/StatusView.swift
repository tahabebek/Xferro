//
//  StatusView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import SwiftUI

struct Action: Identifiable, Equatable {
    let id: String = UUID().uuidString
    let title: String
}

struct StatusView: View {
    enum BoxActions: String, CaseIterable {
        case splitAndCommit = "Split and Commit"
        case amend = "Amend"
        case stageAll = "Include All"
        case stageAllAndCommit = "Include All and Commit"
        case stageAllAndAmend = "Include All and Amend"
        case stageAllCommitAndPush = "Include All, Commit, and Push"
        case stageAllAmendAndPush = "Include All, Amend, and Push"
        case stageAllCommitAndForcePush = "Include All, Commit, and Force Push"
        case stageAllAmendAndForcePush = "Include All, Amend, and Force Push"
        case stash = "Stash"
        case popStash = "Pop Stash"
        case applyStash = "Apply Stash"
        case discardAll = "Discard All"
        // TODO:
        case addCustom = "Add Custom"
    }

    @Bindable var statusViewModel: StatusViewModel

    @Environment(DiscardPopup.self) var discardPopup
    @Environment(\.windowSize) var windowSize
    @FocusState private var isTextFieldFocused: Bool
    @State private var discardDeltaInfo: DeltaInfo? = nil
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top
    @State private var boxActions: [Action] = BoxActions.allCases.map(\.rawValue).map(Action.init)
    @State private var scrollToFile: String? = nil

    private static let actionBoxBottomPadding: CGFloat = 4
    private static let actionBoxVerticalInnerPadding: CGFloat = 16

    private static var totalVerticalPadding: CGFloat {
        Self.actionBoxBottomPadding * 2 + Self.actionBoxVerticalInnerPadding * 2
    }

    @ViewBuilder var actionView: some View {
        VStack {
            HStack {
                Form {
                    TextField(
                        "Summary",
                        text: $statusViewModel.commitSummary,
                        prompt: Text("Summary for commit, amend or stash"),
                        axis: .vertical
                    )
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.roundedBorder)
                }
                commitButton("Commit")
            }
            .padding(.bottom, Self.actionBoxBottomPadding)
            AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                buttons
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
            .animation(.default, value: boxActions)
        }
    }

    var peekViews: some View {
        PeekViewContainer(statusViewModel: statusViewModel, scrollToFile: $scrollToFile)
    }

    var body: some View {
        let _ = Self._printChanges()
        HStack(spacing: 0) {
            VStack {
                actionView
                    .padding()
                    .background(Color(hexValue: 0x15151A))
                    .cornerRadius(8)
                changeBox
            }
            .frame(width: Dimensions.commitDetailsViewMaxWidth)
            peekViews
        }
        .onAppear {
            setInitialSelection()
            isTextFieldFocused = true
        }
        .onChange(of: statusViewModel.selectableStatus) { oldValue, newValue in
            if oldValue.oid != newValue.oid {
                setInitialSelection()
                isTextFieldFocused = false
            }
        }
        .onChange(of: discardDeltaInfo) { _, newValue in
            if let newValue, discardPopup.isPresented == false {
                discardPopup.show(title: discardAlertTitle(deltaInfo: newValue)) {
                    discard(deltaInfo: newValue)
                    self.discardDeltaInfo = nil
                } onCancel: {
                    self.discardDeltaInfo = nil
                }
            }
        }
        .animation(.default, value: statusViewModel.selectableStatus)
        .animation(.default, value: statusViewModel.stagedDeltaInfos)
        .animation(.default, value: statusViewModel.unstagedDeltaInfos)
        .animation(.default, value: statusViewModel.untrackedDeltaInfos)
        .animation(.default, value: statusViewModel.commitSummary)
        .padding(.horizontal, 6)
    }

    private func setInitialSelection() {
        if statusViewModel.currentDeltaInfo == nil {
            var item: DeltaInfo?
            if let firstItem = statusViewModel.stagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = statusViewModel.unstagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = statusViewModel.untrackedDeltaInfos.first {
                item = firstItem
            }
            if let item {
                statusViewModel.currentDeltaInfo = item
            }
        }
    }

    var hasChanges: Bool {
        !statusViewModel.stagedDeltaInfos.isEmpty ||
        !statusViewModel.unstagedDeltaInfos.isEmpty ||
        !statusViewModel.untrackedDeltaInfos.isEmpty
    }

    private var changeBox: some View {
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: false) {
                if !hasChanges {
                    Text("No changes.")
                }
                LazyVStack(spacing: 4) {
                    if statusViewModel.stagedDeltaInfos.isNotEmpty {
                        stagedView
                    }
                    if statusViewModel.unstagedDeltaInfos.isNotEmpty {
                        unstagedView
                    }
                    if statusViewModel.untrackedDeltaInfos.isNotEmpty {
                        untrackedView
                    }
                }
            }
            .padding()
        }
    }

    private func discardAlertTitle(deltaInfo: DeltaInfo) -> String {
        let oldFilePath = deltaInfo.oldFilePath
        let newFilePath = deltaInfo.newFilePath
        var title: String = "Are you sure you want to discard all the changes"

        if let oldFilePath, let newFilePath, oldFilePath == newFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let oldFilePath, let newFilePath {
            title += " to\n\(oldFilePath), and\n\(newFilePath)?"
        } else if let oldFilePath {
            title += " to\n\(oldFilePath)?"
        } else if let newFilePath {
            title += " to\n\(newFilePath)?"
        }
        return title
    }

    func discard(deltaInfo: DeltaInfo) {
        let oldFileURL = deltaInfo.oldFileURL
        let newFileURL = deltaInfo.newFileURL
        var fileURLs = [URL]()

        if let oldFileURL, let newFileURL, oldFileURL == newFileURL {
            fileURLs.append(oldFileURL)
        } else {
            if let oldFileURL {
                fileURLs.append(oldFileURL)
            }
            if let newFileURL {
                fileURLs.append(newFileURL)
            }
        }
        statusViewModel.discardTapped(fileURLs: fileURLs)
    }

    private var buttons: some View {
        ForEach(boxActions) { boxAction in
            switch boxAction.title {
            case BoxActions.splitAndCommit.rawValue:
                splitAndCommitButton(boxAction.title)
            case BoxActions.amend.rawValue:
                amendButton(boxAction.title)
            case BoxActions.stageAllAndCommit.rawValue:
                stageAllAndCommitButton(boxAction.title)
            case BoxActions.stageAllAndAmend.rawValue:
                stageAllAndAmendButton(boxAction.title)
            case BoxActions.stageAllCommitAndPush.rawValue:
                stageAllCommitAndPushButton(boxAction.title)
            case BoxActions.stageAllAmendAndPush.rawValue:
                stageAllAmendAndPushButton(boxAction.title)
            case BoxActions.stageAllCommitAndForcePush.rawValue:
                stageAllCommitAndForcePushButton(boxAction.title)
            case BoxActions.stageAllAmendAndForcePush.rawValue:
                stageAllAmendAndForcePushButton(boxAction.title)
            case BoxActions.stash.rawValue:
                pushStashButton(boxAction.title)
            case BoxActions.popStash.rawValue:
                popStashButton(boxAction.title)
            case BoxActions.applyStash.rawValue:
                applyStashButton(boxAction.title)
            case BoxActions.discardAll.rawValue:
                discardAllButton(boxAction.title)
            default:
                EmptyView()
            }
        }
    }

    private var untrackedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.untrackedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        stageSelectedUntrackedButton(deltaInfo: deltaInfo)
                        ignoreSelectedUntrackedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Untracked Changes")
                Spacer()
                stageAllUntrackedButton
            }
            .padding(.bottom, 4)
        }
    }

    private var unstagedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.unstagedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        stageSelectedUnstagedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Excluded Changes")
                Spacer()
                stageAllUnstagedButton
            }
            .padding(.bottom, 4)
        }
    }

    private var stagedView: some View {
        Section {
            Group {
                ForEach(statusViewModel.stagedDeltaInfos) { deltaInfo in
                    HStack {
                        rowForDeltaInfo(deltaInfo)
                        unstageSelectedStagedButton(deltaInfo: deltaInfo)
                        discardSelectedButton(deltaInfo: deltaInfo)
                    }
                }
            }
        } header: {
            HStack {
                Text("Included Changes")
                Spacer()
                unstageAllStagedButton
            }
            .padding(.bottom, 4)
        }
    }

    private func rowForDeltaInfo(_ deltaInfo: DeltaInfo) -> some View {
        HStack {
            Image(systemName: deltaInfo.statusImageName).foregroundColor(deltaInfo.statusColor)
            Text(deltaInfo.statusFileName)
                .font(.body)
                .foregroundStyle(statusViewModel.currentDeltaInfo == deltaInfo ? Color.accentColor : Color.fabulaFore1)
            Spacer()
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            statusViewModel.currentDeltaInfo = deltaInfo
            scrollToFile = deltaInfo.id
        }
    }
}

// ActionBox
extension StatusView {
    func commitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
                guard !commitSummaryIsEmptyOrWhitespace else {
                    fatalError(.impossible)
                }
                statusViewModel.commitTapped()
                isTextFieldFocused = false
            }
    }
    func splitAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: !hasChanges) {
                guard !commitSummaryIsEmptyOrWhitespace else {
                    fatalError(.impossible)
                }
                statusViewModel.commitTapped()
                isTextFieldFocused = false
            }
    }
    func amendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            statusViewModel.amendTapped()
        }
    }
    func stageAllAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges) {
            guard !commitSummaryIsEmptyOrWhitespace else {
                fatalError(.impossible)
            }
            statusViewModel.stageAllTapped()
            statusViewModel.commitTapped()
            isTextFieldFocused = false
        }
    }
    func stageAllAndAmendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            statusViewModel.stageAllTapped()
            statusViewModel.amendTapped()
            isTextFieldFocused = false
        }
    }
    func stageAllCommitAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges
        ) {
            guard !commitSummaryIsEmptyOrWhitespace else {
                fatalError(.impossible)
            }
            statusViewModel.stageAllTapped()
            statusViewModel.commitTapped()
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    func stageAllCommitAndForcePushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges,
            dangerous: true
        ) {
            guard !commitSummaryIsEmptyOrWhitespace else {
                fatalError(.impossible)
            }
            statusViewModel.stageAllTapped()
            statusViewModel.commitTapped()
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    func stageAllAmendAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            statusViewModel.stageAllTapped()
            statusViewModel.amendTapped()
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    func stageAllAmendAndForcePushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: !hasChanges,
            dangerous: true
        ) {
            statusViewModel.stageAllTapped()
            statusViewModel.amendTapped()
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    func pushStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func popStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func applyStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func discardAllButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges, dangerous: true) {
            statusViewModel.discardAllTapped()
        }
    }
    func addCustomButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
}

// All files
extension StatusView {
    func discardSelectedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Discard", dangerous: true, isProminent: false, isSmall: true) {
            discardDeltaInfo = deltaInfo
        }
    }
}

// Staged Files
extension StatusView {
    var unstageAllStagedButton: some View {
        AnyView.buttonWith(title: "Exclude All") {
            statusViewModel.stageOrUnstageTapped(stage: false)
        }
    }
    func unstageSelectedStagedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Exclude", isProminent: false, isSmall: true) {
            statusViewModel.stageOrUnstageTapped(stage: false, deltaInfos: [deltaInfo])
        }
    }
}

// Unstaged Files
extension StatusView {
    var stageAllUnstagedButton: some View {
        AnyView.buttonWith(title: "Include All") {
            statusViewModel.stageOrUnstageTapped(stage: true)
        }
    }
    func stageSelectedUnstagedButton(deltaInfo: DeltaInfo)-> some View {
        AnyView.buttonWith(title: "Include", isProminent: false, isSmall: true) {
            statusViewModel.stageOrUnstageTapped(stage: true, deltaInfos: [deltaInfo])
        }
    }
}

// Untracked Files
extension StatusView {
    var stageAllUntrackedButton: some View {
        AnyView.buttonWith(title: "Track all") {
            statusViewModel.trackAllTapped()
        }
    }

    func stageSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Track", isProminent: false, isSmall: true) {
            statusViewModel.trackTapped(stage: true, deltaInfos: [deltaInfo])
        }
    }

    func ignoreSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Ignore", isProminent: false, isSmall: true) {
            statusViewModel.ignoreTapped(deltaInfo: deltaInfo)
        }
    }
}

// MARK: Helpers
extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        statusViewModel.commitSummary.isEmptyOrWhitespace
    }
}

struct ActionBoxHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MessageBoxHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
