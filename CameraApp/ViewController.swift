//
//  ViewController.swift
//  CameraApp
//
//  Created by 柿沼儀揚 on 2020/04/25.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

// 初期表示View
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func tappedLogin(_ sender: Any) {
        self.performSegue(withIdentifier: "gotoFaceDetect", sender: nil)
    }

}
