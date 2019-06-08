//
//  ViewController.swift
//  Loger
//
//  Created by MacBook Air on 2019/05/13.
//  Copyright © 2019 MacBook Air. All rights reserved.
//

import UIKit
import CoreMotion
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var underMeasuringLabel: UILabel!    // "計測中"と表示するラベル
    @IBOutlet weak var startSwitch: UISwitch!           // 計測を開始するスイッチ
    var isImmediatelyMode: Bool = true                   // すぐに計測するかどうか
    var isSessionMode: Bool = false                      // セッションモードかどうか
    
    // After 5 secモード用
    var startTime: Double = 0.0                         // タイマーのスタート時間
    var timer = Timer()                                 // タイマー
    
    let motionManager = CMMotionManager()   // MotionManager 表示用
    let motionLogger = MotionSensorLogger()     // センサデータ記録する
    
    @IBOutlet weak var targetLabelTextField: UITextField!   // targetのラベル入力
    @IBOutlet weak var userTextField: UITextField!          // userのラベル入力
    
    // センサデータ表示用ラベル
    @IBOutlet weak var accXLabel: UILabel!
    @IBOutlet weak var accYLabel: UILabel!
    @IBOutlet weak var accZLabel: UILabel!
    
    @IBOutlet weak var gyrXLabel: UILabel!
    @IBOutlet weak var gyrYLabel: UILabel!
    @IBOutlet weak var gyrZLabel: UILabel!
    
    @IBOutlet weak var magXLabel: UILabel!
    @IBOutlet weak var magYLabel: UILabel!
    @IBOutlet weak var magZLabel: UILabel!
    
    // バックグラウンド処理
    var backgroundTaskID: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 計測中かどうかを示すラベル
        self.underMeasuringLabel.text = ""
        
        // 計測表示用のラベルを初期化
        self.accXLabel.text = "0.00"
        self.accYLabel.text = "0.00"
        self.accZLabel.text = "0.00"
        self.gyrXLabel.text = "0.00"
        self.gyrYLabel.text = "0.00"
        self.gyrZLabel.text = "0.00"
        self.magXLabel.text = "0.0"
        self.magYLabel.text = "0.0"
        self.magZLabel.text = "0.0"
        
        
        // スイッチをOFFにしておく
        self.startSwitch.setOn(false, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    // 加速度センサの値を取得する
    private func setAccelerometerValue(_ freq: Double){
        
        if motionManager.isAccelerometerAvailable {
            // 加速度センサーの値取得間隔
            motionManager.accelerometerUpdateInterval = 1 / freq
            // motionの取得を開始
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                // 取得した値をコンソールに表示
                let x = data?.acceleration.x
                let y = data?.acceleration.y
                let z = data?.acceleration.z
                
                self.accXLabel.text = String(format: "%.2f", x!)
                self.accYLabel.text = String(format: "%.2f", y!)
                self.accZLabel.text = String(format: "%.2f", z!)
            })
        }
    }
    
    // ジャイロセンサ
    private func setGyroscopeValue(_ freq: Double) {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 1 / freq
            motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                let x = data?.rotationRate.x
                let y = data?.rotationRate.y
                let z = data?.rotationRate.z
                
                self.gyrXLabel.text = String(format: "%.2f", x!)
                self.gyrYLabel.text = String(format: "%.2f", y!)
                self.gyrZLabel.text = String(format: "%.2f", z!)
            })
        }
    }
    
    // 磁気センサ
    private func setMagnetometerValue(_ freq: Double) {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 1 / freq
            motionManager.startMagnetometerUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                let x = data?.magneticField.x
                let y = data?.magneticField.y
                let z = data?.magneticField.z
                
                self.magXLabel.text = String(format: "%.1f", x!)
                self.magYLabel.text = String(format: "%.1f", y!)
                self.magZLabel.text = String(format: "%.1f", z!)
                
            })
        }
    }
    
    // センサデータをラベルに表示する
    private func setSensorValue(_ freq: Double) {
        self.setAccelerometerValue(freq)
        self.setGyroscopeValue(freq)
        self.setMagnetometerValue(freq)
    }
    
    // センサデータの取得を停止
    func stopSensor() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }

        if motionManager.isMagnetometerActive {
            motionManager.stopMagnetometerUpdates()
        }

        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    // セッションモードの停止処理
    private func stopSession() {
        if self.startSwitch.isOn {
            // 1分後に停止させる
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                // スイッチをオフにする
                self.startSwitch.setOn(false, animated: true)
                self.switchChange(self.startSwitch)
                
                // 通知を出す
                self.putSessionFinishedNotification()
                
            }
        }

    }
    
    // アクティビティコントローラを表示する
    private func showActivityViewController() {
        /* ActivityViewControllerを表示 */
        let outputItem = self.motionLogger.getOutputDataURLs(label: self.targetLabelTextField.text!, user: self.userTextField.text!)
        let activityVc = UIActivityViewController(activityItems: outputItem, applicationActivities: nil)
        self.present(activityVc, animated: true, completion: {
            
        })
    }
    
    /*---スイッチとボタンの処理--------------------------------------*/
    // スイッチがONのとき
    @IBAction func switchChange(_ sender: UISwitch){
        if sender.isOn {
            var sec = 0.0
            if !self.isImmediatelyMode {
                sec = 5.0
                self.startTime = Date().timeIntervalSince1970
                self.underMeasuringLabel.text = "00:05"
                
                self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateLabel), userInfo: nil, repeats: true)
            }
            
            // sec秒後に処理する
            DispatchQueue.main.asyncAfter(deadline: .now() + sec) {
                self.underMeasuringLabel.text = "計測中"
                // 周波数を指定
                let freq = 50.0
                // 中断されたら困る処理の起点
                self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                // 計測開始
                self.motionLogger.startSensor(freq)
                self.setSensorValue(freq)
                // セッションモード
                if self.isSessionMode {
                    self.stopSession()
                }
            }
        }
        else {
            self.underMeasuringLabel.text = ""

            self.motionLogger.stopSensor()
            self.stopSensor()
          
            // 処理が終わったら
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
        }
    }
    
    // 保存ボタンが押されたとき
    @IBAction func buttonTouchDown(_ sender: Any) {
        
        if self.targetLabelTextField.text! != "" && self.userTextField.text! != "" {
            // 保存する
            self.showActivityViewController()
            // データのリセット
            self.motionLogger.resetOutputData()
            
            // TextFieldをクリアにする
            self.targetLabelTextField.text! = ""
            self.userTextField.text! = ""
        }
        else {
            // アラート
            let alert = UIAlertController(title: "保存できません", message: "LabelとUserを入力してください", preferredStyle: UIAlertController.Style.actionSheet)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action) in
                print("OK")
            }
            
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // キーボード以外をタップしたときにキーボードが下がるように
    @IBAction func tapScreen(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // segmented controlの値が変わったとき
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.isImmediatelyMode = true
        case 1:
            self.isImmediatelyMode = false
        default:
            self.isImmediatelyMode = true
        }
    }
    
    // セッションモードの切り替え
    @IBAction func valueChangedSession(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.isSessionMode = false
        case 1:
            self.isSessionMode = true
        default:
            self.isSessionMode = false
        }
    }
    
    // カウントダウンをする
    @objc func updateLabel() {
        let elapsedTime = Date().timeIntervalSince1970 - self.startTime
        let flooredErapsedTime = Int(floor(elapsedTime))
        let leftTime = 5 - flooredErapsedTime
        print(String(leftTime))
        self.underMeasuringLabel.text = String(format: "00:%02d", leftTime)
        
        if leftTime <= 0 {
            // タイマーを終了する
            self.timer.invalidate()
        }
    }
    
    /*--通知-----------------------------------------*/
    // フォアグラウンドでも通知を出す
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    // セッションの終了通知
    func putSessionFinishedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "セッションが終了しました"
        content.subtitle = "お疲れさまでした"
        content.body = ""
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "Timer", content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
}

