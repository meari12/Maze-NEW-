//
//  ViewController.swift
//  Maze
//
//  Created by Meri Sato on 2022/05/11.
//

import UIKit
//CMMotionManager(加速度センサーに関するもの)を使うための設定
import CoreMotion
import AVFoundation

class ViewController: UIViewController {
    
    static var bgmPlayer: AVAudioPlayer?
    
    static func playBGM(fileName: String) {
        if let soundFilePath = Bundle.main.path(forResource: fileName, ofType: "mp3") {
            if let audiPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: soundFilePath), fileTypeHint: nil) {
                audiPlayer.numberOfLoops = -1
                audiPlayer.prepareToPlay()
                bgmPlayer = audiPlayer
            }
        }
        bgmPlayer?.play()
    }
    
    static func stopBGM() {
        bgmPlayer?.stop()
    }
    
    //プレイヤーを表す
    var playerView: UIImageView!
    //iPhoneの動きを感知する
    var playerMotionManager: CMMotionManager!
    //プレイヤーが動く速さ
    var speedX: Double = 0.0
    var speedY: Double = 0.0
    
    //画面サイズの取得
    let screenSize = UIScreen.main.bounds.size
    
    //迷路マップを表した配列
    let maze = [
    [1, 0, 0, 0, 1, 0],
    [1, 0, 1, 0, 1, 0],
    [3, 0, 1, 0, 1, 0],
    [1, 1, 1, 0, 0, 0],
    [1, 0, 0, 1, 1, 0],
    [0, 0, 1, 0, 0, 0],
    [0, 1, 1, 0, 1, 0],
    [0, 0, 0, 0, 1, 1],
    [0, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 2],
    ]
    
    //スタートとゴールを表すUIView
    var startView: UIView!
    var goalView: UIView!
    
    //WallViewのフレームの情報を入れておく配列
    var wallRectArray = [CGRect]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //マップ１マスの幅
        let cellWidth = screenSize.width / CGFloat(maze[0].count)
        //マップ１マスの高さ
        let cellHeight = screenSize.height / CGFloat(maze.count)
        //マスの左上とマスの中心のx座標の差
        let celloffsetX = cellWidth / 2
        //マスの左上とますの中心のy座標の差
        let celloffsetY = cellHeight / 2
        
        for y in 0 ..< maze.count {
            for x in 0 ..< maze[y].count {
                switch maze[y][x] {
                case 1://当たるとゲームオーバーになるマス
                    let wallView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: celloffsetX, offsetY: celloffsetY)
                    wallView.backgroundColor = UIColor.black
                    view.addSubview(wallView)
                    wallRectArray.append(wallView.frame)
                case 2://スタート地点
                    startView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: celloffsetX, offsetY: celloffsetY)
                    startView.backgroundColor = UIColor.green
                    view.addSubview(startView)
                case 3://ゴール地点
                    goalView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: celloffsetX, offsetY: celloffsetY)
                    goalView.backgroundColor = UIColor.red
                    view.addSubview(goalView)
                default:
                    break
                    
                }
            }
        }
        
        //playerViewを生成
        playerView = UIImageView(frame: CGRect(x: 0, y: 0, width: cellWidth / 6, height: cellHeight / 6)) //playerの幅・高さは、マップ１マスの1/6
        playerView.center = startView.center
        playerView.image = UIImage(named: "主人公.jpeg")
        view.addSubview(playerView)
        
        //MotionManagerを生成 加速度の値を0.02秒ごとに取得する
        playerMotionManager = CMMotionManager()
        playerMotionManager.accelerometerUpdateInterval = 0.02
        
        startAccelerometer()
        
    }
    
    func createView(x: Int, y: Int, width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> UIView{
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let view = UIView(frame: rect)
        
        let center = CGPoint(x: offsetX + width * CGFloat(x), y: offsetY + height * CGFloat(y))
        
        view.center = center
        
        return view
    }
    
    func startAccelerometer() {
        
        //加速度を取得する
        let handler: CMAccelerometerHandler = {(CMAccelerometerData: CMAccelerometerData?, error: Error?) -> Void in
            self.speedX += CMAccelerometerData!.acceleration.x
            self.speedY += CMAccelerometerData!.acceleration.y
            
            //プレイヤーの中心位置を設定
            var posX = self.playerView.center.x + (CGFloat(self.speedX) / 3)
            var posY = self.playerView.center.y - (CGFloat(self.speedY) / 3)
            
            //画面上からプレイヤーがはみ出しそうだったら、posX/posYを修正
            if posX <= self.playerView.frame.width / 2 {
                self.speedX = 0
                posX = self.playerView.frame.width / 2
            }
            if posY <= self.playerView.frame.height / 2 {
                self.speedY = 0
                posY = self.playerView.frame.height / 2
            }
            if posX >= self.screenSize.width - (self.playerView.frame.width / 2) {
                self.speedX = 0
                posX = self.screenSize.width - (self.playerView.frame.width / 2)
            }
            if posY >= self.screenSize.height - (self.playerView.frame.height / 2) {
                self.speedY = 0
                posY = self.screenSize.height - (self.playerView.frame.height / 2)
            }
            
            //playerViewとwallViewがあたっているかどうかの判定
            for wallRect in self.wallRectArray{
                if wallRect.intersects(self.playerView.frame) {
                    self.gameCheck(result: "gameover", message: "壁に当たりました")
                    return

                }
            }
            
            //playerViewとgoalViewがあたっているかどうかの判定
            if self.goalView.frame.intersects(self.playerView.frame) {
                self.gameCheck(result: "clear", message: "クリアしました！")
                return
            }
            
            self.playerView.center = CGPoint(x: posX, y: posY)
            
        }
        //加速度の開始
        playerMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
        
    }
        
        //ゲームクリア・ゲームオーバー時にアラートを表示し、リトライできるようにしよう！
        func gameCheck(result: String, message: String){
            //加速度止める
            if playerMotionManager.isAccelerometerActive {
                playerMotionManager.stopAccelerometerUpdates()
            }
            
            let gameCheckAlert: UIAlertController = UIAlertController(title: result, message: message, preferredStyle: .alert)
            
            let retryAction = UIAlertAction(title: "もう一度", style: .default, handler: {
                (action: UIAlertAction!) -> Void in
                self.retry()
            })
            
            gameCheckAlert.addAction(retryAction)
            
            self.present(gameCheckAlert, animated: true, completion: nil)
            
            
        }
        
        func retry() {
            //プレイヤーの位置を初期化
            playerView.center = startView.center
            //加速度センサーを始める
            if !playerMotionManager.isAccelerometerActive {
                self.startAccelerometer()
            }
            //スピードを初期化
            speedX = 0.0
            speedY = 0.0
        }
    
    //BGMの再生
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ViewController.playBGM(fileName: "music")
    }
    //BGMの停止
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ViewController.stopBGM()
    }
    }
        
    
    



