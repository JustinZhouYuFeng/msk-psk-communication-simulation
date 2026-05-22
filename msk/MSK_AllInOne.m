function MSK_AllInOne()
% MSK_AllInOne
% 将原有 MSKwave、MSKWave2、MSKGIF、MSK1 四个脚本整理为一个入口。
% 功能包括：
%   1) 2MSK I/Q 结构与波形生成过程展示
%   2) 相位轨迹 Phase Trellis 展示
%   3) 波形与相位轨迹 GIF 导出
%   4) MSK 与普通 2FSK 功率谱对比
%   5) AWGN 信道下 BER 仿真与理论曲线对比

clc; close all;

cfg = defaultMskConfig();
rng(cfg.randomSeed);

if cfg.saveFiguresAsPng && ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

% ====== 一、演示用 MSK I/Q 波形与相位轨迹 ======
demo = buildMskIqDemo(cfg.demoBits, cfg);

if cfg.showStaticWaveforms
    plotMskWaveformProcess(demo, cfg);
    plotMskPhaseTrellis(demo, cfg);
end

if cfg.exportGifs
    exportMskGifs(demo, cfg);
end

% ====== 二、系统级频谱与误码率仿真 ======
if cfg.runSpectrumAnalysis || cfg.runBerAnalysis
    sim = buildCpfskMskSimulation(cfg);
end

if cfg.runSpectrumAnalysis
    plotSpectrumComparison(sim, cfg);
end

if cfg.runBerAnalysis
    [berSim, berTheory] = simulateMskBer(sim, cfg);
    plotBerComparison(cfg.EbNoDbVec, berSim, berTheory, cfg);
end

% ====== 三、按照总流程图补充更多效果图 ======
if cfg.showEffectGallery
    if ~exist('sim', 'var')
        sim = buildCpfskMskSimulation(cfg);
    end
    plotInstantaneousFrequency(demo, cfg);
    plotIqPlaneAndEnvelope(demo, cfg);
    plotPhaseContinuityComparison(demo, cfg);
    plotNoisyChannelExample(sim, cfg);
    plotCorrelationDecisionExample(sim, cfg);
end

disp('MSK 综合仿真运行完成。');
end


function cfg = defaultMskConfig()
% 所有参数统一放在这里，后续改报告图或仿真规模只改本段即可。

cfg.Rb = 1000;                    % 码元速率 / 比特率 (bps)
cfg.Tb = 1 / cfg.Rb;              % 码元周期 (s)
cfg.fc = 4000;                    % 载波频率 (Hz)
cfg.fs = 32000;                   % 采样频率 (Hz)
cfg.nsamp = cfg.fs / cfg.Rb;      % 每比特采样点数
cfg.deltaF = 1 / (2 * cfg.Tb);    % MSK 最小频率间隔

cfg.demoBits = [1 0 1 1 0 1 0 1]; % 用于波形展示的短码流
cfg.randomSeed = 7;

cfg.showStaticWaveforms = true;
cfg.exportGifs = false;           % 需要重新生成 GIF 时改为 true
cfg.runSpectrumAnalysis = true;
cfg.runBerAnalysis = true;
cfg.showEffectGallery = true;     % 根据总流程图补充更多效果图
cfg.saveFiguresAsPng = true;      % 自动导出 PNG，便于放进 PPT
cfg.outputDir = 'MSK_Output_Figures';

cfg.gifFrames = 60;
cfg.gifDuration = 2.0;            % 每个 GIF 动画总时长约 2 秒
cfg.waveGifFile = 'MSK_Waveforms_5_Subplots.gif';
cfg.phaseGifFile = 'MSK_Phase_Trellis.gif';

cfg.NBitsSystem = 10000;          % BER/频谱仿真比特数
cfg.EbNoDbVec = 0:1:10;
cfg.exampleEbNoDb = 6;            % 信道/相关检测示例图使用的 Eb/N0
cfg.psdNfft = 2048;
cfg.psdWindowLength = 2048;
cfg.psdOverlap = 1024;

cfg.figureColor = 'w';

if abs(cfg.nsamp - round(cfg.nsamp)) > eps
    error('fs/Rb 必须为整数，当前 fs/Rb = %.4f。', cfg.nsamp);
end
cfg.nsamp = round(cfg.nsamp);
end


function demo = buildMskIqDemo(dataBin, cfg)
% 基于 I/Q 等效结构生成演示波形。

dataNrz = 2 * dataBin - 1;
N = numel(dataNrz);
t = (0:N * cfg.nsamp - 1) / cfg.fs;

[pSeq, qSeq] = differentialPrecodeForMsk(dataNrz);

IWave = repelem(pSeq, cfg.nsamp);
QWave = repelem(qSeq, cfg.nsamp);
inputWave = repelem(dataNrz, cfg.nsamp);

shapeI = cos(pi * t / (2 * cfg.Tb));
shapeQ = sin(pi * t / (2 * cfg.Tb));
IBaseband = IWave .* shapeI;
QBaseband = QWave .* shapeQ;

carrierI = cos(2 * pi * cfg.fc * t);
carrierQ = sin(2 * pi * cfg.fc * t);
IRf = IBaseband .* carrierI;
QRf = QBaseband .* carrierQ;
mskSignal = IRf - QRf;

phaseBaseband = unwrap(atan2(QBaseband, IBaseband));
phaseBaseband = phaseBaseband - phaseBaseband(1);

demo.dataBin = dataBin;
demo.dataNrz = dataNrz;
demo.N = N;
demo.t = t;
demo.pSeq = pSeq;
demo.qSeq = qSeq;
demo.inputWave = inputWave;
demo.IWave = IWave;
demo.QWave = QWave;
demo.IBaseband = IBaseband;
demo.QBaseband = QBaseband;
demo.IRf = IRf;
demo.QRf = QRf;
demo.mskSignal = mskSignal;
demo.phaseBaseband = phaseBaseband;
end


function [pSeq, qSeq] = differentialPrecodeForMsk(dataNrz)
% 差分预编码：让 I/Q 两路交错更新，从而保持 MSK 相位连续。

N = numel(dataNrz);
pSeq = zeros(1, N);
qSeq = zeros(1, N);

pPrev = 1;
qPrev = 1;

for k = 1:N
    if mod(k, 2) == 1
        % 奇数码元：Q 路可更新，I 路保持。
        pSeq(k) = pPrev;
        qSeq(k) = dataNrz(k) * pPrev;
        qPrev = qSeq(k);
    else
        % 偶数码元：I 路可更新，Q 路保持。
        pSeq(k) = dataNrz(k) * qPrev;
        qSeq(k) = qPrev;
        pPrev = pSeq(k);
    end
end
end


function plotMskWaveformProcess(demo, cfg)
% 5 子图展示 MSK 从码流到射频波形的生成过程。

fig = figure('Name', '2MSK 调制波形演变过程', ...
    'Position', [80, 60, 950, 850], 'Color', cfg.figureColor);

subplot(5, 1, 1);
stairs(demo.t, demo.inputWave, 'k', 'LineWidth', 1.5);
title('1. 原始输入数据（双极性 NRZ 码）');
axis([0 max(demo.t) -1.5 1.5]); grid on;
ylabel('a_k');

subplot(5, 1, 2);
stairs(demo.t, demo.IWave, 'b', 'LineWidth', 1.4); hold on;
stairs(demo.t, demo.QWave, 'r', 'LineWidth', 1.4);
title('2. 差分预编码后的 I/Q 方波（奇偶交错）');
legend('I 路', 'Q 路', 'Location', 'northeast');
axis([0 max(demo.t) -1.5 1.5]); grid on;

subplot(5, 1, 3);
plot(demo.t, demo.IBaseband, 'b', 'LineWidth', 1.4); hold on;
plot(demo.t, demo.QBaseband, 'r', 'LineWidth', 1.4);
title('3. 半正弦脉冲成形后的 I/Q 基带信号');
legend('I(t)', 'Q(t)', 'Location', 'northeast');
axis([0 max(demo.t) -1.5 1.5]); grid on;

subplot(5, 1, 4);
plot(demo.t, demo.IRf, 'b', 'LineWidth', 1.0); hold on;
plot(demo.t, demo.QRf, 'r', 'LineWidth', 1.0);
title('4. 正交载波调制后的两路射频分量');
legend('I(t)cos(2\pi f_c t)', 'Q(t)sin(2\pi f_c t)', 'Location', 'northeast');
axis([0 max(demo.t) -1.5 1.5]); grid on;

subplot(5, 1, 5);
plot(demo.t, demo.mskSignal, 'm', 'LineWidth', 1.4);
title('5. 最终合成的 2MSK 射频波形（恒包络、相位连续）');
xlabel('时间 (s)');
axis([0 max(demo.t) -1.5 1.5]); grid on;

saveFigureIfNeeded(fig, cfg, '01_MSK_waveform_process');
end


function plotMskPhaseTrellis(demo, cfg)
% 绘制基带相位轨迹，观察每个码元处的连续相位变化。

fig = figure('Name', 'MSK 相位轨迹图 (Phase Trellis)', ...
    'Position', [180, 120, 950, 480], 'Color', cfg.figureColor);

ax = axes; hold(ax, 'on'); grid(ax, 'on');
plot(ax, demo.t, demo.phaseBaseband / pi, 'b', 'LineWidth', 2.2);

axis(ax, [0 max(demo.t), min(demo.phaseBaseband / pi) - 0.5, ...
    max(demo.phaseBaseband / pi) + 0.5]);
drawSymbolGrid(ax, demo.N, cfg.Tb);
yline(ax, 0, 'k', 'LineWidth', 1);

endTime = demo.t(cfg.nsamp:cfg.nsamp:end);
endPhase = demo.phaseBaseband(cfg.nsamp:cfg.nsamp:end) / pi;
plot(ax, endTime, endPhase, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

title(ax, 'MSK 基带瞬时相位轨迹（Phase Trellis）');
xlabel(ax, '时间 (s)');
ylabel(ax, '相位 / \pi');
formatPiTicks(ax, demo.phaseBaseband / pi);

saveFigureIfNeeded(fig, cfg, '02_MSK_phase_trellis');
end


function exportMskGifs(demo, cfg)
% 导出 5 子图波形 GIF 和相位轨迹 GIF。

numFrames = cfg.gifFrames;
totalPoints = numel(demo.t);
pointsPerFrame = totalPoints / numFrames;
delayTime = cfg.gifDuration / numFrames;

fprintf('正在生成 GIF：%s 和 %s\n', cfg.waveGifFile, cfg.phaseGifFile);

hFigWave = figure('Name', '2MSK 波形动态生成', ...
    'Position', [80, 50, 850, 900], 'Color', cfg.figureColor);

ax1 = subplot(5, 1, 1, 'Parent', hFigWave); hold(ax1, 'on'); grid(ax1, 'on');
axis(ax1, [0 max(demo.t) -1.5 1.5]); title(ax1, '1. 原始输入数据');
hLine1 = stairs(ax1, NaN, NaN, 'k', 'LineWidth', 1.5);

ax2 = subplot(5, 1, 2, 'Parent', hFigWave); hold(ax2, 'on'); grid(ax2, 'on');
axis(ax2, [0 max(demo.t) -1.5 1.5]); title(ax2, '2. 差分预编码后的 I/Q 方波');
hLine2I = stairs(ax2, NaN, NaN, 'b', 'LineWidth', 1.5);
hLine2Q = stairs(ax2, NaN, NaN, 'r', 'LineWidth', 1.5);

ax3 = subplot(5, 1, 3, 'Parent', hFigWave); hold(ax3, 'on'); grid(ax3, 'on');
axis(ax3, [0 max(demo.t) -1.5 1.5]); title(ax3, '3. 半正弦成形后的 I/Q 基带信号');
hLine3I = plot(ax3, NaN, NaN, 'b', 'LineWidth', 1.5);
hLine3Q = plot(ax3, NaN, NaN, 'r', 'LineWidth', 1.5);

ax4 = subplot(5, 1, 4, 'Parent', hFigWave); hold(ax4, 'on'); grid(ax4, 'on');
axis(ax4, [0 max(demo.t) -1.5 1.5]); title(ax4, '4. 正交载波调制后的两路射频分量');
hLine4I = plot(ax4, NaN, NaN, 'b', 'LineWidth', 1);
hLine4Q = plot(ax4, NaN, NaN, 'r', 'LineWidth', 1);

ax5 = subplot(5, 1, 5, 'Parent', hFigWave); hold(ax5, 'on'); grid(ax5, 'on');
axis(ax5, [0 max(demo.t) -1.5 1.5]); title(ax5, '5. 最终合成的 2MSK 射频波形');
xlabel(ax5, '时间 (s)');
hLine5 = plot(ax5, NaN, NaN, 'm', 'LineWidth', 1.5);

hFigPhase = figure('Name', 'MSK 相位轨迹动态生成', ...
    'Position', [980, 180, 850, 500], 'Color', cfg.figureColor);
axPhase = axes('Parent', hFigPhase); hold(axPhase, 'on'); grid(axPhase, 'on');
axis(axPhase, [0 max(demo.t), min(demo.phaseBaseband / pi) - 0.5, ...
    max(demo.phaseBaseband / pi) + 0.5]);
title(axPhase, 'MSK 基带瞬时相位轨迹');
xlabel(axPhase, '时间 (s)');
ylabel(axPhase, '相位 / \pi');
drawSymbolGrid(axPhase, demo.N, cfg.Tb);
yline(axPhase, 0, 'k', 'LineWidth', 1);
formatPiTicks(axPhase, demo.phaseBaseband / pi);

endTime = demo.t(cfg.nsamp:cfg.nsamp:end);
endPhase = demo.phaseBaseband(cfg.nsamp:cfg.nsamp:end) / pi;
hTrace = plot(axPhase, NaN, NaN, 'b', 'LineWidth', 2.5);
hDots = plot(axPhase, NaN, NaN, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

for frame = 1:numFrames
    idx = min(totalPoints, max(1, round(frame * pointsPerFrame)));
    if frame == numFrames
        idx = totalPoints;
    end

    tNow = demo.t(1:idx);

    set(hLine1, 'XData', tNow, 'YData', demo.inputWave(1:idx));
    set(hLine2I, 'XData', tNow, 'YData', demo.IWave(1:idx));
    set(hLine2Q, 'XData', tNow, 'YData', demo.QWave(1:idx));
    set(hLine3I, 'XData', tNow, 'YData', demo.IBaseband(1:idx));
    set(hLine3Q, 'XData', tNow, 'YData', demo.QBaseband(1:idx));
    set(hLine4I, 'XData', tNow, 'YData', demo.IRf(1:idx));
    set(hLine4Q, 'XData', tNow, 'YData', demo.QRf(1:idx));
    set(hLine5, 'XData', tNow, 'YData', demo.mskSignal(1:idx));

    set(hTrace, 'XData', tNow, 'YData', demo.phaseBaseband(1:idx) / pi);
    crossed = find(endTime <= demo.t(idx));
    if ~isempty(crossed)
        set(hDots, 'XData', endTime(crossed), 'YData', endPhase(crossed));
    end

    drawnow;

    writeGifFrame(hFigWave, cfg.waveGifFile, frame, delayTime);
    writeGifFrame(hFigPhase, cfg.phaseGifFile, frame, delayTime);
end

fprintf('GIF 生成完成。\n');
end


function sim = buildCpfskMskSimulation(cfg)
% 系统级 MSK/2FSK 信号生成。
% 频谱图使用 passband 实信号；BER 使用等效 complex baseband 信号。

data = randi([0 1], 1, cfg.NBitsSystem);
dataNrz = 2 * data - 1;
dev = dataNrz * (cfg.deltaF / 2);
devExt = repelem(dev, cfg.nsamp);
t = (0:numel(devExt) - 1) / cfg.fs;

phasePassband = 2 * pi * cumsum(cfg.fc + devExt) / cfg.fs;
phaseBaseband = 2 * pi * cumsum(devExt) / cfg.fs;

mskPassband = cos(phasePassband);
mskBaseband = exp(1j * phaseBaseband);

% 对照组：普通 2FSK，不做连续相位累加，因此码元边界处会出现相位跳变。
phaseFsk = 2 * pi * (cfg.fc + devExt) .* t;
fskPassband = cos(phaseFsk);

sim.data = data;
sim.dataNrz = dataNrz;
sim.devExt = devExt;
sim.t = t;
sim.phasePassband = phasePassband;
sim.phaseBaseband = phaseBaseband;
sim.mskPassband = mskPassband;
sim.mskBaseband = mskBaseband;
sim.fskPassband = fskPassband;
end


function plotSpectrumComparison(sim, cfg)
% Welch PSD 对比。为减少工具箱依赖，这里使用本文件内置 Welch 实现。

[Pmsk, f] = localWelchCentered(sim.mskPassband, ...
    cfg.psdWindowLength, cfg.psdOverlap, cfg.psdNfft, cfg.fs);
[Pfsk, ~] = localWelchCentered(sim.fskPassband, ...
    cfg.psdWindowLength, cfg.psdOverlap, cfg.psdNfft, cfg.fs);

fig = figure('Name', '频谱特性分析', ...
    'Position', [100, 100, 900, 460], 'Color', cfg.figureColor);
plot(f, 10 * log10(Pmsk + eps), 'b', 'LineWidth', 1.6); hold on;
plot(f, 10 * log10(Pfsk + eps), 'r--', 'LineWidth', 1.2);
title('功率谱密度对比：连续相位对旁瓣抑制的影响');
xlabel('频率 (Hz)');
ylabel('功率谱密度 (dB/Hz)');
xlim([-8000 8000]);
ylim([-120 -20]);
legend('MSK 信号', '普通 2FSK 信号', 'Location', 'best');
grid on;

saveFigureIfNeeded(fig, cfg, '03_MSK_vs_2FSK_PSD');
end


function [berSim, berTheory] = simulateMskBer(sim, cfg)
% AWGN 下的理想相干相关检测。

berSim = zeros(size(cfg.EbNoDbVec));

for i = 1:numel(cfg.EbNoDbVec)
    snrDb = cfg.EbNoDbVec(i) - 10 * log10(cfg.nsamp);
    rx = localAwgnMeasured(sim.mskBaseband, snrDb);

    rxData = zeros(1, cfg.NBitsSystem);

    for k = 1:cfg.NBitsSystem
        idx = (k - 1) * cfg.nsamp + 1 : k * cfg.nsamp;
        tau = sim.t(idx) - sim.t(idx(1));
        phiStart = sim.phaseBaseband(idx(1));

        ref1 = exp(1j * (phiStart + 2 * pi * (cfg.deltaF / 2) * tau));
        ref0 = exp(1j * (phiStart - 2 * pi * (cfg.deltaF / 2) * tau));

        corr1 = real(rx(idx) * ref1');
        corr0 = real(rx(idx) * ref0');
        rxData(k) = corr1 > corr0;
    end

    berSim(i) = sum(sim.data ~= rxData) / numel(sim.data);
    fprintf('Eb/N0 = %2d dB, BER = %.4g\n', cfg.EbNoDbVec(i), berSim(i));
end

berTheory = 0.5 * erfc(sqrt(10 .^ (cfg.EbNoDbVec / 10)) / sqrt(2));
end


function plotBerComparison(EbNoDbVec, berSim, berTheory, cfg)
fig = figure('Name', '系统误码率 (BER) 性能分析', ...
    'Position', [1040, 100, 650, 520], 'Color', cfg.figureColor);
semilogy(EbNoDbVec, berTheory, 'b-', 'LineWidth', 2); hold on;
semilogy(EbNoDbVec, berSim, 'ro', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on;
xlabel('E_b/N_0 (dB)');
ylabel('误码率 BER');
legend('理论 BER：Q(sqrt(E_b/N_0))', '仿真 BER', 'Location', 'southwest');
title('2MSK 数字通信系统抗噪声性能分析');
ylim([1e-5 1]);

saveFigureIfNeeded(fig, cfg, '04_MSK_BER_performance');
end


function plotInstantaneousFrequency(demo, cfg)
% 对应流程图中的“瞬时频率分析”：MSK 只在两个频率间平滑切换。

freqPerBit = cfg.fc + demo.dataNrz * (cfg.deltaF / 2);
tBit = (0:demo.N - 1) * cfg.Tb;

fig = figure('Name', 'MSK 瞬时频率分析', ...
    'Position', [120, 120, 900, 480], 'Color', cfg.figureColor);
stairs(tBit, freqPerBit, 'b', 'LineWidth', 2); hold on;
yline(cfg.fc, 'k-', 'f_c', 'LineWidth', 1.2);
yline(cfg.fc + cfg.deltaF / 2, 'r--', 'f_c+\Delta f/2', 'LineWidth', 1.1);
yline(cfg.fc - cfg.deltaF / 2, 'r--', 'f_c-\Delta f/2', 'LineWidth', 1.1);
drawSymbolGrid(gca, demo.N, cfg.Tb);
title('MSK 瞬时频率：f_i(t)=f_c \pm \Delta f/2');
xlabel('时间 (s)');
ylabel('瞬时频率 (Hz)');
xlim([0 demo.N * cfg.Tb]);
ylim([cfg.fc - cfg.deltaF, cfg.fc + cfg.deltaF]);
grid on;

saveFigureIfNeeded(fig, cfg, '05_MSK_instantaneous_frequency');
end


function plotIqPlaneAndEnvelope(demo, cfg)
% I/Q 相位平面与恒包络验证。

envelope = sqrt(demo.IBaseband .^ 2 + demo.QBaseband .^ 2);
endIdx = cfg.nsamp:cfg.nsamp:numel(demo.t);

fig = figure('Name', 'MSK I/Q 轨迹与恒包络验证', ...
    'Position', [140, 140, 1050, 480], 'Color', cfg.figureColor);

subplot(1, 2, 1);
plot(demo.IBaseband, demo.QBaseband, 'b', 'LineWidth', 1.8); hold on;
plot(demo.IBaseband(endIdx), demo.QBaseband(endIdx), 'ro', ...
    'MarkerSize', 6, 'MarkerFaceColor', 'r');
axis equal; axis([-1.2 1.2 -1.2 1.2]); grid on;
xlabel('I(t)');
ylabel('Q(t)');
title('I/Q 平面轨迹：相位连续旋转');

subplot(1, 2, 2);
plot(demo.t, envelope, 'm', 'LineWidth', 1.8); hold on;
yline(1, 'k--', '理想恒包络', 'LineWidth', 1.1);
drawSymbolGrid(gca, demo.N, cfg.Tb);
title('恒包络验证：sqrt(I^2+Q^2)');
xlabel('时间 (s)');
ylabel('包络幅度');
ylim([0 1.25]);
grid on;

saveFigureIfNeeded(fig, cfg, '06_MSK_IQ_plane_and_envelope');
end


function plotPhaseContinuityComparison(demo, cfg)
% 连续相位 MSK 与普通 2FSK 的基带相位对比。

dev = demo.dataNrz * (cfg.deltaF / 2);
devExt = repelem(dev, cfg.nsamp);
t = demo.t;

phaseMsk = 2 * pi * cumsum(devExt) / cfg.fs;
phaseFsk = 2 * pi * devExt .* t;
phaseMsk = phaseMsk - phaseMsk(1);
phaseFsk = phaseFsk - phaseFsk(1);

fig = figure('Name', 'MSK 与普通 2FSK 相位连续性对比', ...
    'Position', [160, 160, 950, 500], 'Color', cfg.figureColor);
plot(t, phaseMsk / pi, 'b', 'LineWidth', 2); hold on;
plot(t, phaseFsk / pi, 'r--', 'LineWidth', 1.5);
drawSymbolGrid(gca, demo.N, cfg.Tb);
title('相位连续性对比：MSK 连续，普通 2FSK 在码元边界可跳变');
xlabel('时间 (s)');
ylabel('基带相位 / \pi');
legend('MSK 连续相位', '普通 2FSK 非连续相位', 'Location', 'best');
grid on;

saveFigureIfNeeded(fig, cfg, '07_MSK_phase_continuity_comparison');
end


function plotNoisyChannelExample(sim, cfg)
% AWGN 信道示例：展示 clean / noisy 波形和复平面散点。

snrDb = cfg.exampleEbNoDb - 10 * log10(cfg.nsamp);
rx = localAwgnMeasured(sim.mskBaseband, snrDb);
showBits = 8;
idx = 1:min(showBits * cfg.nsamp, numel(sim.t));
scatterIdx = 1:min(2500, numel(sim.t));

fig = figure('Name', 'AWGN 信道效果示例', ...
    'Position', [180, 180, 1050, 620], 'Color', cfg.figureColor);

subplot(2, 1, 1);
plot(sim.t(idx), real(sim.mskBaseband(idx)), 'b', 'LineWidth', 1.5); hold on;
plot(sim.t(idx), real(rx(idx)), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0);
title(sprintf('AWGN 信道前后波形对比（E_b/N_0 = %g dB）', cfg.exampleEbNoDb));
xlabel('时间 (s)');
ylabel('实部幅度');
legend('发送基带信号', '加噪接收信号', 'Location', 'best');
grid on;

subplot(2, 2, 3);
plot(real(sim.mskBaseband(scatterIdx)), imag(sim.mskBaseband(scatterIdx)), ...
    '.', 'Color', [0.10 0.35 0.75], 'MarkerSize', 7);
axis equal; axis([-1.6 1.6 -1.6 1.6]); grid on;
title('发送端复包络轨迹');
xlabel('In-phase');
ylabel('Quadrature');

subplot(2, 2, 4);
plot(real(rx(scatterIdx)), imag(rx(scatterIdx)), ...
    '.', 'Color', [0.85 0.33 0.10], 'MarkerSize', 7);
axis equal; axis([-1.6 1.6 -1.6 1.6]); grid on;
title('接收端加噪复包络轨迹');
xlabel('In-phase');
ylabel('Quadrature');

saveFigureIfNeeded(fig, cfg, '08_AWGN_channel_effect');
end


function plotCorrelationDecisionExample(sim, cfg)
% 相干相关检测示意：corr1-corr0 大于 0 判 1，小于 0 判 0。

snrDb = cfg.exampleEbNoDb - 10 * log10(cfg.nsamp);
rx = localAwgnMeasured(sim.mskBaseband, snrDb);
Nshow = min(32, cfg.NBitsSystem);
metric = zeros(1, Nshow);
rxData = zeros(1, Nshow);

for k = 1:Nshow
    idx = (k - 1) * cfg.nsamp + 1 : k * cfg.nsamp;
    tau = sim.t(idx) - sim.t(idx(1));
    phiStart = sim.phaseBaseband(idx(1));

    ref1 = exp(1j * (phiStart + 2 * pi * (cfg.deltaF / 2) * tau));
    ref0 = exp(1j * (phiStart - 2 * pi * (cfg.deltaF / 2) * tau));

    corr1 = real(rx(idx) * ref1');
    corr0 = real(rx(idx) * ref0');
    metric(k) = corr1 - corr0;
    rxData(k) = metric(k) > 0;
end

fig = figure('Name', '相干相关检测与判决示例', ...
    'Position', [200, 200, 1050, 580], 'Color', cfg.figureColor);

subplot(2, 1, 1);
stem(1:Nshow, metric, 'filled', 'LineWidth', 1.2); hold on;
yline(0, 'k--', '判决门限', 'LineWidth', 1.1);
title(sprintf('相关检测统计量 corr_1 - corr_0（E_b/N_0 = %g dB）', cfg.exampleEbNoDb));
xlabel('码元序号 k');
ylabel('相关差值');
grid on;

subplot(2, 1, 2);
stairs(1:Nshow, sim.data(1:Nshow), 'b', 'LineWidth', 1.6); hold on;
stairs(1:Nshow, rxData, 'r--', 'LineWidth', 1.4);
ylim([-0.3 1.3]);
title('发送比特与判决恢复比特对比');
xlabel('码元序号 k');
ylabel('比特值');
legend('发送比特', '恢复比特', 'Location', 'best');
grid on;

saveFigureIfNeeded(fig, cfg, '09_coherent_correlation_decision');
end


function [Pxx, f] = localWelchCentered(x, winLength, noverlap, nfft, fs)
% 简化 Welch PSD，输出 centered 频率轴，避免依赖 pwelch。

x = x(:);
winLength = min(winLength, numel(x));
noverlap = min(noverlap, winLength - 1);
step = winLength - noverlap;

if step <= 0
    error('Welch 参数错误：window length 必须大于 overlap。');
end

n = (0:winLength - 1).';
window = 0.54 - 0.46 * cos(2 * pi * n / (winLength - 1)); % Hamming window
starts = 1:step:(numel(x) - winLength + 1);

Pacc = zeros(nfft, 1);
for s = starts
    segment = x(s:s + winLength - 1);
    segment = segment - mean(segment);
    X = fft(segment .* window, nfft);
    Pacc = Pacc + abs(X) .^ 2 / (fs * sum(window .^ 2));
end

Pxx = fftshift(Pacc / numel(starts));
f = (-nfft / 2:nfft / 2 - 1).' * (fs / nfft);
end


function y = localAwgnMeasured(x, snrDb)
% measured AWGN，不依赖 Communications Toolbox 的 awgn 函数。

signalPower = mean(abs(x(:)) .^ 2);
noisePower = signalPower / (10 ^ (snrDb / 10));

if isreal(x)
    noise = sqrt(noisePower) * randn(size(x));
else
    noise = sqrt(noisePower / 2) * (randn(size(x)) + 1j * randn(size(x)));
end

y = x + noise;
end


function drawSymbolGrid(ax, N, Tb)
% 在每个码元边界画虚线。

yl = ylim(ax);
for k = 0:N
    plot(ax, [k * Tb, k * Tb], yl, 'k--', 'LineWidth', 0.5);
end
ylim(ax, yl);
end


function formatPiTicks(ax, phaseByPi)
minP = floor(min(phaseByPi) * 2) / 2;
maxP = ceil(max(phaseByPi) * 2) / 2;
tickVals = minP:0.5:maxP;
labels = cell(size(tickVals));

for i = 1:numel(tickVals)
    v = tickVals(i);
    if abs(v) < eps
        labels{i} = '0';
    elseif abs(v - 1) < eps
        labels{i} = '\pi';
    elseif abs(v + 1) < eps
        labels{i} = '-\pi';
    else
        labels{i} = sprintf('%.1f\\pi', v);
    end
end

set(ax, 'YTick', tickVals, 'YTickLabel', labels);
end


function saveFigureIfNeeded(figHandle, cfg, fileBase)
% 自动导出 PNG，方便直接放进 PPT。

if ~isfield(cfg, 'saveFiguresAsPng') || ~cfg.saveFiguresAsPng
    return;
end

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

fileName = fullfile(cfg.outputDir, [fileBase, '.png']);

try
    if exist('exportgraphics', 'file') || exist('exportgraphics', 'builtin')
        exportgraphics(figHandle, fileName, 'Resolution', 220);
    else
        saveas(figHandle, fileName);
    end
catch
    saveas(figHandle, fileName);
end
end


function writeGifFrame(figHandle, fileName, frameIndex, delayTime)
frameImage = frame2im(getframe(figHandle));
[indexedImage, colorMap] = rgb2ind(frameImage, 256);

if frameIndex == 1
    imwrite(indexedImage, colorMap, fileName, 'gif', ...
        'Loopcount', inf, 'DelayTime', delayTime);
else
    imwrite(indexedImage, colorMap, fileName, 'gif', ...
        'WriteMode', 'append', 'DelayTime', delayTime);
end
end
