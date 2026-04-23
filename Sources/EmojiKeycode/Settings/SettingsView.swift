import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    Image(systemName: model.axTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(model.axTrusted ? .green : .orange)
                    Text(model.axTrusted ? "Accessibility granted" : "Accessibility required")
                    Spacer()
                    Button("Open System Settings") { model.openAccessibility() }
                        .disabled(model.axTrusted)
                }
            }

            Section("Behavior") {
                Toggle("Auto-replace on closing colon", isOn: $model.autoReplace)
                Toggle("Show suggestion popup", isOn: $model.popup)
                Toggle("Launch at login", isOn: $model.launchAtLogin)
            }

            Section("About") {
                LabeledContent("Version", value: model.version)
                Text("Type `:shortcode:` in any input. Example: `:heart:` → ❤️")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
    }
}

final class SettingsModel: ObservableObject {
    @Published var axTrusted: Bool
    @Published var autoReplace: Bool {
        didSet { onAutoReplaceChange?(autoReplace) }
    }
    @Published var popup: Bool {
        didSet { onPopupChange?(popup) }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            if launchAtLogin != LaunchAtLogin.isEnabled {
                LaunchAtLogin.setEnabled(launchAtLogin)
            }
        }
    }

    let version: String
    var onAutoReplaceChange: ((Bool) -> Void)?
    var onPopupChange: ((Bool) -> Void)?
    var openAccessibility: () -> Void = {}

    init(axTrusted: Bool, autoReplace: Bool, popup: Bool) {
        self.axTrusted = axTrusted
        self.autoReplace = autoReplace
        self.popup = popup
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
