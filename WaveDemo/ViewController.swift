//
//  ViewController.swift
//  WaveDemo
//
//  Created by mac on 2017/8/11.
//  Copyright © 2017年 yolande. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var waveView: WaveView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    AudioRecord.shared.delegate = self
    waveView.waveColor = UIColor.red
  }
  @IBAction func record() {
    waveView.begin()
    AudioRecord.shared.record()
  }
  @IBAction func stop() {
    AudioRecord.shared.stop()
    waveView.stop()
  }
}

extension ViewController: AudioRecordPortocol {
  func record(_ record: AudioRecord, voluem: Float) {
    waveView.level = CGFloat(voluem)
    print("volue: \(voluem)")
  }
}

