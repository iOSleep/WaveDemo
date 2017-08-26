# WaveDemo
使用AVAudioEngine录音, 并回执声波图(调参)

修复
* 音频现在可以正常录制了

已知问题
* AVAudioEngine没有提供默认的**音量**获取方式, 需要自行计算(sf上找了,但是,怎么调呢...) 
  > waveView需要调参, 使曲线**平滑**

相关链接[iOS端音频边录边转和声波图的实现](http://www.jianshu.com/p/dbd8c4748e8d)
