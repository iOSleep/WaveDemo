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

struct Platform {
  static let isSimulator: Bool = {
    var isSim = false
    #if arch(i386) || arch(x86_64)
      isSim = true
    #endif
    return isSim
  }()
}

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
  
  init() {
    initLame()
  }
  
  deinit {
    mp3Buffer.deallocate(capacity: AudioRecord.bufSize)
  }
  
  public func record() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
      try session.setActive(true)
      try session.setPreferredSampleRate( Platform.isSimulator ? 44100 : 22050)
    } catch {
      print("seesion设置")
      return
    }
    engine = AVAudioEngine()
    
    guard let engine = engine,
          let input = engine.inputNode else {
      return
    }
    
    let format = input.inputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize:AVAudioFrameCount(AudioRecord.bufSize) , format: format) { [weak self] (buffer, when) in
      
      guard let this = self else {
        return
      }
      
      if let lbuf = buffer.floatChannelData?[0],
        let rbuf = buffer.floatChannelData?[1] {
        let frameLength = Int32(buffer.frameLength)
        let bytes = lame_encode_buffer_ieee_float(this.lame, lbuf, rbuf, frameLength, this.mp3Buffer, Int32(AudioRecord.bufSize))

        var volume = this.calculateVoluem(lbuf: lbuf, rbuf: rbuf, frameLength: UInt(buffer.frameLength))
        volume = min((volume + Float(60))/65.0, 1.0)
        
        this.minLevel = min(this.minLevel, volume)
        this.maxLevel = max(this.maxLevel, volume)
        // 切回去, 更新UI
        DispatchQueue.main.async {
          this.delegate?.record(this, voluem: volume)
        }
        this.data.append(this.mp3Buffer, count: Int(bytes))
      }
    }
    
    engine.prepare()
    do {
      try engine.start()
    } catch {
      print("engine启动")
    }
  }
  
  private func calculateVoluem(lbuf: UnsafeMutablePointer<Float>, rbuf: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
    let levelLowpassTrig: Float = 1.0
    var avgValue: Float32 = 0
    vDSP_meamgv(lbuf, 1, &avgValue, frameLength)
    self.averagePowerForChannel0 = (levelLowpassTrig * ((avgValue==0) ? -100 : 20.0 * log10f(avgValue))) + ((1-levelLowpassTrig) * self.averagePowerForChannel0)
    self.averagePowerForChannel1 = self.averagePowerForChannel0
    
    avgValue = 0
    vDSP_meamgv(rbuf, 1, &avgValue, frameLength);
    self.averagePowerForChannel1 = (levelLowpassTrig * ((avgValue==0) ? -100 : 20.0 * log10f(avgValue))) + ((1-levelLowpassTrig)*self.averagePowerForChannel1)
    return (self.averagePowerForChannel0 + self.averagePowerForChannel1) / 2
  }
  
  private func initLame() {
    
    engine = AVAudioEngine()
    guard let engine = engine,
          let input = engine.inputNode else {
        return
    }
    
    let format = input.inputFormat(forBus: 0)
    let sampleRate = Int32(format.sampleRate)
    let channelCount = Int32(format.channelCount)
    
    lame = lame_init()
    lame_set_bWriteVbrTag(lame, 0);
    lame_set_num_channels(lame, channelCount);
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
    } catch {
      print("文件操作")
    }
    data.removeAll()
  }
  
}
