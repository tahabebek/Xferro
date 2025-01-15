import Foundation

extension Date {
    public func toString(dateFormat format: String) -> String {
        let formatter = DateFormatter()
        
        formatter.dateFormat = format
        
        return formatter.string(from: self)
    }
}

extension Date {
    public var dd_dot_MM_dot_YYYY: String {
        toString(dateFormat: "dd.MM.yyyy")
    }
    
    public var hh_colon_mm_colon_space_a: String {
        toString(dateFormat: "hh:mm a")
    }
    
    public var hh_colon_mm_colon_ss_space_a: String {
        toString(dateFormat: "hh:mm:ss a")
    }
    
    public var hh_colon_mm_colon_ss_space_a_space_dd_dot_MM_dot_YYYY: String {
        toString(dateFormat: "hh:mm:ss a dd.MM.yyyy")
    }
}
