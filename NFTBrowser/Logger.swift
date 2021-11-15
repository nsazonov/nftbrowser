import Foundation
import os

let subsystem = "com.nikolaysazonov"

struct Log {
    static let table = OSLog(subsystem: subsystem, category: "table")
    static let client = OSLog(subsystem: subsystem, category: "client")
    static let imageCache = OSLog(subsystem: subsystem, category: "imageCache")
}
