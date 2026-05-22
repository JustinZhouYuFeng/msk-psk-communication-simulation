# 给另一个 Codex 的执行指令

你负责基于本文件夹中的 MATLAB 仿真结果，完成第二题 2PSK 的报告或 PPT。请严格只围绕“二进制移相键控（2PSK）调制原理”展开，不要混入 MSK、2FSK、AMI/HDB3 等其他题目。

## 运行方式

在 MATLAB 中打开本文件夹：

```matlab
cd('C:\Users\19571\Desktop\研讨\通信原理研讨\topic2_2psk_matlab')
run_all
```

运行后会生成：

- `outputs/figures/00_system_block.png`
- `outputs/figures/00_program_flow.png`
- `outputs/figures/01_2psk_waveform.png`
- `outputs/figures/02_2psk_spectrum.png`
- `outputs/figures/03_coherent_receiver.png`
- `outputs/figures/04_signal_space_noise.png`
- `outputs/figures/05_ber_curve.png`
- `outputs/figures/06_phase_ambiguity_ber.png`
- `outputs/figures/07_phase_decision_demo.png`
- `outputs/result_summary.txt`
- `outputs/topic2_2psk_results.mat`

## 报告要求

报告至少包含：

1. 封皮：按课程模板填写。
2. 题目与各级标题：层次清晰。
3. 实验基本原理：写 2PSK 定义、码元映射、通带表达式、信号空间、理论 BER。
4. 仿真方案：写参数表和程序流程图。
5. 实验结果及分析：插入上述 PNG 图，并逐图解释。
6. 总结及存在的问题。
7. 附录：粘贴 `run_all.m` 和 `src` 文件夹下的核心 `.m` 源码。

## PPT 建议

建议 8 到 10 页：

1. 标题页：第二题 2PSK 调制原理。
2. 研讨任务与系统框图。
3. 2PSK 原理与公式。
4. MATLAB 仿真流程和参数。
5. 波形结果。
6. 频谱结果。
7. AWGN 相干接收。
8. BER 曲线与理论对比。
9. 载波相位模糊。
10. 总结。

## 注意事项

- 不要把有限样本导致的高信噪比零误码解释为理论 BER 为 0。
- 180° 相位误差不是正常解调，而是输出极性整体反转。
- 频谱旁瓣明显的原因是矩形码元成形，不是程序错误。
- 如果要改图，只改 MATLAB 脚本后重新运行，不要手工截图拼接。

