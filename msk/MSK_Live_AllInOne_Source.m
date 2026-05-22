%% MSK 通信系统实时观察脚本（完整单文件版）
% 本实时脚本把完整 MSK 仿真代码和所有本地函数都写在同一个文件里。
% 运行后可在 Live Editor 右侧观察波形、频谱、BER、星座图和动图导出过程。
%
% 输出文件夹：MSK_Output_Figures

clear; clc; close all;
thisFile = mfilename('fullpath');
if isempty(thisFile)
    projectDir = pwd;
else
    projectDir = fileparts(thisFile);
end
cd(projectDir);
addpath(projectDir);
fprintf('当前工程目录：%s\n', projectDir);
fprintf('这是完整单文件实时脚本，不再调用 MSK_Integrated_Demo。\n\n');

%% 一键运行完整 MSK 仿真
cfg = defaultMskConfig();
rng(cfg.randomSeed);

if cfg.saveFiguresAsPng && ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end
writeMskParameterSummary(cfg);

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

if cfg.runParameterAnalysis
    plotMskParameterVariation(cfg);
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
    plotConstellationDiagram(demo, sim, cfg);
    plotPhaseContinuityComparison(demo, cfg);
    plotNoisyChannelExample(sim, cfg);
    plotCorrelationDecisionExample(sim, cfg);
end

% ====== 四、将主要效果图导出为动图 GIF ======
if cfg.exportEffectGifs
    if ~exist('sim', 'var')
        sim = buildCpfskMskSimulation(cfg);
    end
    if ~exist('berSim', 'var') || ~exist('berTheory', 'var')
        [berSim, berTheory] = simulateMskBer(sim, cfg);
    end
    exportEffectGalleryGifs(demo, sim, cfg, berSim, berTheory);
end

disp('MSK 综合仿真运行完成。');

%% 本地函数区
% 下面的函数都属于本实时脚本自身，不需要外部主程序。
function cfg = defaultMskConfig()
% 所有参数统一放在这里，后续改报告图或仿真规模只改本段即可。

cfg.Rb = 1000;                    % 码元速率 / 比特率 (bps)
cfg.Tb = 1 / cfg.Rb;              % 码元周期 (s)
cfg.fc = 4000;                    % 载波频率 (Hz)
cfg.fs = 32000;                   % 采样频率 (Hz)
cfg.nsamp = cfg.fs / cfg.Rb;      % 每比特采样点数
cfg.deltaF = 1 / (2 * cfg.Tb);    % 两个频率状态的最小间隔 f1-f0
cfg.freqDeviation = cfg.deltaF / 2; % 单边频偏 fd=(f1-f0)/2
cfg.modIndex = 2 * cfg.freqDeviation / cfg.Rb; % MSK 调制指数 h=0.5
cfg.fHigh = cfg.fc + cfg.freqDeviation;
cfg.fLow = cfg.fc - cfg.freqDeviation;

cfg.demoBits = [1 0 1 1 0 1 0 1]; % 用于波形展示的短码流
cfg.randomSeed = 7;

cfg.showStaticWaveforms = true;
cfg.exportGifs = false;           % 需要重新生成 GIF 时改为 true
cfg.runSpectrumAnalysis = true;
cfg.runBerAnalysis = true;
cfg.showEffectGallery = true;     % 根据总流程图补充更多效果图
cfg.runParameterAnalysis = true;  % 输出 Rb 等参数变化对波形/频谱的影响
cfg.saveFiguresAsPng = true;      % 自动导出 PNG，便于放进 PPT
cfg.exportEffectGifs = false;     % 需要重新生成效果 GIF 时改为 true
cfg.outputDir = 'MSK_Output_Figures';

cfg.gifFrames = 60;
cfg.effectGifFrames = 36;
cfg.gifDuration = 2.0;            % 每个 GIF 动画总时长约 2 秒
cfg.waveGifFile = fullfile(cfg.outputDir, '01_MSK_waveforms_animated.gif');
cfg.phaseGifFile = fullfile(cfg.outputDir, '02_MSK_phase_trellis_animated.gif');

cfg.NBitsSystem = 50000;          % BER/频谱仿真比特数，越大 BER 曲线越平滑
cfg.EbNoDbVec = 0:1:10;
cfg.exampleEbNoDb = 12;           % 信道/相关检测示例图使用的 Eb/N0
cfg.psdNfft = 2048;
cfg.psdWindowLength = 2048;
cfg.psdOverlap = 1024;
cfg.parameterRbVec = [500 1000 2000]; % 参数分析：比较不同码元速率
cfg.parameterFcVec = [3000 4000 5000]; % 参数分析：比较不同载波频率
cfg.parameterStudyBits = 4096;    % 参数分析使用较短序列，保证运行速度

cfg.figureColor = 'w';

if abs(cfg.nsamp - round(cfg.nsamp)) > eps
    error('fs/Rb 必须为整数，当前 fs/Rb = %.4f。', cfg.nsamp);
end
cfg.nsamp = round(cfg.nsamp);
end


function writeMskParameterSummary(cfg)
% 把报告中需要说明的 MSK 参数关系写成文本，便于直接整理到 PPT/报告。

if ~cfg.saveFiguresAsPng
    return;
end

fileName = fullfile(cfg.outputDir, '00_MSK_parameter_summary.txt');
fid = fopen(fileName, 'w', 'n', 'UTF-8');
if fid < 0
    warning('无法写入参数说明文件：%s', fileName);
    return;
end

fprintf(fid, '2MSK 数字通信系统参数说明\n');
fprintf(fid, '========================\n\n');
fprintf(fid, '基本参数：\n');
fprintf(fid, 'Rb = %.0f bps，Tb = 1/Rb = %.6g s\n', cfg.Rb, cfg.Tb);
fprintf(fid, 'fc = %.0f Hz，fs = %.0f Hz，nsamp = fs/Rb = %.0f\n', cfg.fc, cfg.fs, cfg.nsamp);
fprintf(fid, '两个频率状态间隔：Delta_f = f1 - f0 = 1/(2Tb) = Rb/2 = %.0f Hz\n', cfg.deltaF);
fprintf(fid, '单边频偏：fd = Delta_f/2 = 1/(4Tb) = %.0f Hz\n', cfg.freqDeviation);
fprintf(fid, '频率状态：f1 = fc + fd = %.0f Hz，f0 = fc - fd = %.0f Hz\n', cfg.fHigh, cfg.fLow);
fprintf(fid, '调制指数：h = 2fd/Rb = %.2f。MSK 要求 h = 0.5。\n\n', cfg.modIndex);
fprintf(fid, '参数影响：\n');
fprintf(fid, '1. Rb 增大时，Tb 变短，Delta_f = Rb/2 增大，波形变化更快，频谱主瓣变宽。\n');
fprintf(fid, '2. fc 只改变频谱中心位置，不改变基带频谱形状和理论 BER。\n');
fprintf(fid, '3. fs 决定离散仿真的采样密度，nsamp=fs/Rb 应为整数；nsamp 太小会导致波形和频谱显示失真。\n');
fprintf(fid, '4. Eb/N0 增大时，AWGN 扰动减小，接收判决更稳定，BER 下降。\n');
fprintf(fid, '5. NBitsSystem 越大，Monte Carlo 统计越稳定，低 BER 区域曲线越平滑。\n');

fclose(fid);
end


function cfgVar = retuneMskConfig(cfg, Rb, fc)
% 在保持 MSK h=0.5 的前提下，按新的 Rb/fc 重算相关参数。

cfgVar = cfg;
cfgVar.Rb = Rb;
cfgVar.Tb = 1 / cfgVar.Rb;
cfgVar.fc = fc;
cfgVar.nsamp = cfgVar.fs / cfgVar.Rb;
cfgVar.deltaF = 1 / (2 * cfgVar.Tb);
cfgVar.freqDeviation = cfgVar.deltaF / 2;
cfgVar.modIndex = 2 * cfgVar.freqDeviation / cfgVar.Rb;
cfgVar.fHigh = cfgVar.fc + cfgVar.freqDeviation;
cfgVar.fLow = cfgVar.fc - cfgVar.freqDeviation;

if abs(cfgVar.nsamp - round(cfgVar.nsamp)) > eps
    error('参数分析中 fs/Rb 必须为整数，当前 Rb=%g, fs/Rb=%.4f。', ...
        cfgVar.Rb, cfgVar.nsamp);
end
cfgVar.nsamp = round(cfgVar.nsamp);
end


function plotMskParameterVariation(cfg)
% 改变 Rb 和 fc，观察它们对 MSK 波形与频谱的影响。

studyBits = randi([0 1], 1, cfg.parameterStudyBits);

fig = figure('Name', 'MSK 参数变化影响：码元速率', ...
    'Position', [120, 80, 1050, 720], 'Color', cfg.figureColor);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on;
offsetStep = 2.4;

for i = 1:numel(cfg.parameterRbVec)
    cfgRb = retuneMskConfig(cfg, cfg.parameterRbVec(i), cfg.fc);
    demoRb = buildMskIqDemo(cfg.demoBits, cfgRb);
    offset = (numel(cfg.parameterRbVec) - i) * offsetStep;
    plot(demoRb.t * 1e3, demoRb.mskSignal + offset, 'LineWidth', 1.2);
end
grid on;
xlabel('时间 (ms)');
ylabel('归一化波形（垂直错开）');
title('码元速率 R_b 改变：T_b=1/R_b，波形时间尺度随 R_b 变化');
legend(arrayfun(@(x) sprintf('R_b = %d bps', x), cfg.parameterRbVec, ...
    'UniformOutput', false), 'Location', 'northeast');

nexttile;
hold on;
for i = 1:numel(cfg.parameterRbVec)
    cfgRb = retuneMskConfig(cfg, cfg.parameterRbVec(i), cfg.fc);
    simRb = buildCpfskMskSimulation(cfgRb, studyBits);
    [Pxx, f] = localWelchCentered(simRb.mskBaseband, ...
        cfgRb.psdWindowLength, cfgRb.psdOverlap, cfgRb.psdNfft, cfgRb.fs);
    y = 10 * log10(Pxx / max(Pxx) + eps);
    plot(f, y, 'LineWidth', 1.4);
end
grid on;
xlabel('基带频率 (Hz)');
ylabel('归一化 PSD (dB)');
title('码元速率 R_b 改变：\Delta f = R_b/2，R_b 越大频谱越宽');
xlim([-3500 3500]);
ylim([-80 5]);
legend(arrayfun(@(x) sprintf('R_b=%d, \\Delta f=%d Hz', x, x/2), ...
    cfg.parameterRbVec, 'UniformOutput', false), 'Location', 'southwest');

saveFigureIfNeeded(fig, cfg, '11_MSK_parameter_Rb_effect');

fig = figure('Name', 'MSK 参数变化影响：载波频率', ...
    'Position', [180, 120, 1000, 500], 'Color', cfg.figureColor);
hold on;
for i = 1:numel(cfg.parameterFcVec)
    cfgFc = retuneMskConfig(cfg, cfg.Rb, cfg.parameterFcVec(i));
    simFc = buildCpfskMskSimulation(cfgFc, studyBits);
    [Pxx, f] = localWelchCentered(simFc.mskPassband, ...
        cfgFc.psdWindowLength, cfgFc.psdOverlap, cfgFc.psdNfft, cfgFc.fs);
    positiveIdx = f >= 0;
    y = 10 * log10(Pxx / max(Pxx) + eps);
    plot(f(positiveIdx), y(positiveIdx), 'LineWidth', 1.4);
end
grid on;
xlabel('频率 (Hz)');
ylabel('归一化 PSD (dB)');
title('载波频率 f_c 改变：频谱整体平移，基带形状基本不变');
xlim([1500 6500]);
ylim([-80 5]);
legend(arrayfun(@(x) sprintf('f_c = %d Hz', x), cfg.parameterFcVec, ...
    'UniformOutput', false), 'Location', 'southwest');

saveFigureIfNeeded(fig, cfg, '12_MSK_parameter_fc_shift');
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


function sim = buildCpfskMskSimulation(cfg, data)
% 系统级 MSK/2FSK 信号生成。
% 频谱图使用 passband 实信号；BER 使用等效 complex baseband 信号。

if nargin < 2
    data = randi([0 1], 1, cfg.NBitsSystem);
else
    cfg.NBitsSystem = numel(data);
end
dataNrz = 2 * data - 1;
dev = dataNrz * cfg.freqDeviation;
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

        ref1 = exp(1j * (phiStart + 2 * pi * cfg.freqDeviation * tau));
        ref0 = exp(1j * (phiStart - 2 * pi * cfg.freqDeviation * tau));

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

freqPerBit = cfg.fc + demo.dataNrz * cfg.freqDeviation;
tBit = (0:demo.N - 1) * cfg.Tb;

fig = figure('Name', 'MSK 瞬时频率分析', ...
    'Position', [120, 120, 900, 480], 'Color', cfg.figureColor);
stairs(tBit, freqPerBit, 'b', 'LineWidth', 2); hold on;
yline(cfg.fc, 'k-', 'f_c', 'LineWidth', 1.2);
yline(cfg.fHigh, 'r--', 'f_c+f_d', 'LineWidth', 1.1);
yline(cfg.fLow, 'r--', 'f_c-f_d', 'LineWidth', 1.1);
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


function plotConstellationDiagram(demo, sim, cfg)
% MSK 不像 QPSK 那样只有固定星座点；它的复包络是连续相位轨迹。
% 这里同时给出“理想轨迹 + 码元采样点”和“AWGN 后散点”。

cleanDemo = demo.IBaseband + 1j * demo.QBaseband;
rxDemo = localAwgnMeasured(cleanDemo, cfg.exampleEbNoDb);
sampleIdx = cfg.nsamp:cfg.nsamp:numel(cleanDemo);
unitCircle = exp(1j * linspace(0, 2*pi, 400));
boundaryStates = [1, 1j, -1, -1j];

rxSystem = localAwgnMeasured(sim.mskBaseband, cfg.exampleEbNoDb);
symbolScatterIdx = cfg.nsamp:cfg.nsamp:numel(rxSystem);
symbolScatterIdx = symbolScatterIdx(1:min(220, numel(symbolScatterIdx)));

fig = figure('Name', 'MSK 星座图与连续相位轨迹', ...
    'Position', [150, 120, 1100, 500], 'Color', cfg.figureColor);

subplot(1, 2, 1);
plot(real(unitCircle), imag(unitCircle), '--', ...
    'Color', [0.55 0.55 0.55], 'LineWidth', 1.2); hold on;
plot(real(cleanDemo), imag(cleanDemo), 'b', 'LineWidth', 1.8); hold on;
plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
    'MarkerSize', 7, 'MarkerFaceColor', 'r');
plot(real(cleanDemo(sampleIdx)), imag(cleanDemo(sampleIdx)), 'o', ...
    'Color', [0.85 0.33 0.10], 'MarkerSize', 5, 'LineWidth', 1.2);
text(1.06, 0, '+I', 'FontSize', 10);
text(-1.22, 0, '-I', 'FontSize', 10);
text(0.03, 1.10, '+Q', 'FontSize', 10);
text(0.03, -1.16, '-Q', 'FontSize', 10);
axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
title('完整可能轨迹 + 当前码流轨迹');
xlabel('I');
ylabel('Q');
legend('MSK 可能连续轨迹', '当前码流轨迹', ...
    '四个码元边界状态', '当前码流采样点', 'Location', 'best');

subplot(1, 2, 2);
plot(real(rxSystem(symbolScatterIdx)), imag(rxSystem(symbolScatterIdx)), '.', ...
    'Color', [0.85 0.33 0.10], 'MarkerSize', 10); hold on;
plot(real(rxDemo(sampleIdx)), imag(rxDemo(sampleIdx)), 'go', ...
    'MarkerSize', 7, 'LineWidth', 1.3);
plot(real(unitCircle), imag(unitCircle), 'k--', 'LineWidth', 1);
plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
    'MarkerSize', 7, 'MarkerFaceColor', 'r');
axis equal; axis([-1.8 1.8 -1.8 1.8]); grid on;
title(sprintf('加噪星座散点（E_b/N_0 = %g dB）', cfg.exampleEbNoDb));
xlabel('I');
ylabel('Q');
legend('接收散点', '当前采样点', '理想包络', ...
    '四个边界状态', 'Location', 'best');

saveFigureIfNeeded(fig, cfg, '10_MSK_constellation');
end


function plotPhaseContinuityComparison(demo, cfg)
% 连续相位 MSK 与普通 2FSK 的基带相位对比。

dev = demo.dataNrz * cfg.freqDeviation;
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
% AWGN 信道示例：展示 clean / noisy 波形、连续相位轨迹和判决采样点。
% 这里用于 PPT 可视化，直接使用 cfg.exampleEbNoDb 作为显示信噪比；
% BER 统计函数中仍然保留按每比特能量折算的噪声设置。

snrDb = cfg.exampleEbNoDb;
rx = localAwgnMeasured(sim.mskBaseband, snrDb);
showBits = 8;
idx = 1:min(showBits * cfg.nsamp, numel(sim.t));
trajIdx = idx(1):3:idx(end);
symbolIdx = cfg.nsamp:cfg.nsamp:min(80 * cfg.nsamp, numel(sim.t));
unitCircle = exp(1j * linspace(0, 2*pi, 360));
boundaryStates = [1, 1j, -1, -1j];

fig = figure('Name', 'AWGN 信道效果示例', ...
    'Position', [160, 150, 1080, 620], 'Color', cfg.figureColor);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile([1 2]);
plot(sim.t(idx) * 1e3, real(sim.mskBaseband(idx)), 'b', 'LineWidth', 1.7); hold on;
plot(sim.t(idx) * 1e3, real(rx(idx)), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0);
title(sprintf('AWGN 信道前后波形对比（展示 SNR = %g dB）', snrDb));
xlabel('时间 (ms)');
ylabel('实部幅度');
legend('发送基带信号', '加噪接收信号', 'Location', 'best');
grid on;
ylim([-1.55 1.55]);

nexttile;
plot(real(unitCircle), imag(unitCircle), '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.1); hold on;
plot(real(sim.mskBaseband(trajIdx)), imag(sim.mskBaseband(trajIdx)), ...
    'b-', 'LineWidth', 1.8);
plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
    'MarkerSize', 7, 'MarkerFaceColor', 'r');
axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
title('发送端：恒包络连续相位轨迹');
xlabel('I');
ylabel('Q');

nexttile;
plot(real(unitCircle), imag(unitCircle), '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.1); hold on;
plot(real(rx(trajIdx)), imag(rx(trajIdx)), '.', ...
    'Color', [0.85 0.33 0.10], 'MarkerSize', 7);
plot(real(rx(symbolIdx)), imag(rx(symbolIdx)), 'o', ...
    'Color', [0.00 0.62 0.36], 'MarkerSize', 5, 'LineWidth', 1.0);
plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
    'MarkerSize', 7, 'MarkerFaceColor', 'r');
axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
title('接收端：噪声扰动与判决采样点');
xlabel('I');
ylabel('Q');
legend('理想包络', '加噪轨迹', '判决采样点', '边界状态', 'Location', 'southoutside', ...
    'Orientation', 'horizontal');

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

    ref1 = exp(1j * (phiStart + 2 * pi * cfg.freqDeviation * tau));
    ref0 = exp(1j * (phiStart - 2 * pi * cfg.freqDeviation * tau));

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


function exportEffectGalleryGifs(demo, sim, cfg, berSim, berTheory)
% 按总流程图导出更多动图，便于 PPT 演示。

if ~exist(cfg.outputDir, 'dir')
    mkdir(cfg.outputDir);
end

fprintf('正在导出扩展效果 GIF，请稍候...\n');
exportConstellationGif(demo, sim, cfg);
exportInstantaneousFrequencyGif(demo, cfg);
exportPsdGif(sim, cfg);
exportBerGif(cfg.EbNoDbVec, berSim, berTheory, cfg);
exportIqEnvelopeGif(demo, cfg);
exportAwgnGif(sim, cfg);
exportCorrelationDecisionGif(sim, cfg);
exportPhaseComparisonGif(demo, cfg);
fprintf('扩展效果 GIF 导出完成。\n');
end


function exportConstellationGif(demo, sim, cfg)
cleanDemo = demo.IBaseband + 1j * demo.QBaseband;
rxDemo = localAwgnMeasured(cleanDemo, cfg.exampleEbNoDb - 10 * log10(cfg.nsamp));
sampleIdx = cfg.nsamp:cfg.nsamp:numel(cleanDemo);
rxSystem = localAwgnMeasured(sim.mskBaseband, cfg.exampleEbNoDb - 10 * log10(cfg.nsamp));
scatterIdx = 1:min(3500, numel(rxSystem));
circle = exp(1j * linspace(0, 2*pi, 360));
boundaryStates = [1, 1j, -1, -1j];

fileName = fullfile(cfg.outputDir, '10_MSK_constellation_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', 'MSK 星座图动图', ...
    'Position', [150, 120, 1100, 520], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    idx = max(2, round(frame * numel(cleanDemo) / cfg.effectGifFrames));
    scIdx = scatterIdx(1:max(2, round(frame * numel(scatterIdx) / cfg.effectGifFrames)));
    crossed = sampleIdx(sampleIdx <= idx);

    clf(fig);
    subplot(1, 2, 1);
    plot(real(circle), imag(circle), '--', ...
        'Color', [0.55 0.55 0.55], 'LineWidth', 1.2); hold on;
    plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
        'MarkerSize', 7, 'MarkerFaceColor', 'r');
    plot(real(cleanDemo(1:idx)), imag(cleanDemo(1:idx)), 'b', 'LineWidth', 2);
    if ~isempty(crossed)
        plot(real(cleanDemo(crossed)), imag(cleanDemo(crossed)), 'o', ...
            'Color', [0.85 0.33 0.10], 'MarkerSize', 6, 'LineWidth', 1.3);
    end
    text(1.06, 0, '+I', 'FontSize', 10);
    text(-1.22, 0, '-I', 'FontSize', 10);
    text(0.03, 1.10, '+Q', 'FontSize', 10);
    text(0.03, -1.16, '-Q', 'FontSize', 10);
    axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
    title('MSK 星座：完整可能轨迹 + 当前轨迹');
    xlabel('I'); ylabel('Q');

    subplot(1, 2, 2);
    plot(real(circle), imag(circle), 'k--', 'LineWidth', 1); hold on;
    plot(real(boundaryStates), imag(boundaryStates), 'ro', ...
        'MarkerSize', 7, 'MarkerFaceColor', 'r');
    plot(real(rxSystem(scIdx)), imag(rxSystem(scIdx)), '.', ...
        'Color', [0.85 0.33 0.10], 'MarkerSize', 6);
    if ~isempty(crossed)
        plot(real(rxDemo(crossed)), imag(rxDemo(crossed)), 'go', ...
            'MarkerSize', 7, 'LineWidth', 1.3);
    end
    axis equal; axis([-1.8 1.8 -1.8 1.8]); grid on;
    title(sprintf('AWGN 后星座散点（E_b/N_0 = %g dB）', cfg.exampleEbNoDb));
    xlabel('I'); ylabel('Q');

    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportInstantaneousFrequencyGif(demo, cfg)
freqPerBit = cfg.fc + demo.dataNrz * cfg.freqDeviation;
tBit = (0:demo.N - 1) * cfg.Tb;
fileName = fullfile(cfg.outputDir, '05_MSK_instantaneous_frequency_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', '瞬时频率动图', ...
    'Position', [120, 120, 900, 480], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    n = max(1, ceil(frame * demo.N / cfg.effectGifFrames));
    clf(fig);
    stairs(tBit(1:n), freqPerBit(1:n), 'b', 'LineWidth', 2); hold on;
    yline(cfg.fc, 'k-', 'f_c', 'LineWidth', 1.2);
    yline(cfg.fHigh, 'r--', 'f_c+f_d', 'LineWidth', 1.1);
    yline(cfg.fLow, 'r--', 'f_c-f_d', 'LineWidth', 1.1);
    drawSymbolGrid(gca, demo.N, cfg.Tb);
    title('MSK 瞬时频率动态变化');
    xlabel('时间 (s)'); ylabel('瞬时频率 (Hz)');
    xlim([0 demo.N * cfg.Tb]);
    ylim([cfg.fc - cfg.deltaF, cfg.fc + cfg.deltaF]);
    grid on;
    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportPsdGif(sim, cfg)
[Pmsk, f] = localWelchCentered(sim.mskPassband, ...
    cfg.psdWindowLength, cfg.psdOverlap, cfg.psdNfft, cfg.fs);
[Pfsk, ~] = localWelchCentered(sim.fskPassband, ...
    cfg.psdWindowLength, cfg.psdOverlap, cfg.psdNfft, cfg.fs);

yMsk = 10 * log10(Pmsk + eps);
yFsk = 10 * log10(Pfsk + eps);
fileName = fullfile(cfg.outputDir, '03_MSK_vs_2FSK_PSD_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', 'PSD 对比动图', ...
    'Position', [100, 100, 900, 460], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    n = max(2, round(frame * numel(f) / cfg.effectGifFrames));
    clf(fig);
    plot(f(1:n), yMsk(1:n), 'b', 'LineWidth', 1.6); hold on;
    plot(f(1:n), yFsk(1:n), 'r--', 'LineWidth', 1.2);
    title('功率谱密度对比动态绘制');
    xlabel('频率 (Hz)'); ylabel('功率谱密度 (dB/Hz)');
    xlim([-8000 8000]); ylim([-120 -20]);
    legend('MSK 信号', '普通 2FSK 信号', 'Location', 'best');
    grid on;
    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportBerGif(EbNoDbVec, berSim, berTheory, cfg)
fileName = fullfile(cfg.outputDir, '04_MSK_BER_performance_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', 'BER 动图', ...
    'Position', [1040, 100, 650, 520], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    n = max(1, ceil(frame * numel(EbNoDbVec) / cfg.effectGifFrames));
    clf(fig);
    semilogy(EbNoDbVec, berTheory, 'Color', [0.55 0.65 1.0], ...
        'LineWidth', 1.4); hold on;
    semilogy(EbNoDbVec(1:n), berTheory(1:n), 'b-', 'LineWidth', 2.2);
    semilogy(EbNoDbVec(1:n), berSim(1:n), 'ro', ...
        'MarkerSize', 7, 'LineWidth', 1.5);
    grid on;
    xlabel('E_b/N_0 (dB)');
    ylabel('误码率 BER');
    legend('理论曲线全貌', '理论 BER', '仿真 BER', 'Location', 'southwest');
    title('BER 随 E_b/N_0 增大的动态变化');
    ylim([1e-5 1]);
    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportAwgnGif(sim, cfg)
fileName = fullfile(cfg.outputDir, '08_AWGN_channel_effect_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
showBits = 8;
idx = 1:min(showBits * cfg.nsamp, numel(sim.t));
scatterIdx = 1:min(2500, numel(sim.t));
ebNoFrames = linspace(0, max(cfg.EbNoDbVec), cfg.effectGifFrames);
fig = figure('Name', 'AWGN 信道动图', ...
    'Position', [180, 180, 1050, 620], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    rng(cfg.randomSeed + frame);
    ebNo = ebNoFrames(frame);
    rx = localAwgnMeasured(sim.mskBaseband, ebNo - 10 * log10(cfg.nsamp));

    clf(fig);
    subplot(2, 1, 1);
    plot(sim.t(idx), real(sim.mskBaseband(idx)), 'b', 'LineWidth', 1.5); hold on;
    plot(sim.t(idx), real(rx(idx)), 'Color', [0.85 0.33 0.10], 'LineWidth', 1.0);
    title(sprintf('AWGN 信道：E_b/N_0 = %.1f dB', ebNo));
    xlabel('时间 (s)'); ylabel('实部幅度');
    legend('发送基带信号', '加噪接收信号', 'Location', 'best');
    grid on;

    subplot(2, 2, 3);
    plot(real(sim.mskBaseband(scatterIdx)), imag(sim.mskBaseband(scatterIdx)), ...
        '.', 'Color', [0.10 0.35 0.75], 'MarkerSize', 7);
    axis equal; axis([-1.8 1.8 -1.8 1.8]); grid on;
    title('发送端复包络轨迹');
    xlabel('I'); ylabel('Q');

    subplot(2, 2, 4);
    plot(real(rx(scatterIdx)), imag(rx(scatterIdx)), ...
        '.', 'Color', [0.85 0.33 0.10], 'MarkerSize', 7);
    axis equal; axis([-1.8 1.8 -1.8 1.8]); grid on;
    title('接收端加噪散点');
    xlabel('I'); ylabel('Q');

    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
rng(cfg.randomSeed);
end


function exportIqEnvelopeGif(demo, cfg)
cleanDemo = demo.IBaseband + 1j * demo.QBaseband;
envelope = abs(cleanDemo);
sampleIdx = cfg.nsamp:cfg.nsamp:numel(cleanDemo);
circle = exp(1j * linspace(0, 2*pi, 360));

fileName = fullfile(cfg.outputDir, '06_MSK_IQ_plane_and_envelope_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', 'I/Q 轨迹与恒包络动图', ...
    'Position', [140, 140, 1050, 480], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    idx = max(2, round(frame * numel(cleanDemo) / cfg.effectGifFrames));
    crossed = sampleIdx(sampleIdx <= idx);

    clf(fig);
    subplot(1, 2, 1);
    plot(real(circle), imag(circle), 'k--', 'LineWidth', 1); hold on;
    plot(real(cleanDemo(1:idx)), imag(cleanDemo(1:idx)), 'b', 'LineWidth', 1.8);
    if ~isempty(crossed)
        plot(real(cleanDemo(crossed)), imag(cleanDemo(crossed)), 'ro', ...
            'MarkerSize', 6, 'MarkerFaceColor', 'r');
    end
    axis equal; axis([-1.25 1.25 -1.25 1.25]); grid on;
    title('I/Q 相位平面轨迹');
    xlabel('I(t)'); ylabel('Q(t)');

    subplot(1, 2, 2);
    plot(demo.t(1:idx), envelope(1:idx), 'm', 'LineWidth', 1.8); hold on;
    yline(1, 'k--', '理想恒包络', 'LineWidth', 1.1);
    drawSymbolGrid(gca, demo.N, cfg.Tb);
    xlim([0 max(demo.t)]);
    ylim([0 1.25]);
    title('恒包络随时间保持稳定');
    xlabel('时间 (s)'); ylabel('包络幅度');
    grid on;

    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportCorrelationDecisionGif(sim, cfg)
snrDb = cfg.exampleEbNoDb - 10 * log10(cfg.nsamp);
rx = localAwgnMeasured(sim.mskBaseband, snrDb);
Nshow = min(32, cfg.NBitsSystem);
metric = zeros(1, Nshow);
rxData = zeros(1, Nshow);

for k = 1:Nshow
    idx = (k - 1) * cfg.nsamp + 1 : k * cfg.nsamp;
    tau = sim.t(idx) - sim.t(idx(1));
    phiStart = sim.phaseBaseband(idx(1));
    ref1 = exp(1j * (phiStart + 2 * pi * cfg.freqDeviation * tau));
    ref0 = exp(1j * (phiStart - 2 * pi * cfg.freqDeviation * tau));
    corr1 = real(rx(idx) * ref1');
    corr0 = real(rx(idx) * ref0');
    metric(k) = corr1 - corr0;
    rxData(k) = metric(k) > 0;
end

fileName = fullfile(cfg.outputDir, '09_coherent_correlation_decision_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', '相干相关检测动图', ...
    'Position', [200, 200, 1050, 580], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    n = max(1, ceil(frame * Nshow / cfg.effectGifFrames));
    clf(fig);
    subplot(2, 1, 1);
    stem(1:n, metric(1:n), 'filled', 'LineWidth', 1.2); hold on;
    yline(0, 'k--', '判决门限', 'LineWidth', 1.1);
    xlim([1 Nshow]); grid on;
    title('相关检测统计量逐码元输出：corr_1 - corr_0');
    xlabel('码元序号 k'); ylabel('相关差值');

    subplot(2, 1, 2);
    stairs(1:Nshow, sim.data(1:Nshow), 'Color', [0.65 0.75 1.0], ...
        'LineWidth', 1.2); hold on;
    stairs(1:n, rxData(1:n), 'r--', 'LineWidth', 1.6);
    ylim([-0.3 1.3]); xlim([1 Nshow]); grid on;
    title('判决恢复比特逐步出现');
    xlabel('码元序号 k'); ylabel('比特值');
    legend('发送比特', '已恢复比特', 'Location', 'best');

    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
end


function exportPhaseComparisonGif(demo, cfg)
dev = demo.dataNrz * cfg.freqDeviation;
devExt = repelem(dev, cfg.nsamp);
t = demo.t;
phaseMsk = 2 * pi * cumsum(devExt) / cfg.fs;
phaseFsk = 2 * pi * devExt .* t;
phaseMsk = phaseMsk - phaseMsk(1);
phaseFsk = phaseFsk - phaseFsk(1);

fileName = fullfile(cfg.outputDir, '07_MSK_phase_continuity_comparison_animated.gif');
delayTime = cfg.gifDuration / cfg.effectGifFrames;
fig = figure('Name', '相位连续性对比动图', ...
    'Position', [160, 160, 950, 500], 'Color', cfg.figureColor);

for frame = 1:cfg.effectGifFrames
    idx = max(2, round(frame * numel(t) / cfg.effectGifFrames));
    clf(fig);
    plot(t(1:idx), phaseMsk(1:idx) / pi, 'b', 'LineWidth', 2); hold on;
    plot(t(1:idx), phaseFsk(1:idx) / pi, 'r--', 'LineWidth', 1.5);
    drawSymbolGrid(gca, demo.N, cfg.Tb);
    title('相位连续性动态对比：MSK vs 普通 2FSK');
    xlabel('时间 (s)'); ylabel('基带相位 / \pi');
    legend('MSK 连续相位', '普通 2FSK 非连续相位', 'Location', 'best');
    xlim([0 max(t)]);
    ylim([min([phaseMsk phaseFsk]) / pi - 0.5, max([phaseMsk phaseFsk]) / pi + 0.5]);
    grid on;
    drawnow;
    writeGifFrame(fig, fileName, frame, delayTime);
end
close(fig);
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
