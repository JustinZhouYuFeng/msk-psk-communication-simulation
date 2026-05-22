function results = simulate_extras(figDir, results2psk, resultsMsk)
%SIMULATE_EXTRAS  Extra figures for explanation, comparison and defense.

rng(2028);

%% 1. 2PSK signal-space noisy samples
Eb = 1;
EbN0Show = [-2 4 10];
numSamples = 350;
bits = randi([0 1], 1, numSamples);
sym = 2*bits - 1;

fig = figure('Name', '2PSK signal-space samples', 'Color', 'w');
for i = 1:numel(EbN0Show)
    gamma = db2lin_local(EbN0Show(i));
    sigma = sqrt(Eb/(2*gamma));
    y = sym + sigma*randn(size(sym));
    subplot(1,3,i);
    scatter(y(bits == 0), 0.04*randn(1, sum(bits == 0)), 18, ...
        [0.80 0.20 0.25], 'filled', 'MarkerFaceAlpha', 0.55);
    hold on;
    scatter(y(bits == 1), 0.04*randn(1, sum(bits == 1)), 18, ...
        [0.08 0.55 0.55], 'filled', 'MarkerFaceAlpha', 0.55);
    xline(0, '--k', 'Decision threshold', 'LabelOrientation', 'horizontal');
    xline(-1, ':', 's_0', 'Color', [0.80 0.20 0.25], 'LineWidth', 1.1);
    xline(+1, ':', 's_1', 'Color', [0.08 0.55 0.55], 'LineWidth', 1.1);
    grid on; ylim([-0.24 0.24]); xlim([-3 3]);
    xlabel('Correlator output z_k');
    title(sprintf('E_b/N_0 = %+g dB', EbN0Show(i)));
    if i == 1
        ylabel('Jittered samples');
    end
end
sgtitle('2PSK signal-space decision under AWGN');
save_current_figure(fig, figDir, 'fig_2psk_signal_space_noise');

%% 2. 2PSK and MSK BER comparison
fig = figure('Name', 'BER comparison', 'Color', 'w');
semilogy(results2psk.EbN0dB, max(results2psk.berSim, 0.5/results2psk.params.numBerBits), ...
    'o-', 'LineWidth', 1.2, 'MarkerSize', 6);
hold on;
semilogy(resultsMsk.EbN0dB, max(resultsMsk.berSim, 0.5/resultsMsk.params.numBerBits), ...
    's-', 'LineWidth', 1.2, 'MarkerSize', 6);
semilogy(results2psk.EbN0dB, results2psk.berTheory, 'k--', 'LineWidth', 1.5);
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 / dB'); ylabel('Bit error rate');
title('2PSK and MSK BER comparison under ideal coherent detection');
legend('2PSK simulation', 'MSK simulation', 'Theory', 'Location', 'southwest');
save_current_figure(fig, figDir, 'fig_ber_comparison_2psk_msk');

%% 3. MSK IQ trajectory and phase continuity
numBits = 22;
sps = 80;
h = 0.5;
bitsMsk = randi([0 1], 1, numBits);
[bb, phase, freqDev] = cpfsk_modulate_local(bitsMsk, h, sps);
t = (0:length(bb)-1)/sps;

fig = figure('Name', 'MSK IQ trajectory', 'Color', 'w');
subplot(1,2,1);
plot(real(bb), imag(bb), 'LineWidth', 1.2);
axis equal; grid on;
xlabel('In-phase I'); ylabel('Quadrature Q');
title('Constant-envelope IQ trajectory');
subplot(1,2,2);
plot(t, unwrap(phase)/pi, 'LineWidth', 1.15);
hold on;
plot(t, freqDev, '--', 'LineWidth', 1.0);
grid on; xlabel('Time / T_b');
ylabel('Phase / \pi and \Delta f / R_b');
title('Continuous phase and frequency deviation');
legend('Unwrapped phase / \pi', '\Delta f / R_b', 'Location', 'best');
save_current_figure(fig, figDir, 'fig_msk_iq_phase_trajectory');

%% 4. Baseband spectrum comparison: rectangular 2PSK pulse vs MSK
numSpecBits = 1024;
bitsSpec = randi([0 1], 1, numSpecBits);
spsSpec = 64;
fsSpec = spsSpec;
baseband2psk = repelem(2*bitsSpec - 1, spsSpec);
[bbMsk, ~, ~] = cpfsk_modulate_local(bitsSpec, 0.5, spsSpec);
[f2, psd2] = centered_spectrum_local(baseband2psk, fsSpec);
[fm, psdm] = centered_spectrum_local(bbMsk, fsSpec);

fig = figure('Name', 'Baseband spectrum comparison', 'Color', 'w');
plot(f2, psd2, 'LineWidth', 1.1);
hold on;
plot(fm, psdm, 'LineWidth', 1.1);
grid on; xlim([-4 4]); ylim([-80 5]);
xlabel('Normalized baseband frequency f / R_b');
ylabel('Magnitude / dB');
title('Baseband spectrum: 2PSK rectangular pulse vs MSK continuous phase');
legend('2PSK rectangular baseband', 'MSK baseband', 'Location', 'southwest');
save_current_figure(fig, figDir, 'fig_spectrum_comparison_2psk_msk');

%% 5. 2PSK phase ambiguity signed decision-distance loss
phaseDeg = 0:1:180;
loss = cosd(phaseDeg);
fig = figure('Name', 'Phase ambiguity geometry', 'Color', 'w');
plot(phaseDeg, loss, 'LineWidth', 1.4);
hold on; yline(0, '--k', 'LineWidth', 1.0);
grid on; xlim([0 180]); ylim([-1.05 1.05]);
xlabel('Carrier phase error \theta / degree');
ylabel('cos\theta');
title('2PSK useful correlator component versus carrier phase error');
save_current_figure(fig, figDir, 'fig_2psk_phase_loss_cosine');

results = struct();
results.EbN0Show = EbN0Show;
results.extraFigureNames = { ...
    'fig_2psk_signal_space_noise', ...
    'fig_ber_comparison_2psk_msk', ...
    'fig_msk_iq_phase_trajectory', ...
    'fig_spectrum_comparison_2psk_msk', ...
    'fig_2psk_phase_loss_cosine'};

end

function [bb, phase, freqDev] = cpfsk_modulate_local(bits, h, sps)
bits = bits(:).';
sym = 2*bits - 1;
numBits = numel(bits);
bb = zeros(1, numBits*sps);
phase = zeros(1, numBits*sps);
freqDev = zeros(1, numBits*sps);
tau = (0:sps-1) / sps;
phaseState = 0;
for k = 1:numBits
    idx = (k-1)*sps + (1:sps);
    phaseBlock = phaseState + pi*h*sym(k)*tau;
    phase(idx) = phaseBlock;
    bb(idx) = exp(1j*phaseBlock);
    freqDev(idx) = sym(k) * h/2;
    phaseState = phaseState + pi*h*sym(k);
end
end

function [fAxis, specDb] = centered_spectrum_local(x, fs)
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

function save_current_figure(fig, figDir, name)
fileName = fullfile(figDir, [name '.png']);
if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, fileName, 'Resolution', 190);
else
    saveas(fig, fileName);
end
end
