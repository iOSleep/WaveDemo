//
//  WaveView.swift
//  WaveDemo
//
//  Created by mac on 2017/8/11.
//  Copyright © 2017年 yolande. All rights reserved.
//

import UIKit

class WaveView: UIControl {
  
  private var phase: CGFloat = 0.0
  private var _amplitude: CGFloat = 1.0
  
  public var waveColor: UIColor = .black {
    didSet {
      for line in lines {
        line.strokeColor = waveColor.cgColor
      }
    }
  }
  
  public var numberOfWaves = 5
  public var lineWidth: CGFloat = 3.0
  public var idleAmplitude: CGFloat = 0.01
  public var frequency: CGFloat = 1.2
  public var density: CGFloat = 5
  public var phaseShift: CGFloat = -0.25
  
  private weak var linker: CADisplayLink?
  
  private var paths = [UIBezierPath]()
  private var lines = [CAShapeLayer]()
  
  public var amplitude: CGFloat {
    get {
      return _amplitude
    }
  }
  public var level: CGFloat = 0 {
    didSet {
      // 不平
      _amplitude = max(level, idleAmplitude)
    }
  }
  private var waveHeight: CGFloat {
    return bounds.height
  }
  private var waveWidth: CGFloat {
    return bounds.width
  }
  private var waveMid: CGFloat {
    return waveWidth / 2
  }
  private var maxAmplitude: CGFloat {
    return waveHeight - 4.0
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  deinit {
    stop()
  }
  
  private func setup() {
    for i in 0..<numberOfWaves {
      let shapeLayer = creatLayer()
      if i == 0 {
        shapeLayer.lineWidth = 2
      }
      layer.addSublayer(shapeLayer)
      lines.append(shapeLayer)
      
      let path = UIBezierPath()
      paths.append(path)
    }
  }
  
  private func creatLayer() -> CAShapeLayer {
    let shaperLayer = CAShapeLayer()
    shaperLayer.fillColor = UIColor.clear.cgColor
    shaperLayer.shadowColor = UIColor.cyan.cgColor
    shaperLayer.lineWidth = 1
    return shaperLayer
  }
  //MARK: - public
  public func begin() {
    let linker = CADisplayLink(target: self, selector: #selector(WaveView.updateMeters))
    linker.add(to: .current, forMode: .commonModes)
    self.linker = linker
  }
  
  public func stop() {
    linker?.invalidate()
    paths.forEach { (path) in
      path.removeAllPoints()
    }
  }
  //MARK: - import
  @objc private func updateMeters() {
    // 移动
    phase += phaseShift
    for i in 0..<numberOfWaves {
      let path = paths[i]
      path.removeAllPoints()
      let progress = 1.0 - CGFloat(i) / CGFloat(numberOfWaves)
      let normedAmplitude = (1.5 * progress - 0.5) * amplitude
      
      var x: CGFloat = 0
      while x < waveWidth + density {
        
        let scaling: CGFloat = -pow(x / waveMid - 1, 2) + 1
        let y = scaling * maxAmplitude * normedAmplitude * sin(2 * CGFloat.pi * (x / waveWidth) * frequency + phase) + (waveHeight * 0.5)
        if x == 0 {
          path.move(to: CGPoint(x: x, y: y))
        } else {
          path.addLine(to: CGPoint(x: x, y: y))
        }
        x += density
      }
      
      let line = lines[i]
      line.path = path.cgPath
    }
  }
}
