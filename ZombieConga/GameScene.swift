//
//  GameScene.swift
//  ZombieConga
//
//  Created by Joe Harasz on 11/6/17.
//  Copyright © 2017 JJH. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint(x: 0, y: 0)
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    var isZombieInvincible = false
    var catsMovePointsPerSecond = CGFloat(480.0)
    var lives = 3
    var gameOver = false
    let backgroundMovePointsPerSec: CGFloat = 200.0
    
    //preloads the sounds so no lag
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        //dont need self here
        backgroundColor = SKColor.white;
        
        //old background code
        /*
        let background = SKSpriteNode(imageNamed: "background1")
        //background.position = CGPoint(x: size.width/2, y: size.height/2)
        
        //anchor point changes where the image "pin" or anchor is
        //background.anchorPoint = CGPoint(x: 0, y: 0)
        //background.position = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) // default
        //background.zRotation = CGFloat(M_PI) / 8
        
        //this will draw before anything else
        background.zPosition = -1
        
        let mySize = background.size
        //print("Size: \(mySize)");
        
        addChild(background)
        */
        
        let background = backgroundNode()
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.position = CGPoint(x: 0, y: 0)
        background.name = "background"
        addChild(background)
        
        zombie.position = CGPoint(x: 400, y: 400)
        //zombie.setScale(2);
        zombie.zPosition = 100
        
        addChild(zombie)
        
        //zombie.run(SKAction.repeatForever(zombieAnimation))
        
        //inline actions
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnEnemy), SKAction.wait(forDuration: 2.0)])))
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnCat), SKAction.wait(forDuration: 1.0)])))
        //debugDrawPlayableArea()
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        //print("\(dt*1000) milliseconds since last update")
        
        //zombie.position = CGPoint(x: zombie.position.x + 4, y: zombie.position.y)
        
        if let lastTouch = lastTouchLocation {
            let diff = lastTouch - zombie.position
            if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
                zombie.position = lastTouchLocation!
                velocity = CGPoint(x: 0, y: 0)
                stopZombieAnimation()
            } else {
                moveSprite(sprite: zombie, velocity: velocity)
                let shortest = shortestAngleBetween(angle1: zombie.position.angle, angle2: velocity.angle)
                var amtToRotate =
                rotateSprite(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            }
        }
        boundsCheckZombie()
        //checkCollisions()
        moveTrain()
        moveBackground()
        
        if (lives <= 0 && !gameOver) {
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
            
            //1
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            //2
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            //3
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    //removes collison detection delay
    //Performs any scene-specific updates that need to occur after scene actions are evaluated
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        //1
        let amountToMove = velocity * CGFloat(dt)
        
        print("Amount to move: \(amountToMove)")
        //2
//        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
//                                  y: sprite.position.y + amountToMove.y)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length),
                                y: offset.y / CGFloat(length))
        velocity = direction * zombieMovePointsPerSec
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(location: touchLocation)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        //1
        var textures: [SKTexture] = []
        //2
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        //3
        textures.append(textures[2])
        textures.append(textures[1])
        //4
        //make sure that you animate the textures the correct way (normal textures is not the same thing as the method call below)
        zombieAnimation = SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: 0.1))
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        //below is replacement for above
        
        //CGPathAddRect(path, nil , playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    /*
    func spawnEnemy() {
        
        //moveactions - moveTo / moveBy
        
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        //enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: size.height/2)
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(min: playableRect.maxY + enemy.size.height/2, max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        
        
        //let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 2.0)
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
        
        /*
        let actionMidMove = SKAction.moveBy(x: -size.width/2-enemy.size.width/2, y: -playableRect.height/2 + enemy.size.height/2, duration: 1.0)
        let actionMove = SKAction.moveBy(x: -size.width/2 - enemy.size.height/2, y: playableRect.height/2 - enemy.size.height/2, duration: 1.0)
        let wait = SKAction.wait(forDuration: 0.25)
        let logMessage = SKAction.run( {
            print("Reached bottom!")
        })
        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
        let sequence = SKAction.sequence([halfSequence, halfSequence.reversed()])
        //action can not be named repeat
        let repeatA = SKAction.repeatForever(sequence)
        enemy.run(repeatA) */
    } */
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(
            min: playableRect.minY + enemy.size.height/2,
            max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        
        let actionMove =
            SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    func spawnCat() {
        //1
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX, max: playableRect.maxX), y: CGFloat.random(min: playableRect.minY, max: playableRect.maxY))
        cat.setScale(0)
        addChild(cat)
        //2
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        let disappear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        //cat.removeFromParent()
        run(catCollisionSound)
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        
        //SKAction.colorize will change to color over time
        let greenAction = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        cat.run(greenAction)
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        isZombieInvincible = true
        //enemy.removeFromParent()
        run(enemyCollisionSound)
        loseCats()
        lives = lives - 1
        
        //make invincible
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                node.isHidden = remainder > slice / 2
        }
        let setHidden = SKAction.run {
            self.zombie.isHidden = false;
            self.isZombieInvincible = false
        }
        //have to run this on the zombie else the screen will blink
        //run(blinkAction)
        zombie.run(SKAction.sequence([blinkAction, setHidden]))
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { ( node, _) in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        
        for cat in hitCats {
            zombieHitCat(cat: cat)
        }
        
        if isZombieInvincible {
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        
        enumerateChildNodes(withName: "enemy") { (node, _) in
            let enemy = node as! SKSpriteNode
            //'CGRectInset' has been replaced by instance method 'CGRect.insetBy(dx:dy:)'
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                    hitEnemies.append(enemy)
                }
        }
        
        for enemy in hitEnemies {
            zombieHitEnemy(enemy: enemy)
        }
        
        //dont remove nodes while enumerating it can crash app
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        
        //movement is being weird and jittery - OVER IT
        
        enumerateChildNodes(withName: "train") { (node, _) in
            trainCount = trainCount + 1
            if !node.hasActions() {
                let actionDuration = 0.3
                //offset between cats current position and the target position
                let offset = targetPosition - node.position
                //vector unit pointing in the offset
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catsMovePointsPerSecond
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 5 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            
            //1
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            //2
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            //3
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats() {
        //1
        var loseCount = 0
        enumerateChildNodes(withName: "train") { (node, stop) in
            //2
            var randomSpot = node.position
            //used to calculate offset position to spin out and remove
            randomSpot.x = CGFloat.random(min: -100, max: 100)
            randomSpot.y = CGFloat.random(min: -100, max: 100)
            //3
            node.name = ""
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(byAngle: π*4, duration: 1.0),
                    SKAction.move(to: randomSpot, duration: 1.0),
                    SKAction.scale(to: 0, duration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
            //4
            loseCount = loseCount + 1
            if loseCount >= 2 {
                //memory renamed to pointee in swift
                stop.pointee = true
            }
        }
    }
    
    func backgroundNode() -> SKSpriteNode {
        //1
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundNode.name = "background"
        backgroundNode.zPosition = -1
        //2
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint(x: 0, y: 0)
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        //3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint(x: 0, y: 0)
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        //4
        backgroundNode.size = CGSize(width: background1.size.width + background2.size.width, height: background1.size.height)
        return backgroundNode
    }
    
    func moveBackground() {
        enumerateChildNodes(withName: "background") { (node, _) in
            let background = node as! SKSpriteNode
            let backgroundVelocity = CGPoint(x: -self.backgroundMovePointsPerSec, y: 0)
            let amountToMove = backgroundVelocity * CGFloat(self.dt)
            background.position += amountToMove
        }
    }
}
