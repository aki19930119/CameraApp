//
//  FaceDetectViewController.swift
//  CameraApp
//
//  Created by 柿沼儀揚 on 2020/04/25.
//  Copyright © 2020 柿沼儀揚. All rights reserved.
//

// 顔検出をするView
import UIKit

class FaceDetectViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!

    // 顔検出をするためのクラス
    private var faceDetecter: FaceDetecter?
    // 検出された顔のフレームを表示するためのView
    private let frameView = UIView()
    // 切り出された画像
    private var image = UIImage()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }

    ///viewが表示されなくなる直前に呼び出される
    override func viewWillDisappear(_ animated: Bool) {
        if let faceDetecter = faceDetecter {
            faceDetecter.stopRunning()
        }
        faceDetecter = nil
    }

    ///準備
    private func setup() {
        frameView.layer.borderWidth = 3
        view.addSubview(frameView)
        faceDetecter = FaceDetecter(view: cameraView, completion: {faceRect, image in
            self.frameView.frame = faceRect
            self.image = image
        })
    }

    ///実行を停止
    private func stopRunning() {
        guard let faceDetecter = faceDetecter else { return }
        faceDetecter.stopRunning()
    }
    ///メモリ警告を受信した後の処理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    ///バックボタンを押した後の処理
    @IBAction func tappedBackButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}

