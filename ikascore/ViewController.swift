import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.whiteColor()
 
        UIApplication.sharedApplication().idleTimerDisabled = false

        let startButton: UIButton = UIButton(frame: CGRectMake(0,0,120,50))
        startButton.backgroundColor = UIColor(red: 200/255, green: 0/255, blue: 225/255, alpha: 1.0)
        startButton.layer.masksToBounds = true
        startButton.setTitle("スタート", forState: .Normal)
        startButton.layer.cornerRadius = 5.0
        
        
        let size:CGSize  = UIScreen.mainScreen().bounds.size
        if size.width < size.height {
            startButton.layer.position = CGPoint(x: self.view.frame.height/2, y: self.view.frame.width-65)
        } else if size.width > size.height {
            startButton.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height-65)
        }

        startButton.addTarget(self, action: #selector(onClickStartButton), forControlEvents: .TouchUpInside)
        
        // ボタンを追加する.
        self.view.addSubview(startButton);
    }

    internal func onClickStartButton(sender: UIButton){
        
        // 遷移するViewを定義する.
        let nextViewController: UIViewController = CaptureController()
        
        // アニメーションを設定する.
        nextViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        // Viewの移動する.
        self.presentViewController(nextViewController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

