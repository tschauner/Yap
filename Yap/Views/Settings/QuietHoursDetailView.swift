// QuietHoursDetailView.swift
// Yap

import SwiftUI

/// Detail-View für Silent Hours — NavigationLink aus Settings.
/// Gleicher Stil wie CustomRoastView.
struct QuietHoursDetailView: View {
    @State private var isEnabled: Bool = QuietHours.isEnabled
    @State private var startTime: Date = Calendar.current.date(
        bySettingHour: QuietHours.start, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var endTime: Date = Calendar.current.date(
        bySettingHour: QuietHours.end, minute: 0, second: 0, of: Date()
    ) ?? Date()
    
    var body: some View {
        List {
            Section {
                Toggle(L10n.QuietHours.enabled, isOn: $isEnabled)
            } footer: {
                Text(L10n.QuietHours.footer)
            }
            
            if isEnabled {
                Section {
                    HStack {
                        Text(L10n.QuietHours.from)
                        Spacer()
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text(L10n.QuietHours.until)
                        Spacer()
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
            }
        }
        .navigationTitle(L10n.QuietHours.title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
        .onChange(of: isEnabled) { _, newValue in
            QuietHours.isEnabled = newValue
        }
        .onChange(of: startTime) { _, newValue in
            QuietHours.start = Calendar.current.component(.hour, from: newValue)
        }
        .onChange(of: endTime) { _, newValue in
            QuietHours.end = Calendar.current.component(.hour, from: newValue)
        }
    }
}

#Preview {
    NavigationStack {
        QuietHoursDetailView()
    }
}
