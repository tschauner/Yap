//
//  AgentListView.swift
//  Yap
//
//  Created by Philipp Tschauner on 09.03.26.
//

import SwiftUI

struct AgentListView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var packStore: AgentPackStore
    var cardNamespace: Namespace.ID
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center) {
                ForEach(viewModel.orderAgentList(packStore: packStore)) { agent in
                    if viewModel.selectedAgent != agent {
                        AgentCard(agent: agent)
                            .matchedGeometryEffect(id: agent.id, in: cardNamespace)
                            .onTapGesture {
                                viewModel.selectedAgent = nil
                                withAnimation(.snappy(extraBounce: 0.1)) {
                                    viewModel.selectedAgent = agent
                                }
                        }
                    }
                }
                .scrollTargetLayout()
            }
        }
    }
}
