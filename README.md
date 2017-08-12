# WaveDemo
使用AVAudioEngine录音, 并回执声波图(调参)

已知问题
* AVAudioEngine没有提供默认的**音量**获取方式, 需要自行计算(sf上找了,但是,怎么调呢...) 
  > waveView需要调参, 使曲线**平滑**
* inputNode的format极不稳定,Mac和iPhone上有差异
  > 声道不同, 转码lame的时候用到的方法不同
    
  > 采样率不同, 之前测试得到的采样率可以通过设置seesion修改, 这次又不行了...


相关链接[iOS端音频边录边转和声波图的实现](http://www.jianshu.com/p/dbd8c4748e8d)
