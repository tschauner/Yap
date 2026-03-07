//
//  MissionBox.swift
//  Yap
//
//  Created by Philipp Tschauner on 05.03.26.
//

import SwiftUI

struct MissionBox: View {
    let mission: MissionItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(mission.title)
            
            Divider()
            
            HStack {
                Image(icon: .bell)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("2 messages scheduled")
                    .foregroundStyle(.secondary)
                    .redacted(reason: .placeholder)
            }
            
            HStack {
                Image(icon: .eye)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("2 messages ignored")
                    .foregroundStyle(.secondary)
                    .redacted(reason: .placeholder)
            }
            
            HStack {
                Image(icon: .clock)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                Text("mission.createdAt")
                    .foregroundStyle(.secondary)
                    .redacted(reason: .placeholder)
            }
        }
        .padding()
        .border(.primary)
    }
}

#Preview {
    MissionBox(mission: .init(title: "Wäsche waschen"))
}
