function result = simulate_2psk_system(cfg, figDir)
% 生成 2PSK 波形、频谱、接收机和 BER 图。

palette = make_palette();

%% 1. 系统框图与程序流程图
draw_system_block(cfg, figDir, palette);
draw_program_flow(cfg, figDir, palette);

%% 2. 时域 2PSK 波形
bitsPlot = randi([0 1], 1, cfg.numPlotBits);
symPlot = 2 * bitsPlot - 1;
basebandPlot = repelem(symPlot, cfg.sps);
tPlot = (0:length(basebandPlot)-1) / cfg.fs;
carrierPlot = cos(2*pi*cfg.fc*tPlot);
s2pskPlot = cfg.amp * basebandPlot .* carrierPlot;

fig = new_fig('2PSK waveform');
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, '2PSK 调制波形：随机比特、极性基带与通带信号', ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold');

nexttile;
stairs(tPlot, repelem(bitsPlot, cfg.sps), 'Color', palette.ink, 'LineWidth', cfg.lineWidth);
ylim([-0.2 1.2]); grid on; box off;
ylabel('bit'); xlabel('时间 / T_b');
style_axis(cfg);

nexttile;
stairs(tPlot, basebandPlot, 'Color', palette.blue, 'LineWidth', cfg.lineWidth);
ylim([-1.35 1.35]); grid on; box off;
ylabel('a_k'); xlabel('时间 / T_b');
style_axis(cfg);

nexttile;
plot(tPlot, s2pskPlot, 'Color', palette.teal, 'LineWidth', 1.05);
grid on; box off;
ylabel('幅度'); xlabel('时间 / T_b');
style_axis(cfg);
save_fig(fig, figDir, '01_2psk_waveform', cfg);

%% 3. 频谱分析
bitsSpec = randi([0 1], 1, cfg.numSpecBits);
symSpec = 2 * bitsSpec - 1;
basebandSpec = repelem(symSpec, cfg.sps);
tSpec = (0:length(basebandSpec)-1) / cfg.fs;
s2pskSpec = cfg.amp * basebandSpec .* cos(2*pi*cfg.fc*tSpec);
[fAxis, specDb] = centered_spectrum(s2pskSpec, cfg.fs);
specSmoothDb = movmean(specDb, 15);

fig = new_fig('2PSK spectrum');
plot(fAxis / cfg.Rb, specDb, 'Color', [0.70 0.82 0.94], 'LineWidth', 0.55);
hold on;
plot(fAxis / cfg.Rb, specSmoothDb, 'Color', palette.blue, 'LineWidth', 1.35);
hold on;
xline(cfg.fc/cfg.Rb, '--', 'f_c', 'Color', palette.red, 'LineWidth', 1.2, ...
    'FontName', cfg.fontName, 'LabelVerticalAlignment', 'top');
xline(-cfg.fc/cfg.Rb, '--', '-f_c', 'Color', palette.red, 'LineWidth', 1.2, ...
    'FontName', cfg.fontName, 'LabelVerticalAlignment', 'top');
grid on; box off; ylim([-82 5]); xlim([-20 20]);
xlabel('归一化频率 f / R_b'); ylabel('幅度 / dB');
title('2PSK 通带频谱（矩形码元成形）', 'FontName', cfg.fontName, ...
    'FontSize', 15, 'FontWeight', 'bold');
subtitle('能量集中于载波附近；矩形脉冲导致旁瓣明显', 'FontName', cfg.fontName);
style_axis(cfg);
save_fig(fig, figDir, '02_2psk_spectrum', cfg);

%% 4. AWGN 通带示例与相干接收
EbN0Show = 6;
N0Show = cfg.Eb / db2lin_local(EbN0Show);
noiseStdPassband = sqrt(N0Show * cfg.fs / 2);
rPassband = s2pskPlot + noiseStdPassband * randn(size(s2pskPlot));
phi = sqrt(2 / cfg.Tb) * cos(2*pi*cfg.fc*tPlot);
metrics = zeros(1, cfg.numPlotBits);
for k = 1:cfg.numPlotBits
    idx = (k-1)*cfg.sps + (1:cfg.sps);
    metrics(k) = sum(rPassband(idx) .* phi(idx)) / cfg.fs;
end
bitsHatPlot = metrics >= 0;

fig = new_fig('Coherent receiver');
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, sprintf('2PSK 加噪信号与相干接收判决  (E_b/N_0 = %g dB)', EbN0Show), ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold');

nexttile;
plot(tPlot, s2pskPlot, 'Color', palette.teal, 'LineWidth', 1.05);
grid on; box off; ylabel('发送信号'); xlabel('时间 / T_b');
style_axis(cfg);

nexttile;
plot(tPlot, rPassband, 'Color', palette.amber, 'LineWidth', 0.95);
grid on; box off; ylabel('接收信号'); xlabel('时间 / T_b');
style_axis(cfg);

nexttile;
stem(1:cfg.numPlotBits, metrics, 'filled', 'Color', palette.blue, ...
    'MarkerFaceColor', palette.blue, 'LineWidth', 1.1);
hold on; yline(0, '--', '判决门限', 'Color', palette.red, ...
    'FontName', cfg.fontName, 'LineWidth', 1.1);
grid on; box off; xlabel('比特序号'); ylabel('相关器输出');
style_axis(cfg);
save_fig(fig, figDir, '03_coherent_receiver', cfg);

%% 5. 信号空间噪声示意图
draw_signal_space_noise(cfg, figDir, palette);

%% 6. BER 曲线
bitsBer = randi([0 1], 1, cfg.numBerBits);
symBer = sqrt(cfg.Eb) * (2 * bitsBer - 1);
berSim = zeros(size(cfg.EbN0dB));
for i = 1:numel(cfg.EbN0dB)
    gamma = db2lin_local(cfg.EbN0dB(i));
    sigma = sqrt(cfg.Eb / (2 * gamma));
    y = symBer + sigma * randn(size(symBer));
    bitsHat = y >= 0;
    berSim(i) = mean(bitsHat ~= bitsBer);
end
berTheory = 0.5 * erfc(sqrt(db2lin_local(cfg.EbN0dB)));

fig = new_fig('BER');
semilogy(cfg.EbN0dB, max(berSim, 0.5/cfg.numBerBits), 'o-', ...
    'Color', palette.blue, 'MarkerFaceColor', palette.blue, ...
    'LineWidth', 1.5, 'MarkerSize', 6.5);
hold on;
semilogy(cfg.EbN0dB, berTheory, '--', 'Color', palette.ink, 'LineWidth', 1.6);
grid on; box off; ylim([1e-6 1]); xlim([min(cfg.EbN0dB) max(cfg.EbN0dB)]);
xlabel('E_b/N_0 / dB'); ylabel('误码率 BER');
title('2PSK 相干检测 BER：仿真曲线与理论曲线对比', ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold');
legend({'Monte Carlo 仿真', '理论值：0.5erfc(sqrt(E_b/N_0))'}, ...
    'Location', 'southwest', 'FontName', cfg.fontName);
style_axis(cfg);
save_fig(fig, figDir, '05_ber_curve', cfg);

%% 7. 载波相位模糊
gammaPhase = db2lin_local(cfg.phaseEbN0dB);
sigmaPhase = sqrt(cfg.Eb / (2 * gammaPhase));
berPhaseSim = zeros(size(cfg.phaseDeg));
berPhaseTheory = zeros(size(cfg.phaseDeg));
for i = 1:numel(cfg.phaseDeg)
    c = cosd(cfg.phaseDeg(i));
    yPhase = symBer * c + sigmaPhase * randn(size(symBer));
    bitsHatPhase = yPhase >= 0;
    berPhaseSim(i) = mean(bitsHatPhase ~= bitsBer);
    berPhaseTheory(i) = 0.5 * erfc(sqrt(gammaPhase) * c);
end

fig = new_fig('Phase ambiguity');
semilogy(cfg.phaseDeg, max(berPhaseSim, 0.5/cfg.numBerBits), 'o-', ...
    'Color', palette.red, 'MarkerFaceColor', palette.red, ...
    'LineWidth', 1.45, 'MarkerSize', 6.5);
hold on;
semilogy(cfg.phaseDeg, min(max(berPhaseTheory, 1e-6), 1), '--', ...
    'Color', palette.ink, 'LineWidth', 1.55);
xline(90, ':', 'Color', palette.amber, 'LineWidth', 1.35);
text(92, 0.035, '90°：有效分量为 0', 'FontName', cfg.fontName, ...
    'FontSize', 10.5, 'Color', palette.amber, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
grid on; box off; ylim([1e-5 1.1]); xlim([0 180]);
xlabel('载波相位误差 / 度'); ylabel('误码率 BER');
title(sprintf('载波相位模糊对 2PSK BER 的影响  (E_b/N_0 = %g dB)', cfg.phaseEbN0dB), ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold');
legend({'Monte Carlo 仿真', '理论趋势'}, ...
    'Location', 'southeast', 'FontName', cfg.fontName);
style_axis(cfg);
save_fig(fig, figDir, '06_phase_ambiguity_ber', cfg);

draw_phase_decision_demo(cfg, figDir, palette);

%% 返回结果
result.bitsPlot = bitsPlot;
result.bitsHatPlot = bitsHatPlot;
result.metrics = metrics;
result.EbN0dB = cfg.EbN0dB;
result.berSim = berSim;
result.berTheory = berTheory;
result.phaseDeg = cfg.phaseDeg;
result.berPhaseSim = berPhaseSim;
result.berPhaseTheory = berPhaseTheory;
end

function palette = make_palette()
palette.ink = [22 34 50] / 255;
palette.muted = [84 99 115] / 255;
palette.teal = [10 128 130] / 255;
palette.blue = [37 99 170] / 255;
palette.amber = [214 136 24] / 255;
palette.red = [178 58 72] / 255;
palette.green = [35 140 92] / 255;
palette.pale = [246 250 252] / 255;
palette.line = [214 226 236] / 255;
end

function fig = new_fig(name)
fig = figure('Name', name, 'Color', 'w', 'Position', [80 80 1180 720]);
end

function style_axis(cfg)
set(gca, 'FontName', cfg.fontName, 'FontSize', 11, 'LineWidth', 0.85, ...
    'GridAlpha', 0.18, 'MinorGridAlpha', 0.10);
end

function save_fig(fig, figDir, name, cfg)
png = fullfile(figDir, [name '.png']);
figFile = fullfile(figDir, [name '.fig']);
exportgraphics(fig, png, 'Resolution', cfg.exportDpi, 'BackgroundColor', 'white');
if isfield(cfg, 'saveFigFiles') && cfg.saveFigFiles
    savefig(fig, figFile);
end
close(fig);
end

function y = db2lin_local(x)
y = 10.^(x/10);
end

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
