# 第二题 2PSK 研讨报告写作提纲

## 题目

二进制移相键控（2PSK）调制原理、仿真与误码率性能分析

## 必须覆盖的课程要求

1. 产生二进制随机数据。
2. 仿真对应的 2PSK 调制波形。
3. 观察并分析 2PSK 频谱。
4. 对调制波形加入不同信噪比的白噪声。
5. 选取相干解调接收方案。
6. 绘制系统误码率曲线，并与理论误码率对比。
7. 补充分析载波相位模糊对 2PSK 误码率性能的影响。

## 推荐报告结构

1. 摘要与关键词
2. 2PSK 基本原理
   - 码元映射：bit 1 -> +1，bit 0 -> -1
   - 通带表达式：s_k(t)=sqrt(2Eb/Tb) a_k cos(2*pi*fc*t)
   - 信号空间：两个点分别位于 +sqrt(Eb) 和 -sqrt(Eb)
3. 仿真方案
   - 参数表：Tb=1，sps=80，fc=8Rb，Eb/N0=-4:2:12 dB
   - 程序流程图：见 `outputs/figures/00_program_flow.png`
4. 实验结果与分析
   - 系统框图：`00_system_block.png`
   - 波形图：`01_2psk_waveform.png`
   - 频谱图：`02_2psk_spectrum.png`
   - 加噪相干接收：`03_coherent_receiver.png`
   - 信号空间噪声：`04_signal_space_noise.png`
   - BER 曲线：`05_ber_curve.png`
5. 载波相位模糊补充分析
   - 公式：z_k = a_k sqrt(Eb) cos(theta) + n_k
   - 结果图：`06_phase_ambiguity_ber.png`、`07_phase_decision_demo.png`
6. 总结及存在的问题
7. 附录：MATLAB 源代码

## 核心结论

- 2PSK 用两个相差 pi 的载波相位表示二进制信息。
- 相干解调后，2PSK 检测等价于一维过零判决。
- AWGN 信道下，理论误码率为 Pb=0.5erfc(sqrt(Eb/N0))。
- 载波相位误差会按 cos(theta) 缩小有效判决距离；90° 附近接近随机判决，180° 时发生判决极性反转。

