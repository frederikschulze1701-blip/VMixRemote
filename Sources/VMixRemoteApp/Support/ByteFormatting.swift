// SPDX-License-Identifier: Apache-2.0

import Foundation

extension Array where Element == UInt8 {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
