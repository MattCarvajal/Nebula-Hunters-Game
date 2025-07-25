//
//  GameScene.swift
//  Nebula Hunters Game
//
//  Created by Matt Carvajal on 5/12/25.
//

import SpriteKit
import GameplayKit
import SKTiled


class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    var tilemap: SKTilemap?
    
    // Joystick nodes
    var joystickBase: SKSpriteNode!
    var joystickStick:SKSpriteNode!
    var isTouchingJoystick:Bool = false // Check to see if the stick is touched
    var isIdle:Bool = false
    
    // Player node
    var player: SKSpriteNode!
    
    // Enemy node
    var enemy: SKSpriteNode!
    
    // Direction var
    var currentDirection: String = ""
    
    // Movement vector for smooth movement
    var movementVector = CGVector(dx: 0, dy: 0)
    
    // Physics stuff
    struct PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let wall: UInt32   = 0x1 << 1
    }
    
    
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
    
    func animateIdle(character: String){
        var frames: [SKTexture] = [] // Animation array
        for i in 0..<2{
            let frameName = String(format: character+"Idle%02d", i)
            frames.append(SKTexture(imageNamed: frameName))
            
            print("Loading frame: \(frameName)") // Tester

        }
        let animation = SKAction.repeatForever(SKAction.animate(with: frames, timePerFrame: 0.5))
        
        // Where we decide who to animate
        if (character == "player"){
            player.run(animation, withKey: "Idle")
        } else if (character == "enemy"){
            enemy.run(animation, withKey: "Idle")
        }

        isIdle = true
        
    }

    // DidMove method to add sprites to our scene
    override func didMove(to view: SKView) {
        
        // === CAMERA SETUP
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        addChild(cameraNode)
        
        // == MAP SETUP ==
        // TMX CHECKER FOR MAP TO MAKE SURE IT EXISTS
        if let path = Bundle.main.path(forResource: "Sci-fi_Map", ofType: "tmx") {
            print("✅ TMX path: \(path)")
        } else {
            print("❌ TMX file not found in bundle!")
        }
        
        // LOAD MAP
        if let tilemap = SKTilemap.load(tmxFile: "Sci-fi_Map"){
            tilemap.zPosition = -1 // Puts the map behind character and the JS
            tilemap.setScale(3.0) // Scale of the map to adjust size
            tilemap.position = CGPoint(x: 0, y: 0) // set position to origin
            
            // For each layer, set z position to -1 (debug issue of player behind map)
            for layer in tilemap.layers{
                layer.zPosition = -1
                
            }
            
            addChild(tilemap)
            self.tilemap = tilemap
            
            // Wall physics
            if let wallLayer = tilemap.tileLayers(named: "Walls").first {
                let tileSize = tilemap.tileSize
                let mapSize  = tilemap.size

                for y in 0..<Int(mapSize.height) {
                    for x in 0..<Int(mapSize.width) {
                        // only place a body where there's actually a tile
                        if wallLayer.tileAt(x, y) != nil {
                            
                            // bottom-left corner of the tile in layer coords
                            let rawPos = wallLayer.pointForCoordinate(x, y)
                            
                            let centerPos = CGPoint(
                                x: rawPos.x + tileSize.width * 0.15,
                                y: rawPos.y + tileSize.height * 0.15
                            )
                            
                            // make your empty node at that center point
                            let wallNode = SKNode()
                            wallNode.position = centerPos
                            
                            // give it a physics body the same size as one tile
                            let body = SKPhysicsBody(rectangleOf: tileSize)
                            body.isDynamic           = false
                            body.categoryBitMask     = PhysicsCategory.wall
                            body.contactTestBitMask  = PhysicsCategory.player
                            wallNode.physicsBody     = body
                            
                            //add into the layer so it picks up the map’s transform
                            wallLayer.addChild(wallNode)
                        }
                    }
                }
            }
            
        } else {
            print("Failed to load map")
            
        }
        
        
//        // Map boarder setup
//        if let tilemap = self.tilemap{
//           // Manually make boarder due to top being open when calculating accumulated frame
//            let width = CGFloat(tilemap.size.width) * tilemap.tileSize.width * tilemap.xScale
//            let height = CGFloat(tilemap.size.height) * tilemap.tileSize.height * tilemap.yScale
//            let origin = CGPoint(x: tilemap.position.x - width / 2, y: tilemap.position.y - height / 2)
//            
//            // Define rectangle to make boarder with
//            let mapRect = CGRect(origin: origin, size: CGSize(width: width, height: height))
//            
//            // Define boarder
//            let boarder = SKPhysicsBody(edgeLoopFrom: mapRect)
//            boarder.isDynamic = false
//            boarder.friction = 0
//            tilemap.physicsBody = boarder
//            
//            print("Boarder applied to map ✅ ")
//        }
        
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
        animateIdle(character: "player")
        
        //print("Map Frame: \(tilemap.frame)")
        print("Player Pos: \(player.position)")

        
        // === ADD PHYSICS BODY TO PLAYER ===
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size) // might want to change this for more percise hitbox
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.allowsRotation = false

        player.physicsBody?.categoryBitMask = 0x1 << 1       // player
        player.physicsBody?.collisionBitMask = 0xFFFFFFFF     // collide with everything
        player.physicsBody?.contactTestBitMask = 0            // (optional, for events)

        // === ENEMY SETUP ===
        enemy = SKSpriteNode(imageNamed: "enemyIdle00")
        //player.position = map.position
        //player.position = CGPoint(x: map.position.x, y: map.position.y) // center in map
        // Spawn point for this map
        if let enemySpawn = childNode(withName: "EnemySpawnPoint") {
            enemy.position = enemySpawn.position
           
        }
        
        enemy.zPosition = 5
        addChild(enemy)
        animateIdle(character: "enemy")
        
        //print("Map Frame: \(tilemap.frame)")
        print("Enemy Pos: \(enemy.position)")

        
        // === ADD PHYSICS BODY TO PLAYER ===
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size) // might want to change this for more percise hitbox
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.allowsRotation = false

        enemy.physicsBody?.categoryBitMask = 0x1 << 1       // enemy
        enemy.physicsBody?.collisionBitMask = 0xFFFFFFFF     // collide with everything
        enemy.physicsBody?.contactTestBitMask = 0            // (optional, for events)

        
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
        
        animateIdle(character: "player") // Run idle animation
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
