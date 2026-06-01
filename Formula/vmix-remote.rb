# SPDX-License-Identifier: Apache-2.0

class VmixRemote < Formula
  desc "Native macOS mixer remote rebuilt in SwiftUI with CoreMIDI support"
  homepage "https://github.com/frederikschulze1701-blip/VMixRemote"
  url "https://github.com/frederikschulze1701-blip/VMixRemote.git",
      tag: "v0.1.0"
  license "Apache-2.0"
  head "https://github.com/frederikschulze1701-blip/VMixRemote.git", branch: "main"

  depends_on xcode: ["14.0", :build]
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox", "--product", "VMixRemoteApp"

    app = prefix/"VMix Remote.app"
    contents = app/"Contents"
    macos = contents/"MacOS"
    resources = contents/"Resources"

    macos.mkpath
    resources.mkpath
    macos.install ".build/release/VMixRemoteApp"
    resources.install "Sources/VMixRemoteApp/Resources/AppIcon.icns"

    (contents/"Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>VMixRemoteApp</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleIdentifier</key>
        <string>com.vmixremote.macos</string>
        <key>CFBundleName</key>
        <string>VMix Remote</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>0.1.0</string>
        <key>CFBundleVersion</key>
        <string>1</string>
        <key>LSMinimumSystemVersion</key>
        <string>13.0</string>
        <key>NSPrincipalClass</key>
        <string>NSApplication</string>
      </dict>
      </plist>
    XML

    (bin/"vmix-remote").write <<~SH
      #!/bin/bash
      open "#{app}"
    SH
    chmod 0755, bin/"vmix-remote"
  end

  test do
    assert_path_exists prefix/"VMix Remote.app/Contents/MacOS/VMixRemoteApp"
    assert_path_exists prefix/"VMix Remote.app/Contents/Resources/AppIcon.icns"
  end
end
