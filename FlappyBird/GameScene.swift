//
//  GameScene.swift
//  FlappyBird
//
//  Created by ken on 2017/07/31.
//  Copyright © 2017年 ken. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var sakeNode:SKNode!
    var bird:SKSpriteNode!
    var sake:SKSpriteNode!
    
    // 壁と酒の移動スピードや位置関係を同期させる用
    var movingDistance:CGFloat!
    var wallTexture:SKTexture!
    var under_wall_y:CGFloat!
    var slit_length:CGFloat!
    
    //　酒の出現ランダマイズ用
    //var sakeAppear:TimeInterval!
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory:UInt32 = 1 << 2        // 0...00100
    let scoreCategory:UInt32 = 1 << 3       // 0...01000
    let sakeCategory:UInt32 = 1 << 4        // 0...10000
    
    // スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var sakeLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    //酒関連
    var drink = 0
    var timer:Timer!
    var timer_sec:Float = 0
    var slit:CGFloat = 4
    
    //音声
    let hiccupSound = SKAction.playSoundFileNamed("hiccup.mp3", waitForCompletion: false)
    let punchSound = SKAction.playSoundFileNamed("punch.mp3", waitForCompletion: true)
    let snoreSound = SKAction.playSoundFileNamed("snore.mp3", waitForCompletion: false)
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3)
        physicsWorld.contactDelegate = self

        backgroundColor = UIColor(colorLiteralRed:0.15,green:0.75,blue:0.9,alpha:1)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(drunken), userInfo: nil, repeats: true)
        
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        sakeNode = SKNode()
        scrollNode.addChild(sakeNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupSake()
        
        setUpScoreLabel()
    }
    
    //鳥が酔っ払ってる挙動
    func drunken(){
        timer_sec += 1
        if drink == 0{
            return
        }else{
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            let random:Int = Int(arc4random_uniform(UInt32(UInt(3))))
            if random == 2{
                if drink <= 10{
                    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: drink))
                }else{
                    bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
                }
            }else{
                if random == 0{
                    if drink <= 10{
                        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -2 * drink))
                    }else{
                        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -20))
                    }
                return
                }
            }
        }
    }
    
    func setUpScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score\(score)"
        self.addChild(scoreLabelNode)
        
        drink = 0
        sakeLabelNode = SKLabelNode()
        sakeLabelNode.fontColor = UIColor.black
        sakeLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        sakeLabelNode.zPosition = 100
        sakeLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        sakeLabelNode.text = "Sake\(drink)"
        self.addChild(sakeLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score\(bestScore)"
        self.addChild(bestScoreLabelNode)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            bird.position.x = self.frame.size.width * 0.2
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
            
        }else if bird.speed == 0 {
            restart()
        }
    }

    
    func restart(){
        score = 0
        drink = 0
        slit = 4
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(drunken), userInfo: nil, repeats: true)
        scoreLabelNode.text = String("Score\(score)")
        sakeLabelNode.text = "Sake\(drink)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.colorBlendFactor = CGFloat(0.1 * Double(drink))
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | sakeCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | sakeCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        sakeNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            //bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | sakeCategory
            //bird.physicsBody?.contactTestBitMask = 0
            //let wait = SKAction.wait(forDuration: 2)
            //self.bird.run(SKAction.repeatForever(SKAction.sequence([wait, self.snoreSound])))
            return
        }
        
        if(contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory{
            // スコア用の物体と衝突した
            score += Int(1 + 1 * drink)
            scoreLabelNode.text = "Score\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            
            // ベストスコア更新か確認する
            if score > bestScore{
                bestScore = score
                bestScoreLabelNode.text = "Best Score\(bestScore)"
                userDefaults.set(bestScore, forKey:"BEST")
                userDefaults.synchronize()
            }
            
        }else{
            // 酒を飲んだ
            if(contact.bodyA.categoryBitMask & sakeCategory) == sakeCategory || (contact.bodyB.categoryBitMask & sakeCategory) == sakeCategory{
                drink += 1
                sakeLabelNode.text = "Sake\(drink)"
                self.sake.removeFromParent()
                self.bird.run(hiccupSound)
                if drink <= 10{
                    self.bird.colorBlendFactor = CGFloat(0.1 * Double(drink))
                    self.bird.color = UIColor.red
                }else{
                    self.bird.colorBlendFactor = CGFloat(1.0)
                    self.bird.color = UIColor.red
                }

            }else{
                // 壁か地面と衝突した
                print("GameOver")
                bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | sakeCategory
                bird.physicsBody?.contactTestBitMask = 0
                scrollNode.speed = 0
                self.bird.run(punchSound)
            
                bird.physicsBody?.collisionBitMask = groundCategory
                timer.invalidate()
                timer = nil
                let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
                bird.run(roll, completion:{
                    self.bird.speed = 0
                })
            }
        }
    }
    
    func setupGround(){
        
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // 必要な枚数を計算
        let needGroundNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width,y: 0,duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        // groundのスプライトを配置する
        stride(from: 0.0, to: needGroundNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.zPosition = 0.0
            
            // スプライトを表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
        
    func setupCloud(){
            
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
            
        // 必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
            
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width,y: 0,duration: 20.0)
            
        // 元の位置に戻すアクション
        let resetCloud  = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
            
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollCloud  = SKAction.repeatForever(SKAction.sequence([moveCloud ,resetCloud ]))
            
        // cloudのスプライトを配置する
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach { i in
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
                
            // スプライトを表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
                
            // スプライトにアクションを設定する
            sprite.run(repeatScrollCloud )
                
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupWall(){
        // 壁の下ごしらえ
        wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.linear
        
        movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        let move = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        let remove = SKAction.removeFromParent()
        let wallAnimation = SKAction.sequence([move, remove])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + self.wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0
            
            // 壁の座標関連
            let center_y = self.frame.size.height / 2
            let random_y_range = self.frame.size.height / 3
            let under_wall_lowest_y = UInt32( center_y - self.wallTexture.size().height / 2 - random_y_range / 2)
            let random_y = arc4random_uniform(UInt32(random_y_range))
            self.under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            if self.drink >= 0{
                self.slit = 4
            }
            if self.drink >= 2{
            self.slit = 3
            }
            if self.drink >= 5{
            self.slit = 2
            }
            self.slit_length = self.frame.size.height / self.slit
            
            // 下側の壁
            let under = SKSpriteNode(texture: self.wallTexture)
            under.position = CGPoint(x: 0.0, y: self.under_wall_y)
            wall.addChild(under)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: self.wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            // 上側の壁
            let upper = SKSpriteNode(texture: self.wallTexture)
            upper.position = CGPoint(x: 0.0, y: self.under_wall_y + self.wallTexture.size().height + self.slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: self.wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            // 衝突の時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            wall.addChild(upper)
            
            // スコアアップ用のノード
            let scoreNode = SKSpriteNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.size.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.size = CGSize(width: upper.size.width, height: self.frame.size.height)
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            
            wall.addChild(scoreNode)
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupSake(){
        let sakeTexture = SKTexture(imageNamed: "sake")
        sakeTexture.filteringMode = SKTextureFilteringMode.linear
        
        let move = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        let remove = SKAction.removeFromParent()
        let sakeAnimation = SKAction.sequence([move, remove])
        
        let createSakeAnimation = SKAction.run({
            self.sake = SKSpriteNode(texture: sakeTexture)
            self.sake.physicsBody = SKPhysicsBody(rectangleOf: sakeTexture.size())
            self.sake.physicsBody?.categoryBitMask = self.sakeCategory
            self.sake.physicsBody?.isDynamic = false
            
            let random = CGFloat(arc4random_uniform(UInt32(100)))
            let sake_y = CGFloat(self.under_wall_y + self.wallTexture.size().height / 2 +  self.slit_length * (1 + random/100) / 2)
            self.sake.position = CGPoint(x: self.frame.size.width + self.wallTexture.size().width / 2, y: sake_y)
            self.sake.run(sakeAnimation)
            self.sakeNode.addChild(self.sake)
        })
        
        let wait1 = SKAction.wait(forDuration: 1)
        let wait2 = SKAction.wait(forDuration: 3)
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([wait1, createSakeAnimation,wait2]))
        sakeNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)

        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | sakeCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | sakeCategory
        
        bird.run(flap)
        addChild(bird)
    }
}
