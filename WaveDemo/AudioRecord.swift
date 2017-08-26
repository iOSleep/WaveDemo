//
//  AudioRecord.swift
//  WaveDemo
//
//  Created by mac on 2017/8/11.
//  Copyright © 2017年 yolande. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

protocol AudioRecordPortocol: NSObjectProtocol {
  func record(_ record: AudioRecord, voluem: Float)
}

class AudioRecord {
  
  public static let shared = AudioRecord()
  public weak var delegate: AudioRecordPortocol?
  private static let bufSize: Int = 4096
  private var engine: AVAudioEngine?
  private var lame: lame_t?
  private var mp3Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
  private var data = Data()
  
  private var averagePowerForChannel0: Float = 0.0
  private var averagePowerForChannel1: Float = 0.0
  
  private var minLevel: Float = 0.0
  private var maxLevel: Float = 0.0
  
  deinit {
    mp3Buffer.deallocate(capacity: AudioRecord.bufSize)
  }
  
  public func record() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
      try session.setPreferredSampleRate(44100)
      try session.setPreferredIOBufferDuration(0.1)
      try session.setActive(true)
      initLame()
    } catch {
      print("seesion设置")
      return
    }
    
    guard let input = engine?.inputNode else {
      print("input获取")
      return
    }
    
    let format = input.inputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize:AVAudioFrameCount(AudioRecord.bufSize) , format: format) { [weak self] (buffer, when) in
      
      guard let this = self else {
        return
      }
      
      if let buf = buffer.floatChannelData?[0]
      {
        let frameLength = Int32(buffer.frameLength) / 2
        let bytes = lame_encode_buffer_interleaved_ieee_float(this.lame, buf, frameLength, this.mp3Buffer, Int32(AudioRecord.bufSize))
        
        let levelLowpassTrig: Float = 0.5
        var avgValue: Float32 = 0
        vDSP_meamgv(buf, 1, &avgValue, vDSP_Length(frameLength))
        this.averagePowerForChannel0 = (levelLowpassTrig * ((avgValue==0) ? -100 : 20.0 * log10f(avgValue))) + ((1-levelLowpassTrig) * this.averagePowerForChannel0)
        
        let volume = min((this.averagePowerForChannel0 + Float(55))/55.0, 1.0)
        
        this.minLevel = min(this.minLevel, volume)
        this.maxLevel = max(this.maxLevel, volume)
        // 切回去, 更新UI
        DispatchQueue.main.async {
          this.delegate?.record(this, voluem: volume)
        }
        if bytes > 0 {
          this.data.append(this.mp3Buffer, count: Int(bytes))
        }
      }
    }
    
    engine?.prepare()
    do {
      try engine?.start()
    } catch {
      print("engine启动")
    }
  }
  
  private func initLame() {
    
    engine = AVAudioEngine()
    guard let engine = engine,
          let input = engine.inputNode else {
        return
    }
    
    let format = input.inputFormat(forBus: 0)
    let sampleRate = Int32(format.sampleRate) / 2
    
    lame = lame_init()
    lame_set_in_samplerate(lame, sampleRate);
    lame_set_VBR_mean_bitrate_kbps(lame, 96);
    lame_set_VBR(lame, vbr_off);
    lame_init_params(lame);
  }
  
  public func stop() {
    print("min: \(self.minLevel)")
    print("max: \(self.maxLevel)")
    engine?.inputNode?.removeTap(onBus: 0)
    engine = nil
    do {
      var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      let name = String(CACurrentMediaTime()).appending(".mp3")
      url.appendPathComponent(name)
      if !data.isEmpty {
        try data.write(to: url)
      }
      else {
        print("空文件")
      }
    } catch {
      print("文件操作")
    }
    data.removeAll()
  }
  
}
