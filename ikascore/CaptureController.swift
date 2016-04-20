import UIKit
import AVFoundation
import Social

class CaptureController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var myComposeView : SLComposeViewController!

    // セッション.
    var mySession : AVCaptureSession!
    // デバイス.
    var myDevice : AVCaptureDevice!
    // 画像のアウトプット.
    var myOutput : AVCaptureVideoDataOutput!
    var imageView: UIImageView!
    
    // 顔検出オブジェクト
    let detector: Detector = Detector()
    
    var status: Bool = true
    var items: [NSString] = []
    
    let message: UIButton = UIButton()
    
    var scoreImage:UIImage!
    var scoreText:UILabel = UILabel()

    var winCount:NSInteger = 0
    var loseCount:NSInteger = 0


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if (initCamera()) {
            message.frame = CGRectMake(0,0,300,50)
            message.layer.masksToBounds = true
            message.setTitle("loading...", forState: .Normal)
            message.layer.cornerRadius = 5.0
            message.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height/2)
            message.hidden = true
            message.addTarget(self, action: #selector(restore), forControlEvents: .TouchUpInside)
            self.view.addSubview(message);

            UIApplication.sharedApplication().idleTimerDisabled = true
        } else {
            let errorMessage: UILabel = UILabel()
            errorMessage.frame = CGRectMake(0,0,300,50)
            errorMessage.backgroundColor = UIColor.redColor()
            errorMessage.textColor = UIColor.whiteColor()
            errorMessage.text = "カメラを有効にしてください。"
            errorMessage.textAlignment = NSTextAlignment.Center
            errorMessage.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height/2)
            self.view.addSubview(errorMessage);
        }

        let backBtn: UIButton = UIButton()
        backBtn.frame = CGRectMake(0,0,90,44)
        backBtn.layer.position = CGPoint(x: 60, y:30)
        backBtn.setTitle("もどる", forState: .Normal)
        backBtn.layer.masksToBounds = true
        backBtn.layer.cornerRadius = 5.0
        backBtn.backgroundColor = UIColor.whiteColor()
        backBtn.setTitleColor(UIColor.blackColor(), forState: .Normal)
        backBtn.addTarget(self, action: #selector(toTop), forControlEvents: .TouchUpInside)
        self.view.addSubview(backBtn);

        let tweetBtn: UIButton = UIButton()
        tweetBtn.frame = CGRectMake(0,0,90,44)
        tweetBtn.layer.position = CGPoint(x: self.view.bounds.width - tweetBtn.layer.bounds.width/2 - 10, y:30)
        tweetBtn.setTitle("Tweet", forState: .Normal)
        tweetBtn.layer.masksToBounds = true
        tweetBtn.layer.cornerRadius = 5.0
        tweetBtn.backgroundColor = UIColor(red: 59/255, green: 148/255, blue: 217/255, alpha: 1.0)
        tweetBtn.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        tweetBtn.addTarget(self, action: #selector(tweet), forControlEvents: .TouchUpInside)
        self.view.addSubview(tweetBtn);
    }
    
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        
        // 解像度の指定.
        mySession.sessionPreset = AVCaptureSessionPresetMedium
        
        
        // デバイス一覧の取得.
        let devices = AVCaptureDevice.devices()
        
        // バックカメラをmyDeviceに格納.
        for device in devices {
            if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        if myDevice == nil {
            return false
        }
        
        // バックカメラからVideoInputを取得.
        var myInput: AVCaptureDeviceInput! = nil
        do {
            myInput = try AVCaptureDeviceInput(device: myDevice) as AVCaptureDeviceInput
        } catch let error {
            print(error)
        }
        
        // セッションに追加.
        if mySession.canAddInput(myInput) {
            mySession.addInput(myInput)
        } else {
            return false
        }
        
        // 出力先を設定
        myOutput = AVCaptureVideoDataOutput()
        myOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) ]
        
        
        
        // FPSを設定
        do {
            try myDevice.lockForConfiguration()
            myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 10)
            myDevice.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
            myDevice.unlockForConfiguration()
        } catch let error {
            print("lock error: \(error)")
            return false
        }
        
        // デリゲートを設定
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue",  nil)
        myOutput.setSampleBufferDelegate(self, queue: queue)
        
        
        // 遅れてきたフレームは無視する
        myOutput.alwaysDiscardsLateVideoFrames = true
        
        // セッションに追加.
        if mySession.canAddOutput(myOutput) {
            mySession.addOutput(myOutput)
        } else {
            return false
        }
        
        // カメラの向きを合わせる
        for connection in myOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.supportsVideoOrientation {
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        
        // 画像を表示するレイヤーを生成.
        let myVideoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session:mySession)
        myVideoLayer.frame = self.view.bounds
        myVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        let orientation = AVCaptureVideoOrientation(rawValue: UIApplication.sharedApplication().statusBarOrientation.rawValue)!
        myVideoLayer.connection.videoOrientation = orientation
        
        // セッション開始.
        mySession.startRunning()
        
        self.view.layer.addSublayer(myVideoLayer)

        return true
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_sync(dispatch_get_main_queue(), {
            if (self.status) {
                // UIImageへ変換
                let image:UIImage = CameraUtil.imageFromSampleBuffer(sampleBuffer)
                
                // 認識
                let res = self.detector.recognizeFace(image)
                if (self.status) {
                    self.result(res, image: image)
                }
            }
        })
    }
    
    func result(res: NSString, image: UIImage) {
        if (res == "win" || res == "lose") {
            print(res)
            items.append(res)
        } else {
            items = []
            return
        }
        
        print(items);
        
        if (items.count < 3) {
            return
        } else {
            items.removeFirst()
        }
        
        for item in items {
            if (res != item) {
                return
            }
        }
        
        self.status = false
        NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: #selector(restore), userInfo: nil, repeats: false)

        if (res == "win") {
            winCount += 1
            message.setTitle("WIN!", forState: .Normal)
            message.backgroundColor = UIColor(red: 250/255, green: 30/255, blue: 0/255, alpha: 1.0)
        } else if (res == "lose") {
            loseCount += 1
            message.setTitle("LOSE", forState: .Normal)
            message.backgroundColor = UIColor(red: 15/255, green: 15/255, blue: 230/255, alpha: 1.0)
        }
        scoreImage = image
        message.hidden = false
        setScore()
    }
    
    func setScore() {
        scoreText.numberOfLines = 2
        scoreText.text = "WIN: \(winCount)\n" +
                         "LOSE: \(loseCount)"
        scoreText.backgroundColor = UIColor.blackColor()
        scoreText.textColor = UIColor.whiteColor()
        scoreText.sizeToFit()
        scoreText.textAlignment = NSTextAlignment.Center
        scoreText.baselineAdjustment = UIBaselineAdjustment.AlignCenters
        scoreText.frame = CGRectMake(0, 0, scoreText.layer.bounds.width+20, scoreText.layer.bounds.height+20)
        scoreText.layer.position = CGPoint(x: self.view.bounds.width - scoreText.layer.bounds.width/2, y:self.view.bounds.height - scoreText.layer.bounds.height/2)
        self.view.addSubview(scoreText);
    }

    internal func restore() {
        print("restore")
        status = true
        items = []
        message.hidden = true
    }
    
    internal func toTop() {
        status = false
        
        // 遷移するViewを定義する.
        let nextViewController: UIViewController = ViewController()
        
        // アニメーションを設定する.
        nextViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        // Viewの移動する.
        self.presentViewController(nextViewController, animated: true, completion: nil)        
    }

    internal func tweet() {
        myComposeView = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
        myComposeView.setInitialText("スプラトゥーン対戦結果：\(winCount)勝\(loseCount)敗 #スプラトゥーン #イカスコア")
        myComposeView.addImage(scoreImage)
        self.presentViewController(myComposeView, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}