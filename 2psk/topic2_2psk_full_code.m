%% 第二题：2PSK 调制、相干解调与误码率分析
% 通信原理研讨第二题：二进制移相键控（2PSK/BPSK）调制原理
% 功能：
% 1. 产生随机二进制数据并生成 2PSK 调制波形
% 2. 观察并分析 2PSK 通带频谱
% 3. 在不同 Eb/N0 下加入 AWGN，采用相干解调并统计 BER
% 4. 与理论 BER 进行对比
% 5. 分析载波相位模糊对相干解调误码率的影响
%
% 说明：本脚本不依赖通信工具箱，直接运行即可。

clear; clc; close all;
rng(2026);

%% 0. 输出文件夹
rootDir = fileparts(mfilename('fullpath'));
outDir = fullfile(rootDir, 'outputs_full_code');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% 1. 基本参数
Tb = 1;                 % 归一化比特周期
Rb = 1 / Tb;            % 比特率
sps = 80;               % 每比特采样点数
fs = sps / Tb;          % 采样频率
fc = 2 * Rb;            % 载波频率，取 2 个周期/比特便于观察波形
Eb = 1;                 % 归一化比特能量
A = sqrt(2 * Eb / Tb);  % 通带信号幅度

numPlotBits = 24;       % 波形显示使用的比特数
numSpecBits = 1024;     % 频谱估计使用的比特数
numBerBits = 8e5;       % BER 蒙特卡洛仿真比特数
EbN0dB = -4:2:12;       % BER 扫描的 Eb/N0 范围

phaseEbN0dB = 6;        % 相位模糊分析使用的 Eb/N0
phaseDeg = [0 15 30 45 60 75 90 105 120 150 180];

%% 2. 生成随机比特与 2PSK 波形
bits = randi([0 1], 1, numPlotBits);
ak = 2 * bits - 1;                  % 比特 1 映射为 +1，比特 0 映射为 -1
baseband = repelem(ak, sps);
t = (0:length(baseband)-1) / fs;
carrier = cos(2*pi*fc*t);
s2psk = A * baseband .* carrier;

fig = figure('Color', 'w', 'Position', [80 80 1120 680]);
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle('2PSK 调制波形：随机比特、极性基带与通带信号', ...
    'FontName', 'Microsoft YaHei', 'FontSize', 15, 'FontWeight', 'bold');

nexttile;
stairs(t, repelem(bits, sps), 'k', 'LineWidth', 1.4);
grid on; box off; ylim([-0.2 1.2]);
xlabel('时间 / T_b'); ylabel('bit');
title('随机二进制数据', 'FontName', 'Microsoft YaHei');

nexttile;
stairs(t, baseband, 'Color', [0.12 0.39 0.70], 'LineWidth', 1.4);
grid on; box off; ylim([-1.35 1.35]);
xlabel('时间 / T_b'); ylabel('a_k');
title('极性基带码：0 -> -1，1 -> +1', 'FontName', 'Microsoft YaHei');

nexttile;
plot(t, s2psk, 'Color', [0.05 0.50 0.52], 'LineWidth', 1.0);
grid on; box off;
xlabel('时间 / T_b'); ylabel('幅度');
title('2PSK 通带调制信号', 'FontName', 'Microsoft YaHei');
set_all_axes_font('Microsoft YaHei');
exportgraphics(fig, fullfile(outDir, '01_2psk_waveform.png'), 'Resolution', 220);

%% 3. 计算 2PSK 信号频谱
bitsSpec = randi([0 1], 1, numSpecBits);
akSpec = 2 * bitsSpec - 1;
basebandSpec = repelem(akSpec, sps);
tSpec = (0:length(basebandSpec)-1) / fs;
sSpec = A * basebandSpec .* cos(2*pi*fc*tSpec);
[fAxis, specDb] = centered_spectrum(sSpec, fs);
specTrendDb = movmean(specDb, 15);

fig = figure('Color', 'w', 'Position', [80 80 1120 620]);
plot(fAxis/Rb, specDb, 'Color', [0.72 0.84 0.95], 'LineWidth', 0.55);
hold on;
plot(fAxis/Rb, specTrendDb, 'Color', [0.12 0.39 0.70], 'LineWidth', 1.35);
xline(fc/Rb, '--', 'f_c', 'Color', [0.70 0.18 0.24], ...
    'LineWidth', 1.1, 'LabelVerticalAlignment', 'top');
xline(-fc/Rb, '--', '-f_c', 'Color', [0.70 0.18 0.24], ...
    'LineWidth', 1.1, 'LabelVerticalAlignment', 'top');
grid on; box off; ylim([-82 5]); xlim([-20 20]);
xlabel('归一化频率 f / R_b'); ylabel('幅度 / dB');
title('2PSK 通带频谱', 'FontName', 'Microsoft YaHei', ...
    'FontSize', 15, 'FontWeight', 'bold');
subtitle('能量集中在载波附近；矩形码元成形会产生明显旁瓣', ...
    'FontName', 'Microsoft YaHei');
legend({'FFT 幅度谱', '平滑趋势'}, 'Location', 'southwest', ...
    'FontName', 'Microsoft YaHei');
set_all_axes_font('Microsoft YaHei');
exportgraphics(fig, fullfile(outDir, '02_2psk_spectrum.png'), 'Resolution', 220);

%% 4. AWGN 通带示例与相干接收
EbN0Show = 6;
N0Show = Eb / db2lin_local(EbN0Show);
noiseStdPassband = sqrt(N0Show * fs / 2);
rPassband = s2psk + noiseStdPassband * randn(size(s2psk));

% 相干相关器：接收信号乘以本地载波基函数后在一个比特周期内积分。
phi = sqrt(2 / Tb) * cos(2*pi*fc*t);
metric = zeros(1, numPlotBits);
for k = 1:numPlotBits
    idx = (k-1)*sps + (1:sps);
    metric(k) = sum(rPassband(idx) .* phi(idx)) / fs;
end
bitsHat = metric >= 0;

fig = figure('Color', 'w', 'Position', [80 80 1120 680]);
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(sprintf('2PSK 加噪信号与相干解调判决  (E_b/N_0 = %g dB)', EbN0Show), ...
    'FontName', 'Microsoft YaHei', 'FontSize', 15, 'FontWeight', 'bold');

nexttile;
plot(t, s2psk, 'Color', [0.05 0.50 0.52], 'LineWidth', 1.0);
grid on; box off; xlabel('时间 / T_b'); ylabel('发送信号');
title('发送端 2PSK 通带波形', 'FontName', 'Microsoft YaHei');

nexttile;
plot(t, rPassband, 'Color', [0.85 0.52 0.10], 'LineWidth', 0.9);
grid on; box off; xlabel('时间 / T_b'); ylabel('接收信号');
title('加入 AWGN 后的接收波形', 'FontName', 'Microsoft YaHei');

nexttile;
stem(1:numPlotBits, metric, 'filled', 'Color', [0.12 0.39 0.70], ...
    'MarkerFaceColor', [0.12 0.39 0.70], 'LineWidth', 1.1);
hold on;
yline(0, '--', '判决门限', 'Color', [0.70 0.18 0.24], 'LineWidth', 1.0);
grid on; box off; xlabel('比特序号'); ylabel('相关器输出');
title(sprintf('相干解调判决，示例错误数 = %d', sum(bitsHat ~= bits)), ...
    'FontName', 'Microsoft YaHei');
set_all_axes_font('Microsoft YaHei');
exportgraphics(fig, fullfile(outDir, '03_coherent_receiver.png'), 'Resolution', 220);

%% 5. AWGN 信道下的 BER 曲线
bitsBer = randi([0 1], 1, numBerBits);
symBer = sqrt(Eb) * (2 * bitsBer - 1);
berSim = zeros(size(EbN0dB));

for i = 1:numel(EbN0dB)
    gamma = db2lin_local(EbN0dB(i));
    sigma = sqrt(Eb / (2 * gamma));
    y = symBer + sigma * randn(size(symBer));
    bitsHatBer = y >= 0;
    berSim(i) = mean(bitsHatBer ~= bitsBer);
end

berTheory = 0.5 * erfc(sqrt(db2lin_local(EbN0dB)));
berPlot = max(berSim, 0.5 / numBerBits); % 避免对数坐标下 0 值无法绘制

fig = figure('Color', 'w', 'Position', [80 80 980 660]);
semilogy(EbN0dB, berPlot, 'o-', 'Color', [0.12 0.39 0.70], ...
    'MarkerFaceColor', [0.12 0.39 0.70], 'LineWidth', 1.45, 'MarkerSize', 6.5);
hold on;
semilogy(EbN0dB, berTheory, '--', 'Color', [0.10 0.15 0.22], 'LineWidth', 1.55);
grid on; box off; ylim([1e-6 1]); xlim([min(EbN0dB) max(EbN0dB)]);
xlabel('E_b/N_0 / dB'); ylabel('误码率 BER');
title('2PSK 相干检测 BER：仿真曲线与理论曲线对比', ...
    'FontName', 'Microsoft YaHei', 'FontSize', 15, 'FontWeight', 'bold');
legend({'Monte Carlo 仿真', '理论值：0.5erfc(sqrt(E_b/N_0))'}, ...
    'Location', 'southwest', 'FontName', 'Microsoft YaHei');
set_all_axes_font('Microsoft YaHei');
exportgraphics(fig, fullfile(outDir, '04_ber_comparison.png'), 'Resolution', 220);

%% 6. 相干解调中的载波相位模糊
% 若本地载波存在相位误差 theta，相关器输出的有效信号分量会变为
% a_k*sqrt(Eb)*cos(theta)。当 theta=90° 时，有效分量消失；
% 当 theta=180° 时，相关器输出极性反转。
gammaPhase = db2lin_local(phaseEbN0dB);
sigmaPhase = sqrt(Eb / (2 * gammaPhase));
berPhaseSim = zeros(size(phaseDeg));
berPhaseTheory = zeros(size(phaseDeg));

for i = 1:numel(phaseDeg)
    c = cosd(phaseDeg(i));
    yPhase = symBer * c + sigmaPhase * randn(size(symBer));
    bitsHatPhase = yPhase >= 0;
    berPhaseSim(i) = mean(bitsHatPhase ~= bitsBer);
    berPhaseTheory(i) = 0.5 * erfc(sqrt(gammaPhase) * c);
end

fig = figure('Color', 'w', 'Position', [80 80 1120 660]);
semilogy(phaseDeg, max(berPhaseSim, 0.5/numBerBits), 'o-', ...
    'Color', [0.70 0.18 0.24], 'MarkerFaceColor', [0.70 0.18 0.24], ...
    'LineWidth', 1.45, 'MarkerSize', 6.5);
hold on;
semilogy(phaseDeg, min(max(berPhaseTheory, 1e-6), 1), '--', ...
    'Color', [0.10 0.15 0.22], 'LineWidth', 1.55);
xline(90, ':', 'Color', [0.85 0.52 0.10], 'LineWidth', 1.25);
text(94, 3e-2, '90°：有效分量为 0', 'Color', [0.85 0.52 0.10], ...
    'FontName', 'Microsoft YaHei', 'FontSize', 11, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
grid on; box off; ylim([1e-5 1.1]); xlim([0 180]);
xlabel('载波相位误差 / 度'); ylabel('误码率 BER');
title(sprintf('载波相位模糊对 2PSK BER 的影响  (E_b/N_0 = %g dB)', phaseEbN0dB), ...
    'FontName', 'Microsoft YaHei', 'FontSize', 15, 'FontWeight', 'bold');
legend({'Monte Carlo 仿真', '理论趋势'}, 'Location', 'southeast', ...
    'FontName', 'Microsoft YaHei');
set_all_axes_font('Microsoft YaHei');
exportgraphics(fig, fullfile(outDir, '05_phase_ambiguity_ber.png'), 'Resolution', 220);

%% 7. 打印数值结果摘要
fprintf('\n2PSK BER 对比\n');
fprintf('Eb/N0(dB)\t仿真值\t理论值\n');
for i = 1:numel(EbN0dB)
    fprintf('%+7.1f\t%.6e\t%.6e\n', EbN0dB(i), berSim(i), berTheory(i));
end

fprintf('\n载波相位模糊分析，Eb/N0 = %.1f dB\n', phaseEbN0dB);
fprintf('相位误差(度)\t仿真值\t理论趋势\n');
for i = 1:numel(phaseDeg)
    fprintf('%7.1f\t%.6e\t%.6e\n', phaseDeg(i), berPhaseSim(i), berPhaseTheory(i));
end

fprintf('\n图像已保存到：\n%s\n', outDir);

%% 本脚本使用的局部函数
function [fAxis, specDb] = centered_spectrum(x, fs)
    x = x(:).';
    n = length(x);
    win = 0.5 - 0.5*cos(2*pi*(0:n-1)/(n-1));
    nfft = 2^nextpow2(4*n);
    X = fftshift(fft(x .* win, nfft));
    mag = abs(X);
    specDb = 20*log10(mag / max(mag) + eps);
    fAxis = (-nfft/2:nfft/2-1) * fs / nfft;
end

function y = db2lin_local(x)
    y = 10.^(x/10);
end

function set_all_axes_font(fontName)
    axesList = findall(gcf, 'Type', 'axes');
    for ii = 1:numel(axesList)
        set(axesList(ii), 'FontName', fontName, 'FontSize', 11, ...
            'LineWidth', 0.85, 'GridAlpha', 0.18);
    end
end
