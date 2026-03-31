//
//  InputTextfield.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

enum PickerState: Equatable {
    case selection
    case loading(Agent)
    case reaction(Agent, String)
    case setup(Agent)
    
    var isLoading: Bool {
        switch self {
        case .loading, .setup:
            return true
        default:
            return false
        }
    }
    
    var lockedAgent: Agent? {
        switch self {
        case .loading(let a), .reaction(let a, _), .setup(let a): return a
        default: return nil
        }
    }
}

struct InputTextfield: View {
    @EnvironmentObject var viewModel: MissionViewModel
    @FocusState private var isFocused
    @State private var showDeadlinePicker = false
    
    private var addEnabled: Bool {
        missionText.count >= 3 && !viewModel.notificationsDisabled
    }
    
    private var missionText: String {
        viewModel.missionText
    }
    
    private var deadlineFormatted: String {
        let total = Int(viewModel.deadlineOffset)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if minutes == 0 { return "in \(hours)h" }
        if hours == 0 { return "in \(minutes)m" }
        return "in \(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Deadline Anzeige
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Image(icon: .clock)
                        .font(.system(size: 12, weight: .medium))
                    Text(L10n.Input.deadlineLabel(deadlineFormatted))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .onTapGesture {
                    if ProAccess.canChangeDeadline {
                        showDeadlinePicker = true
                    } else {
                        viewModel.showPaywall = true
                    }
                }
                
                HStack(spacing: 4) {
                    Image(icon: .bag)
                        .font(.system(size: 12, weight: .medium))
                    if let agent = viewModel.selectedAgent {
                        Text(agent.displayName)
                            .font(.system(size: 13, weight: .medium))
                    } else {
                        Text(L10n.Input.agentPlaceholder)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // Input Row
            HStack(spacing: 15) {
                TextField("", text: $viewModel.missionText, prompt: Text(L10n.Input.placeholder), axis: .vertical)
                    .focused($isFocused)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.top, 15)
                    .onChange(of: viewModel.missionText) { _, newValue in
                        if newValue.count > 120 {
                            viewModel.missionText = String(newValue.prefix(120))
                        }
                    }
                
                if let selectedAgent = viewModel.selectedAgent, addEnabled {
                    Image(icon: .checkmarkCircle)
                        .font(.system(size: 26, weight: .semibold))
                        .frame(width: 30, height: 40, alignment: .bottom)
                        .foregroundStyle(.blue)
                        .onTapGesture {
                            Task {
                                await MainActor.run { isFocused = false }
                                await viewModel.startMissionWithQuietCheck(selectedAgent, title: missionText)
                            }
                        }
                } else {
                    Color.clear
                        .frame(width: 30, height: 40)
                }
            }
        }
        .errorFeedback(trigger: viewModel.error)
        .errorFeedback(trigger: viewModel.showQuietHoursAlert)
        .animation(.snappy(duration: 0.3), value: missionText.isEmpty)
        .onChange(of: isFocused) { oldValue, newValue in
            viewModel.isFocused = isFocused
        }
        .onChange(of: viewModel.isFocused) { oldValue, newValue in
            isFocused = newValue
        }
        .sheet(isPresented: $showDeadlinePicker) {
            DeadlinePickerSheet(offset: $viewModel.deadlineOffset)
        }
        .alert(L10n.QuietHours.alertTitle, isPresented: $viewModel.showQuietHoursAlert) {
            Button(L10n.QuietHours.alertStart) {
                Task { await viewModel.confirmQuietHoursStart() }
            }
            Button(L10n.QuietHours.alertChange) {
                viewModel.changeQuietHours()
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.QuietHours.alertMessage(QuietHours.formattedRange))
        }
        .sheet(isPresented: $viewModel.showQuietHoursSheet) {
            QuietHoursSheet()
        }
        .alert(L10n.Common.error, isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button(L10n.Common.ok) { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }
}

// MARK: - Deadline Picker Sheet

struct DeadlinePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var offset: TimeInterval

    // Local absolute date for the wheel picker, initialized fresh on appear
    @State private var selectedDate: Date = Date().addingTimeInterval(2 * 60 * 60)

    private var minDate: Date { Date() }
    private var maxDate: Date { Date().addingTimeInterval(24 * 60 * 60) }

    private let quickOptions: [(label: String, seconds: Double)] = [
        ("1h", 3600), ("2h", 7200), ("4h", 4 * 3600)
    ]

    private func isSelected(_ seconds: Double) -> Bool {
        abs(offset - seconds) < 5 * 60
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                hourPicker
                    .padding(.top, 12)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: minDate...maxDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: selectedDate) { _, newValue in
                    let raw = newValue.timeIntervalSinceNow
                    offset = max(0, (raw / 60).rounded() * 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.Input.deadlinePickerTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) { dismiss() }
                }
            }
            .presentationBackground(.black.opacity(0.6))
        }
        .presentationDetents([.height(380)])
        .onAppear {
            selectedDate = Date().addingTimeInterval(offset)
        }
    }

    var hourPicker: some View {
        HStack(spacing: 10) {
            ForEach(quickOptions, id: \.seconds) { option in
                Text(option.label)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        isSelected(option.seconds)
                            ? Color.blue.opacity(0.2)
                            : Color.white.opacity(0.08)
                    )
                    .foregroundStyle(isSelected(option.seconds) ? .blue : .secondary)
                    .clipShape(Capsule())
                    .button {
                        offset = option.seconds
                        selectedDate = Date().addingTimeInterval(option.seconds)
                    }
            }
        }
    }
}

#Preview {
    DeadlinePickerSheet(offset: .constant(7200))
}
