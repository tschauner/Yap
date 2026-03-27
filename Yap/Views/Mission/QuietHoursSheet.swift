// QuietHoursSheet.swift
// Yap

import SwiftUI

/// Kompaktes Sheet zum Anpassen der Silent Hours.
/// Wird aus dem Quiet-Hours-Alert heraus geöffnet ("Ändern").
struct QuietHoursSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MissionViewModel
    
    @State private var isEnabled: Bool = QuietHours.isEnabled
    @State private var startTime: Date = Calendar.current.date(
        bySettingHour: QuietHours.start, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var endTime: Date = Calendar.current.date(
        bySettingHour: QuietHours.end, minute: 0, second: 0, of: Date()
    ) ?? Date()
    
    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        save()
                        dismiss()
                    }
                }
            }
            .presentationBackground(.black.opacity(0.6))
            .animation(.easeInOut(duration: 0.25), value: isEnabled)
        }
        .presentationDetents([.medium])
    }
    
    private func save() {
        QuietHours.isEnabled = isEnabled
        QuietHours.start = Calendar.current.component(.hour, from: startTime)
        QuietHours.end = Calendar.current.component(.hour, from: endTime)
    }
}

#Preview {
    QuietHoursSheet()
}
