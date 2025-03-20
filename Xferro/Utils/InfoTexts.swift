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
    
    When you use force-with-lease, Git will only allow the push to proceed if your local copy of the remote branch is up-to-date. This helps prevent you from accidentally overwriting changes that others have pushed to the branch since you last fetched or pulled.
    
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
    
    - It rewrites Git history, so don't amend commits that have already been pushed to a shared repository (unless you're using force-with-lease)
    - You can only amend the most recent commit
    - If you need to modify older commits, you'd need to use interactive rebase instead
    """

    static let stash = """
    Push Stash: 
    
    "Push Stash" temporarily saves your uncommitted changes to a storage area called the stash stack. When you stash changes, Git takes all modified tracked files, saves them in the stash, and then reverts your working directory to match the HEAD commit. This gives you a clean working directory without losing your in-progress work.
    
    You can stash multiple sets of changes, creating a stack of stashes. Each stash gets an identifier and can optionally have a message to help you remember what it contains.
    
    Pop Stash:
    
    "Pop Stash" retrieves the most recent stash from the stack and applies those changes to your current working directory. The key difference from other stash retrieval commands is that pop also removes the stash from the stack after applying it.
    
    When you pop a stash, Git tries to merge the stashed changes into your current working directory. If there are conflicts, you'll need to resolve them manually.
    
    When to Use Them:
    
    Stashing is useful when you need to switch contexts quickly without committing incomplete work. For example, when you need to:
    
    - Switch to a different branch to work on something urgent
    - Pull changes from remote when you have local modifications
    - Clear your workspace temporarily to test something
    
    The push and pop operations together create a workflow that lets you set aside work and then retrieve it later, maintaining a clean commit history while not losing any changes.
    """

    static let push = """
    "Push" is the command used to upload your local repository content to a remote repository. When you push, Git sends the commits, branches, tags, and other objects from your local repository to the remote, updating it with your changes.
    
    When you push, you're essentially synchronizing the remote repository with your local changes, making them available to other collaborators.
    
    The push operation requires:
    
    - A remote repository that you have permission to push to
    - One or more commits in your local repository that aren't in the remote
    - A branch or reference to push
    
    By default, Git only pushes changes if they can be fast-forwarded, meaning they build linearly on top of the remote's current state. If your local history has diverged from the remote (for example, if someone else pushed changes while you were working), Git will reject your push to prevent overwriting others' work.
    
    In such cases, you would typically need to:
    
    - Pull the remote changes first
    - Merge or rebase your work
    - Then push again
    
    If a Git push fails due to authentication problems, it typically means Git cannot verify your identity with the remote repository. When using SSH for authentication with Git, this often indicates an issue with your SSH keys.
    """

    static let commit = """
    "Commit" is the command that records changes to your repository. When you make a commit, Git takes a snapshot of your current staged changes and stores it permanently in your repository's history.
    
    A commit serves as a checkpoint in your project's timeline. Each commit:
    
    - Has a unique identifier (hash)
    - Contains a complete snapshot of all tracked files
    - Includes metadata like author, date, and a message describing the changes
    - References its parent commit(s), creating a chain of history
    
    The commit message is crucial as it explains what changes were made and why. This message becomes part of the permanent history and helps others (and your future self) understand the purpose of the modifications.
    
    Commits are local operations, meaning they happen entirely in your local repository without requiring internet connection or server interaction. They remain in your local history until you explicitly push them to a remote repository.
    """
}
