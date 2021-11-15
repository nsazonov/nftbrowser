import Foundation
import os

let subsystem = "com.nikolaysazonov"

struct Log {
  static let table = OSLog(subsystem: subsystem, category: "table")
  static let Client = OSLog(subsystem: subsystem, category: "client")
}
