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
    @EnvironmentObject var viewModel: HomeViewModel
    @FocusState private var isFocused
    @State private var showDeadlinePicker = false
    
    private var addEnabled: Bool {
        missionText.count >= 3
    }
    
    private var missionText: String {
        viewModel.missionText
    }
    
    private var deadlineFormatted: String {
        viewModel.selectedDeadline.formatted(date: .omitted, time: .shortened)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Deadline Anzeige
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Image(icon: .clock)
                        .font(.system(size: 12, weight: .medium))
                    Text("until \(deadlineFormatted)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .onTapGesture {
                    showDeadlinePicker = true
                }
                
                HStack(spacing: 4) {
                    Image(icon: .bag)
                        .font(.system(size: 12, weight: .medium))
                    if let agent = viewModel.selectedAgent {
                        Text(agent.displayName)
                            .font(.system(size: 13, weight: .medium))
                    } else {
                        Text("Agent")
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            // Input Row
            HStack(spacing: 15) {
                TextField("", text: $viewModel.missionText, prompt: Text("What needs to get done?"), axis: .vertical)
                    .focused($isFocused)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 19, weight: .medium))
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
                                await viewModel.selectAgent(selectedAgent, title: missionText)
                            }
                        }
                } else {
                    Color.clear
                        .frame(width: 30, height: 40)
                }
            }
        }
        //.onAppear { isFocused = true }
        .animation(.snappy(duration: 0.3), value: missionText.isEmpty)
        .onChange(of: isFocused) { oldValue, newValue in
            viewModel.isFocused = isFocused
        }
        .onChange(of: viewModel.isFocused) { oldValue, newValue in
            isFocused = newValue
        }
        .sheet(isPresented: $showDeadlinePicker) {
            DeadlinePickerSheet(deadline: $viewModel.selectedDeadline)
        }
    }
}

// MARK: - Deadline Picker Sheet

struct DeadlinePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var deadline: Date
    
    private var minDate: Date { Date() }
    private var maxDate: Date { Date().addingTimeInterval(24 * 60 * 60) } // +24h
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Until when?")
                    .font(.system(size: 20, weight: .bold))
                
                DatePicker(
                    "",
                    selection: $deadline,
                    in: minDate...maxDate,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
