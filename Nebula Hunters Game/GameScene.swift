//
//  GameScene.swift
//  Nebula Hunters Game
//
//  Created by Matt Carvajal on 5/12/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    // Joystick nodes
    var joystickBase: SKSpriteNode!
    var joystickStick:SKSpriteNode!
    var isTouchingJoystick:Bool = false // Check to see if the stick is touched
    var isIdle:Bool = false
    
    // Player node
    var player: SKSpriteNode!
    
    // Direction var
    var currentDirection: String = ""
    
    // Movement vector for smooth movement
    var movementVector = CGVector(dx: 0, dy: 0)
    
    // Sprite frames to load namespace for animation
    func loadAnimationFrames(baseName: String, count: Int) -> [SKTexture] {
        var frames: [SKTexture] = []
        for i in 0..<count {
            let frameName = String(format: "\(baseName)%02d", i)
            frames.append(SKTexture(imageNamed: frameName))
        }
        return frames
    }
    
    // Animate sprite function that takes in a direction that controls sprite direction animation
    func animatePlayer(direction: String) {
        // Only animate if the direction changed or animation isn't running
        if currentDirection != direction || player.action(forKey: "walking") == nil {
           
            currentDirection = direction // Store new direction (prevents animation from restarting
            var frames: [SKTexture] = [] // Empty animation array
            isIdle = false
            player.removeAction(forKey: "idle")
           
            // For loop that cycles through images to animate direction movement
            for i in 0..<9 {
                let frameName = String(format: "%@%02d", direction, i)
                frames.append(SKTexture(imageNamed: frameName))
               
                print("Loading frame: \(frameName)") // Tester

            }

            // Takes the frames array and animates it with 0.1 sec in between sprites
            let animation = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: 0.1))
            player.run(animation, withKey: "walking") // Starts the animation for the player obj
            
            
        }
    }
    
    func animateIdle(){
        var frames: [SKTexture] = [] // Animation array
        for i in 0..<2{
            let frameName = String(format: "idle%02d", i)
            frames.append(SKTexture(imageNamed: frameName))
            
            print("Loading frame: \(frameName)") // Tester

        }
        let animation = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: 0.5))
        player.run(animation, withKey: "idle")
        isIdle = true
        
    }

    // DidMove method to add sprites to our scene
    override func didMove(to view: SKView) {
        
        // === CAMERA SETUP
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
        
        // == MAP SETUP ==
        // Check for map
        guard let map = childNode(withName: "Map") as? SKSpriteNode else {
            fatalError("❗️ Map node not found in scene")
        }
        
        // Set up map border
        if let map = childNode(withName: "Map")as? SKSpriteNode {
            let boarder = SKPhysicsBody(edgeLoopFrom: map.frame)
            boarder.isDynamic = false
            map.physicsBody = boarder
        }
        
        // === PLAYER SETUP ===
        player = SKSpriteNode(imageNamed: "forward00")
        //player.position = map.position
        //player.position = CGPoint(x: map.position.x, y: map.position.y) // center in map
        // Spawn point for this map
        if let spawn = childNode(withName: "SpawnPoint") {
            player.position = spawn.position
            camera?.position = player.position
        }
        
        player.zPosition = 5
        addChild(player)
        animateIdle()
        
        print("Map Frame: \(map.frame)")
        print("Player Pos: \(player.position)")

        
        // === ADD PHYSICS BODY TO PLAYER ===
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.allowsRotation = false

        player.physicsBody?.categoryBitMask = 0x1 << 1       // player
        player.physicsBody?.collisionBitMask = 0xFFFFFFFF     // collide with everything
        player.physicsBody?.contactTestBitMask = 0            // (optional, for events)

        
        // === JOYSTICK SETUP
        
        // Assign sprite images to the joystick base and stick
        joystickBase = SKSpriteNode(imageNamed: "JS_Circle")
        joystickStick = SKSpriteNode(imageNamed: "JS_Ball")
        
        joystickBase.position = CGPoint(x: -self.size.width / 2 + 100, y: -self.size.height / 2 + 100) // Places JS in bottom right of the screen
        joystickStick.position = joystickBase.position // Stick starts in the center
        
        // Ensures the stick is drawn on top of the base.
        joystickBase.zPosition = 10
        joystickStick.zPosition = 11
        
        joystickBase.setScale(0.2)  // 20% of original size
        joystickStick.setScale(0.1)
        
        // Adds joystick parts to the scene to make them visable
        cameraNode.addChild(joystickBase)
        cameraNode.addChild(joystickStick)
        
        
    }
    
    
    // What happens when touches begin
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first{
            let location = touch.location(in: camera!)
            if joystickBase.contains(location){
                isTouchingJoystick = true // Change status of true if touched
                isIdle = false
            }
        }
        
    }
    
    // When touches are moved function
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchingJoystick, let touch = touches.first else { return }

        let location = touch.location(in: camera!)

        let dx = location.x - joystickBase.position.x
        let dy = location.y - joystickBase.position.y
        let distance = sqrt(dx * dx + dy * dy)
        let maxDistance: CGFloat = 50
        let angle = atan2(dy, dx)

        // Clamp joystick stick position to radius
        if distance > maxDistance {
            joystickStick.position = CGPoint(
                x: joystickBase.position.x + cos(angle) * maxDistance,
                y: joystickBase.position.y + sin(angle) * maxDistance
            )
        } else {
            joystickStick.position = location
        }

        // Used for constant speed
        if distance > 0 {
            // Normalize direction for consistent speed
            let normalizedDx = dx / distance
            let normalizedDy = dy / distance
            movementVector = CGVector(dx: normalizedDx, dy: normalizedDy)
        } else {
            movementVector = .zero
        }

        // Determine animation direction (8 frames per direction)
        var direction = ""
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? "right" : "left"
        } else {
            direction = dy > 0 ? "backwards" : "forward"
        }

        animatePlayer(direction: direction)
    }

    // When touches end
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouchingJoystick = false
        joystickStick.position = joystickBase.position
        movementVector = .zero
        player.removeAction(forKey: "walking")
        currentDirection = ""
        
        animateIdle() // Run idle animation
    }

    
    // What updates after every frame
    override func update(_ currentTime: TimeInterval) {
        let moveSpeed: CGFloat = 100.0
        
        if let body = player.physicsBody {
                body.velocity = CGVector(dx: movementVector.dx * moveSpeed,
                                         dy: movementVector.dy * moveSpeed)
            }
        
        // Make the camera follow the player
        camera?.position = player.position
    }
    
}
