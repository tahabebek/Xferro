//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

private class Wrapper<T> {
    let value: T

    init(_ value: T) {
        self.value = value
    }
    deinit {

    }
}

enum Credentials: Equatable {
    case `default`
    case username(String)
    case plaintext(username: String, password: String)
    case sshAgent
    case sshFile(username: String, publicKeyPath: String, privateKeyPath: String, passphrase: String)
    case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)

    /// see `git_credential_t`
    internal var type: git_credential_t {
        switch self {
        case .default:
            return GIT_CREDENTIAL_DEFAULT
        case .username:
            return GIT_CREDENTIAL_USERNAME
        case .plaintext:
            return GIT_CREDENTIAL_USERPASS_PLAINTEXT
        case .sshAgent:
            return git_credential_t(rawValue: GIT_CREDENTIAL_SSH_MEMORY.rawValue + GIT_CREDENTIAL_SSH_KEY.rawValue)
        case .sshFile:
            return GIT_CREDENTIAL_SSH_KEY
        case .sshMemory:
            return GIT_CREDENTIAL_SSH_MEMORY
        }
    }

    internal func allowed(by code: UInt32) -> Bool {
        return code & self.type.rawValue > 0
    }

    static func == (lhs: Credentials, rhs: Credentials) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default),
             (.username, .username),
             (.plaintext, .plaintext),
             (.sshAgent, .sshAgent),
             (.sshFile, .sshFile),
             (.sshMemory, .sshMemory):
            return true
        default:
            return false
        }
    }
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
func credentialsCallback(
    out: UnsafeMutablePointer<UnsafeMutablePointer<git_credential>?>?,
    url: UnsafePointer<CChar>?,
    username_from_url: UnsafePointer<CChar>?,
    allowed_types: UInt32,
    payload: UnsafeMutableRawPointer?
) -> Int32 {
    // Convert C strings to Swift strings if needed
    let urlString = url != nil ? String(cString: url!) : ""
    let usernameFromURL = username_from_url != nil ? String(cString: username_from_url!) : nil
    
    // Check what credential types are allowed
    let supportsSSH = (allowed_types & GIT_CREDENTIAL_SSH_KEY.rawValue) != 0
    let supportsUserPass = (allowed_types & GIT_CREDENTIAL_USERPASS_PLAINTEXT.rawValue) != 0
    let supportsDefault = (allowed_types & GIT_CREDENTIAL_DEFAULT.rawValue) != 0
    
    // Get the credential payload if provided
    var credentialInfo: CredentialInfo? = nil
    if let payloadPtr = payload {
        credentialInfo = Unmanaged<CredentialInfo>.fromOpaque(payloadPtr).takeUnretainedValue()
    }
    switch credentialInfo?.credentials.first {
    case .sshFile(let username, let publicKeyPath, let privateKeyPath, let passphrase),
            .sshMemory(let username, let publicKeyPath, let privateKeyPath, let passphrase):
        let result = git_credential_ssh_key_new(
            out,
            username,
            publicKeyPath,
            privateKeyPath,
            "P1zzapr!nt"
        )
        
        if result == 0 {
            return 0 // Success
        }
        case .plaintext(let username, let password):
        let result = git_credential_userpass_plaintext_new(
            out,
            username,
            password
        )
        
        if result == 0 {
            return 0 // Success
        }
        default:
            break
    }
    
    // If all else fails, try default credentials if supported
    if supportsDefault {
        let result = git_credential_default_new(out)
        if result == 0 {
            return 0 // Success
        }
    }
    
    // No credentials worked
    return GIT_EAUTH.rawValue
}

class CredentialInfo {
    var url: GitURL?
    var credentials: [Credentials] = []
    var availableCredentials: [Credentials] = []
    var messageBlock: RemoteCallback.MessageBlock?
    var progressBlock: RemoteCallback.ProgressBlock?
    var mode: RemoteCallback.Mode?
    var lastTime: Double?
    var lastTimeInterval: TimeInterval?
    var lastTransferBytes: Int?
    var lastTransferSpeed: Int?
    var transferFinished: Bool?
    var indexFinished: Bool?
}
