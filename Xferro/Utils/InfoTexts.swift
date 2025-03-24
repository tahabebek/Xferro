//
//  InfoTexts.swift
//  Xferro
//
//  Created by Taha Bebek on 3/20/25.
//

import Foundation

enum InfoTexts {
    static let forcePushWithLease = """
    "Force with Lease" is a safer alternative to the standard force command.
    
    When you use force-with-lease, it will only allow the push to proceed if your local copy of the remote branch is up-to-date. This helps prevent you from accidentally overwriting changes that others have pushed to the branch since you last fetched or pulled.
    
    Here's how it works:
    - If someone else has pushed changes to the remote branch that you haven't pulled yet, the force-with-lease push will fail
    - This protects you from inadvertently overwriting their work
    - Unlike a regular force push, which will overwrite the remote branch regardless of its state
    
    This is particularly useful in collaborative environments where multiple people might be working on the same branch. It provides a safety check while still allowing you to rewrite history when needed.
    """

    static let amend = """
    "Amend" allows you to modify your most recent commit without creating a new commit entry in the history.
    
    Here's what amending does:
    
    1. It takes your current selected files/lines and uses it to replace the contents of the most recent commit.
    2. It lets you update the commit message if you want.
    
    Common use cases for amend include:
    
    - Fixing typos in commit messages
    - Adding files you forgot to include in the commit
    - Making small changes to files that logically belong in the previous commit
    
    Important things to know about amend:
    
    - It rewrites the history, so don't amend commits that have already been pushed to a shared repository (unless you're using force-with-lease)
    - You can only amend the most recent commit
    - If you need to modify older commits, you'd need to use interactive rebase instead
    """

    static let stash = """
    Push Stash: 
    
    "Push Stash" temporarily saves your uncommitted changes to a storage area called the stash stack. When you stash changes, it takes all modified tracked files, saves them in the stash, and then reverts your working directory to match the HEAD commit. This gives you a clean working directory without losing your in-progress work.
    
    You can stash multiple sets of changes, creating a stack of stashes. Each stash gets an identifier and can optionally have a message to help you remember what it contains.
    
    Pop Stash:
    
    "Pop Stash" retrieves the most recent stash from the stack and applies those changes to your current working directory. The key difference from other stash retrieval commands is that pop also removes the stash from the stack after applying it.
    
    When you pop a stash, it tries to merge the stashed changes into your current working directory. If there are conflicts, you'll need to resolve them manually.
    
    When to Use Them:
    
    Stashing is useful when you need to switch contexts quickly without committing incomplete work. For example, when you need to:
    
    - Switch to a different branch to work on something urgent
    - Pull changes from remote when you have local modifications
    - Clear your workspace temporarily to test something
    
    The push and pop operations together create a workflow that lets you set aside work and then retrieve it later, maintaining a clean commit history while not losing any changes.
    """

    static let applyStash = """
    "Apply Stash" is a command that retrieves a stashed set of changes and applies them to your current working directory, but unlike stash pop, it keeps the stash in the stash stack.
    
    When you run stash apply, it takes the changes from the stash and attempts to reapply them to your current working directory. The stashed changes are merged into your working files, potentially modifying tracked files that exist in both your current state and the stash.
    
    The key characteristic of stash apply is that it's non-destructive to your stash stack. After applying a stash, that stash remains available in the stack, which can be useful if you need to apply the same stashed changes to multiple branches or if you want to keep the stash as a backup.
    """

    static let push = """
    "Push" is the command used to upload your local repository content to a remote repository. When you push, it sends the commits, branches, tags, and other objects from your local repository to the remote, updating it with your changes.
    
    When you push, you're essentially synchronizing the remote repository with your local changes, making them available to other collaborators.
    
    The push operation requires:
    
    - A remote repository that you have permission to push to
    - One or more commits in your local repository that aren't in the remote
    - A branch or reference to push
    
    By default, it only pushes changes if they can be fast-forwarded, meaning they build linearly on top of the remote's current state. If your local history has diverged from the remote (for example, if someone else pushed changes while you were working), it will reject your push to prevent overwriting others' work.
    
    In such cases, you would typically need to:
    
    - Pull the remote changes first
    - Merge or rebase your work
    - Then push again
    
    If a push fails due to authentication problems, it typically means it cannot verify your identity with the remote repository. When using SSH for authentication, this often indicates an issue with your SSH keys.
    """

    static let commit = """
    "Commit" is the command that records changes to your repository. When you make a commit, it takes a snapshot of your current staged changes and stores it permanently in your repository's history.
    
    A commit serves as a checkpoint in your project's timeline. Each commit:
    
    - Has a unique identifier (hash)
    - Contains a complete snapshot of all tracked files
    - Includes metadata like author, date, and a message describing the changes
    - References its parent commit(s), creating a chain of history
    
    The commit message is crucial as it explains what changes were made and why. This message becomes part of the permanent history and helps others (and your future self) understand the purpose of the modifications.
    
    Commits are local operations, meaning they happen entirely in your local repository without requiring internet connection or server interaction. They remain in your local history until you explicitly push them to a remote repository.
    """

    static let fetch = """
    "Fetch" is the command used to download objects and references from a remote repository to your local repository without integrating those changes into your working files.
    
    When you fetch from a remote repository, it retrieves all the branches, tags, and commits that exist on the remote but don't exist in your local repository. This updates your remote-tracking branches (like origin/main) to match what's on the remote server, but doesn't modify your local branches or working directory.
    
    Fetch is essentially an information-gathering operation. It:
    
    - Updates your remote-tracking branches
    - Downloads new objects (commits, files, etc.) that you don't have
    - Updates your local representation of the remote repository's state
    - Doesn't change your current branch or working files
    
    This is in contrast to "Pull", which fetches and then automatically merges or rebases the retrieved changes into your current branch.
    
    Fetch is useful when you want to:
    
    - See what others have been working on without integrating those changes
    - Review changes before merging them
    - Update your local copy of the remote repository without disrupting your current work
    - Check if there are any updates before deciding whether to incorporate them
    """

    static let pull = """
    "Pull" is the command used to fetch changes from a remote repository and immediately integrate them into your current working branch. It's essentially a combination of two other commands: fetch followed by merge or rebase.
    
    When you perform a pull operation, it:
    
    1. First fetches all the changes from the specified remote repository, updating your remote-tracking branches
    2. Then automatically merges (or rebases) the retrieved changes into your current local branch
    
    If you use pull with merge, it creates a new merge commit if there are any changes to integrate. This preserves the complete history, including parallel development. 
    
    If you use rebase instead, it replays your local commits on top of the updated remote branch, creating a linear history.
    
    Pull is designed to keep your local branch up to date with its remote counterpart. It's commonly used when you want to:
    
    - Get the latest changes from a collaborative project
    - Update your local environment with changes made by teammates
    - Ensure you're working with the most current code before pushing your own changes
    """

    static let branch = """
    Branch is a lightweight, movable pointer to a specific commit in your repository's history. Branches allow parallel development within the same repository by creating separate lines of development.
    
    When you create a branch, it simply creates a new reference that points to the current commit. As you make new commits on that branch, the pointer moves forward automatically to track your latest changes. This allows different features, fixes, or experiments to evolve independently without affecting each other.
    
    Creating additional branches allows you to:
    
    - Work on new features without affecting the stable codebase
    - Make fixes to specific versions of your software
    - Try experimental changes that may or may not be incorporated later
    - Collaborate with others without interfering with each other's work
    
    Branches can be created, switched between, merged together, and deleted. When development on a branch is complete, you can merge it back into another branch (like the main branch), incorporating all its changes.
    
    Branches are one of the most powerful features, enabling flexible workflows where multiple streams of development can progress simultaneously. They're particularly valuable for team collaboration and for maintaining multiple versions of a project.
    """

    static let tag = """
    Tag is a reference that points to a specific commit in your repository's history, marking it as an important point or milestone. Unlike branches, tags don't move - they permanently mark a particular commit, typically used to identify release versions.
    
    Tags serve as fixed historical markers that give human-readable names to specific commits. While branches are designed to track ongoing development, tags are designed to mark significant points in your project's timeline that won't change.
    
    There are two types of tags:
    
    - Lightweight tags - simple pointers to a commit
    - Annotated tags - full objects that include metadata like the tagger's name, email, date, and a message
    
    Tags are commonly used to mark release versions (like v1.0.0, v2.1.3), major milestones, or other significant points in a project's history. They make it easy to:
    
    - Identify and reference specific versions of your code
    - Checkout a particular release for debugging or review
    - Deploy a known stable version
    - Create release archives or documentation
    
    Tags play an important role in version management and help provide a stable reference point in an otherwise constantly evolving codebase.
    """

    static let wip = """
    We've created a Git client that automatically generates backup branches and commits changes as you work, ensuring your code is always protected without disrupting your workflow. Every time you make a change to your files, Xferro automatically commits those changes to a backup branch and pushes them to the remote repository.
    
    Why We Matter
    
    The average developer loses 5-7 hours of work monthly due to various coding mishaps. Xferro transforms this experience by making lost work a thing of the past, protecting you from common scenarios like:
    
    - Accidental `git reset --hard` commands
    - Clicking "discard changes" on autopilot
    - Losing track of good solutions when experimenting with LLMs
    - Coffee spills and hardware failures
    - IDE crashes after hours of uncommitted changes
    - Power outages and system failures
    - Merge conflicts from pulling without stashing
    """
}
