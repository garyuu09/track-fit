//
//  TopView.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/18.
//

import SwiftUI

struct TopView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("TopView")
            }
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    TopView()
}
