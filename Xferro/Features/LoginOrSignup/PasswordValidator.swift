//
//  PasswordValidator.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

class PasswordValidator {
    struct ValidationRule {
        let pattern: String
        let message: String
    }

    private var rules: [ValidationRule] = []
    private let minLength: Int
    private let maxLength: Int

    init(minLength: Int = 8, maxLength: Int = 30) {
        self.minLength = minLength
        self.maxLength = maxLength

        addRule(pattern: "[A-Z]", message: "Must contain at least one uppercase letter")
        addRule(pattern: "[a-z]", message: "Must contain at least one lowercase letter")
        addRule(pattern: "[0-9]", message: "Must contain at least one number")
        addRule(pattern: "[@$!%*?&]", message: "Must contain at least one special character")
    }

    func addRule(pattern: String, message: String) {
        rules.append(ValidationRule(pattern: pattern, message: message))
    }

    func validate(_ password: String) -> [String] {
        var errors: [String] = []

        // Check length
        if password.count < minLength {
            errors.append("Password must be at least \(minLength) characters long")
        }

        if password.count > maxLength {
            errors.append("Password must be less than \(maxLength) characters long")
        }

        // Check all rules
        for rule in rules {
            if password.range(of: rule.pattern, options: .regularExpression) == nil {
                errors.append(rule.message)
            }
        }

        return errors
    }
}
