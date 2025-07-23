//
//  GameViewContainer.swift
//  Nebula Hunters Game
//
//  Created by Matt Carvajal on 5/27/25.
//
// This file is going to be used to help switch between different scenes

import SwiftUI
import SpriteKit

struct GameViewContainer: View {
    var scene: SKScene{
        guard let scene = SKScene(fileNamed: "GameScene.sks") as? GameScene else{
           fatalError( "Unable to load GameScene.sks")
        }
        
        scene.scaleMode = .resizeFill
        return scene
    }
        
    var body: some View {
            SpriteView(
                scene: scene,
                debugOptions: [
                  .showsFPS,
                  .showsPhysics
                ]
            )
            .ignoresSafeArea()
    }

}

