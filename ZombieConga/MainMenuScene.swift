//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Joe Harasz on 2/6/18.
//  Copyright © 2018 JJH. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        let background: SKSpriteNode = SKSpriteNode(imageNamed: "MainMenu")
        
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let myScene = GameScene(size: self.size)
        myScene.scaleMode = self.scaleMode
        let reveal = SKTransition.doorway(withDuration: 1.5)
        self.view?.presentScene(myScene, transition: reveal)
    }
    
}
