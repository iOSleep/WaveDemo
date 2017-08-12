//
//  ViewController.swift
//  WaveDemo
//
//  Created by mac on 2017/8/11.
//  Copyright © 2017年 yolande. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    AudioRecord.shared.delegate = self
  }
  @IBAction func record() {
    AudioRecord.shared.record()
  }
  @IBAction func stop() {
    AudioRecord.shared.stop()
  }
}

extension ViewController: AudioRecordPortocol {
  func record(_ record: AudioRecord, voluem: Float) {
    print("volue: \(voluem)")
  }
}

