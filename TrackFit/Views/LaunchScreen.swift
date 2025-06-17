//
//  LaunchScreen.swift
//  TrackFit
//
//  Created by Ryuga on 2025/06/16.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var isLaunching = true

    var body: some View {
        if isLaunching {
            ZStack {
                Color(red: 242 / 255, green: 137 / 255, blue: 58 / 255)
                    .ignoresSafeArea()

                VStack(spacing: 15) {
                    Image("TrackFItIconFilledWhite")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)

                    Text("TrackFit")
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                }
                .foregroundStyle(Color.white)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isLaunching = false
                    }
                }
            }
        } else {
            ContentView()
        }
    }
}

#Preview {
    LaunchScreen()
}
