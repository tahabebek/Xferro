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
        case stageAll = "Stage All"
        case stageAllAndCommit = "Stage All and Commit"
        case stageAllAndAmend = "Stage All and Amend"
        case stageAllCommitAndPush = "Stage All, Commit, and Push"
        case stageAllAmendAndPush = "Stage All, Amend, and Push"
        case stageAllCommitAndForcePush = "Stage All, Commit, and Force Push"
        case stageAllAmendAndForcePush = "Stage All, Amend, and Force Push"
        case stash = "Stash"
        case popStash = "Pop Stash"
        case applyStash = "Apply Stash"
        // TODO:
//        case addCustom = "Add Custom"
    }
    @Environment(CommitsViewModel.self) var commitsViewModel
    @Environment(StatusViewModel.self) var statusViewModel
    @Environment(DiscardPopup.self) var discardPopup
    @Environment(\.windowSize) var windowSize
    @State private var commitSummary = Dictionary<OID, String>()
    @FocusState private var isTextFieldFocused: Bool
    @State private var discardDeltaInfo: DeltaInfo? = nil
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top
    @State private var boxActions: [Action] = BoxActions.allCases.map(\.rawValue).map(Action.init)
    @State private var actionBoxHeight: CGFloat = 0
    @State private var messageBoxHeight: CGFloat = 0

    private static let actionBoxBottomPadding: CGFloat = 4
    private static let actionBoxVerticalInnerPadding: CGFloat = 16

    private static var totalVerticalPadding: CGFloat {
        Self.actionBoxBottomPadding * 2 + Self.actionBoxVerticalInnerPadding * 2
    }
    var body: some View {
        VSplitView {
            actionBox
                .frame(height : actionBoxHeight + messageBoxHeight + Self.totalVerticalPadding)
                .padding(.bottom, Self.actionBoxBottomPadding)
            changeBox
                .padding(.top, Self.actionBoxBottomPadding)
                .frame(maxHeight: .infinity)
        }
        .onAppear {
            setInitialSelection()
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
        .animation(.default, value: commitsViewModel.currentDeltaInfo)
        .animation(.default, value: commitSummary)
        .padding(.horizontal, 6)
    }

    private func setInitialSelection() {
        if commitsViewModel.currentDeltaInfos[statusViewModel.selectableStatus.oid] == nil {
            var item: DeltaInfo?
            if let firstItem = statusViewModel.stagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = statusViewModel.unstagedDeltaInfos.first {
                item = firstItem
            } else if let firstItem = statusViewModel.untrackedDeltaInfos.first {
                item = firstItem
            }
            if let item {
                commitsViewModel.setCurrentDeltaInfo(oid: statusViewModel.selectableStatus.oid, deltaInfo: item)
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
            Color(hex: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: true) {
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
        commitsViewModel.discardFileButtonTapped(
            repository: statusViewModel.repository,
            fileURLs: fileURLs
        )
    }

    private var actionBox: some View {
        ZStack {
            Color(hex: 0x15151A)
                .cornerRadius(8)
            VStack(alignment: .leading) {
                messageBoxView
                flowActionsView
                    .frame(height: actionBoxHeight)
            }
            .padding(Self.actionBoxVerticalInnerPadding)
        }
    }

    private var messageBoxView: some View {
        HStack {
            Form {
                TextField(
                    "Message",
                    text: Binding(
                        get: { commitSummary[statusViewModel.selectableStatus.oid] ?? "" },
                        set: { commitSummary[statusViewModel.selectableStatus.oid] = $0 }
                    ),
                    prompt: Text("Message for commit, amend or stash"),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                commitButton("Commit")
                Spacer(minLength: 0)
            }
        }
        .padding(.bottom, 8)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.size) { _, newValue in
                        self.messageBoxHeight = newValue.height
                    }
            }
        )
    }

    private var flowActionsView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                    buttons
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onChange(of: geometry.size) { _, newValue in
                                self.actionBoxHeight = newValue.height
                            }
                    }
                )
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
            .animation(.default, value: boxActions)
        }
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
                Text("Untracked files")
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
                Text("Unstaged changes")
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
                Text("Staged changes")
                Spacer()
                unstageAllStagedButton
            }
            .padding(.bottom, 4)
        }
    }

    @ViewBuilder private func rowForDeltaInfo(_ deltaInfo: DeltaInfo) -> some View {
        let oldFileName = deltaInfo.oldFileURL?.lastPathComponent
        let newFileName = deltaInfo.newFileURL?.lastPathComponent
        Group {
            switch deltaInfo.delta.status {
            case .unmodified:
                fatalError(.impossible)
            case .added:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .green,
                        imageName: "a.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .deleted:
                if let oldFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: oldFileName,
                        color: .red,
                        imageName: "d.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .modified:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .blue,
                        imageName: "m.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .renamed:
                if let oldFileName, let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: "\(oldFileName) -> \(newFileName)",
                        color: .yellow,
                        imageName: "r.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .copied:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .green,
                        imageName: "c.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .ignored:
                fatalError(.unimplemented)
            case .untracked:
                if let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: newFileName,
                        color: .red,
                        imageName: "questionmark.square"
                    )
                } else {
                    fatalError(.impossible)
                }
            case .typeChange:
                if let oldFileName, let newFileName {
                    fileView(
                        deltaInfo: deltaInfo,
                        text: "\(oldFileName) -> \(newFileName)",
                        color: .yellow,
                        imageName: "r.square"
                    )
                } else {
                    fatalError(.impossible)
                }
                fatalError(.unimplemented)
            case .unreadable:
                fatalError(.unimplemented)
            case .conflicted:
                fatalError(.unimplemented)
            }
        }
        .contentShape(Rectangle())
        .frame(minHeight: 24)
        .frame(maxHeight: 48)
        .onTapGesture {
            commitsViewModel.setCurrentDeltaInfo(oid: statusViewModel.selectableStatus.oid, deltaInfo: deltaInfo)
        }
    }

    private func fileView(
        deltaInfo: DeltaInfo,
        text: String,
        color: Color,
        imageName: String
    ) -> some View {
        HStack {
            Image(systemName: imageName).foregroundColor(color)
            Text(text)
                .font(.body)
                .foregroundStyle(commitsViewModel.currentDeltaInfos[statusViewModel.selectableStatus.oid] == deltaInfo ? Color.accentColor : Color.fabulaFore1)
            Spacer()
        }
    }
}

// ActionBox
extension StatusView {
    func commitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
                guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                    fatalError(.impossible)
                }
                commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
                commitSummary[statusViewModel.selectableStatus.oid] = nil
                isTextFieldFocused = false
            }
    }
    func splitAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: !hasChanges) {
                guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                    fatalError(.impossible)
                }
                commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
                commitSummary[statusViewModel.selectableStatus.oid] = nil
                isTextFieldFocused = false
            }
    }
    func amendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
        }
    }
    func stageAllAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    func stageAllAndAmendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    func stageAllCommitAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges
        ) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
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
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    func stageAllAmendAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
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
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
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
        AnyView.buttonWith(title: "Unstage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.stagedDeltaInfos
            )
        }
    }
    func unstageSelectedStagedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Unstage", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }
}

// Unstaged Files
extension StatusView {
    var stageAllUnstagedButton: some View {
        AnyView.buttonWith(title: "Stage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.unstagedDeltaInfos
            )
        }
    }
    func stageSelectedUnstagedButton(deltaInfo: DeltaInfo)-> some View {
        AnyView.buttonWith(title: "Stage", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }
}

// Untracked Files
extension StatusView {
    var stageAllUntrackedButton: some View {
        AnyView.buttonWith(title: "Track all") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.untrackedDeltaInfos
            )
        }
    }

    func stageSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Track", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }

    func ignoreSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Ignore", isProminent: false, isSmall: true) {
            commitsViewModel.ignoreButtonTapped(
                repository: statusViewModel.repository,
                deltaInfo: deltaInfo
            )
        }
    }
}

// MARK: Helpers
extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        commitSummary[statusViewModel.selectableStatus.oid]?.isEmptyOrWhitespace ?? true
    }
}

