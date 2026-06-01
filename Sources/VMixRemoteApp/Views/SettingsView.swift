// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Profiles") {
                Text("~/Library/Application Support/VMixRemote/Profiles")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Bundle Identifier") {
                Text("com.vmixremote.macos")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 520)
    }
}
