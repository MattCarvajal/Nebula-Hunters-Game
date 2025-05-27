//
//  gameMenu.swift
//  Nebula Hunters Game
//
//  Created by Matt Carvajal on 5/26/25.
//

import SwiftUI
import SpriteKit

struct GameMenuView: View {
    @State private var play = false // var that keeps track is user is playing
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack{
                    Text("Nebula Hunters")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Play button
                    Button("Play"){
                        play = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .fullScreenCover(isPresented: $play) {
                    GameViewContainer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force stacking to prevent sidebar issue
        
    }
}



struct GameMenuView_Previews: PreviewProvider {
    static var previews: some View {
        GameMenuView()
    }
}
