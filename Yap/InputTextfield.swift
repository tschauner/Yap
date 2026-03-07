//
//  InputTextfield.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

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
        VStack(alignment: .leading, spacing: 20) {
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
                .onTapGesture {
                    viewModel.selectedMission = .init(title: missionText)
                }
                
                Spacer()
            }
            
            // Input Row
            HStack(spacing: 15) {
                TextField("", text: $viewModel.missionText, prompt: Text("What needs to get done?"))
                    .focused($isFocused)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 19, weight: .medium))
                
//                Image(icon: .clock)
//                    .font(.system(size: 20, weight: .semibold))
//                    .onTapGesture {
//                        showDeadlinePicker = true
//                    }
//                    .hidden()
                
                
                if let selectedAgent = viewModel.selectedAgent {
                    Image(icon: .paperplane)
                        .font(.system(size: 20, weight: .semibold))
                        .onTapGesture {
                            Task {
                                await viewModel.selectAgent(selectedAgent, title: missionText)
                            }
                        }
                }
            }
        }
        .onAppear { isFocused = true }
        .animation(.snappy(duration: 0.3), value: missionText.isEmpty)
        .onChange(of: isFocused) { oldValue, newValue in
            viewModel.isFocused = isFocused
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
