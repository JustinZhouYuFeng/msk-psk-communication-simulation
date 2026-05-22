function results = simulate_2psk(figDir)
%SIMULATE_2PSK  2PSK/BPSK waveform, spectrum, coherent detection and BER.
%
% The BER section uses the equivalent baseband model:
%   y = a + n, a in {-1,+1}, n ~ N(0, N0/2)
% This is mathematically equivalent to ideal coherent passband 2PSK
% detection with a matched correlator, and it is much faster for Monte
% Carlo BER estimation.

rng(2026);

%% Parameters
Tb = 1;                 % bit period, normalized
Rb = 1 / Tb;            % bit rate
sps = 64;               % samples per bit
fs = sps / Tb;          % sampling frequency
fc = 8 * Rb;            % carrier frequency, 8 cycles per bit
Eb = 1;                 % normalized bit energy
amp = sqrt(2 * Eb / Tb);

numPlotBits = 24;
numSpecBits = 512;
numBerBits = 5e5;
EbN0dB = -4:2:12;

%% 1. Time-domain waveform
bitsPlot = randi([0 1], 1, numPlotBits);
symPlot = 2 * bitsPlot - 1;
basebandPlot = repelem(symPlot, sps);
tPlot = (0:length(basebandPlot)-1) / fs;
carrierPlot = cos(2*pi*fc*tPlot);
s2pskPlot = amp * basebandPlot .* carrierPlot;

fig = figure('Name', '2PSK waveform', 'Color', 'w');
subplot(3,1,1);
plot(tPlot, repelem(bitsPlot, sps), 'k', 'LineWidth', 1.2);
ylim([-0.2 1.2]); grid on;
xlabel('Time / T_b'); ylabel('Bit');
title('Random binary data');

subplot(3,1,2);
plot(tPlot, basebandPlot, 'LineWidth', 1.2);
ylim([-1.4 1.4]); grid on;
xlabel('Time / T_b'); ylabel('Amplitude');
title('Polar baseband symbols: 0 -> -1, 1 -> +1');

subplot(3,1,3);
plot(tPlot, s2pskPlot, 'LineWidth', 1.0);
grid on;
xlabel('Time / T_b'); ylabel('Amplitude');
title('2PSK passband signal');
save_current_figure(fig, figDir, 'fig_2psk_waveform');

%% 2. Spectrum
bitsSpec = randi([0 1], 1, numSpecBits);
symSpec = 2 * bitsSpec - 1;
basebandSpec = repelem(symSpec, sps);
tSpec = (0:length(basebandSpec)-1) / fs;
s2pskSpec = amp * basebandSpec .* cos(2*pi*fc*tSpec);
[fAxis, specDb] = centered_spectrum(s2pskSpec, fs);

fig = figure('Name', '2PSK spectrum', 'Color', 'w');
plot(fAxis / Rb, specDb, 'LineWidth', 1.1);
grid on; ylim([-80 5]); xlim([-20 20]);
xlabel('Normalized frequency f / R_b');
ylabel('Magnitude / dB');
title('2PSK spectrum with rectangular pulse shaping');
save_current_figure(fig, figDir, 'fig_2psk_spectrum');

%% 3. Passband AWGN and coherent correlator demonstration
EbN0Show = 6;
N0Show = Eb / db2lin_local(EbN0Show);
noiseStdPassband = sqrt(N0Show * fs / 2);
rPassband = s2pskPlot + noiseStdPassband * randn(size(s2pskPlot));
phi = sqrt(2 / Tb) * cos(2*pi*fc*tPlot);
metrics = zeros(1, numPlotBits);
for k = 1:numPlotBits
    idx = (k-1)*sps + (1:sps);
    metrics(k) = sum(rPassband(idx) .* phi(idx)) / fs;
end
bitsHatPlot = metrics >= 0;

fig = figure('Name', '2PSK coherent receiver', 'Color', 'w');
subplot(3,1,1);
plot(tPlot, s2pskPlot, 'LineWidth', 1.0); grid on;
xlabel('Time / T_b'); ylabel('Amplitude');
title('Clean passband signal');

subplot(3,1,2);
plot(tPlot, rPassband, 'LineWidth', 0.9); grid on;
xlabel('Time / T_b'); ylabel('Amplitude');
title(sprintf('Received passband signal, E_b/N_0 = %g dB', EbN0Show));

subplot(3,1,3);
stem(1:numPlotBits, metrics, 'filled'); grid on;
hold on; yline(0, '--k');
xlabel('Bit index'); ylabel('Correlator output');
title(sprintf('Coherent decision samples, errors = %d', sum(bitsHatPlot ~= bitsPlot)));
save_current_figure(fig, figDir, 'fig_2psk_coherent_rx');

%% 4. BER curve
berSim = zeros(size(EbN0dB));
bitsBer = randi([0 1], 1, numBerBits);
symBer = 2 * bitsBer - 1;

for i = 1:numel(EbN0dB)
    gamma = db2lin_local(EbN0dB(i));
    sigma = sqrt(Eb / (2 * gamma));
    y = symBer + sigma * randn(size(symBer));
    bitsHat = y >= 0;
    berSim(i) = mean(bitsHat ~= bitsBer);
end

berTheory = 0.5 * erfc(sqrt(db2lin_local(EbN0dB)));
berPlot = max(berSim, 0.5 / numBerBits);

fig = figure('Name', '2PSK BER', 'Color', 'w');
semilogy(EbN0dB, berPlot, 'o-', 'LineWidth', 1.2, 'MarkerSize', 6);
hold on;
semilogy(EbN0dB, berTheory, 'k--', 'LineWidth', 1.4);
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 / dB'); ylabel('Bit error rate');
title('2PSK coherent detection in AWGN');
legend('Monte Carlo simulation', 'Theory: 0.5 erfc(sqrt(E_b/N_0))', ...
    'Location', 'southwest');
save_current_figure(fig, figDir, 'fig_2psk_ber');

%% 5. Carrier phase ambiguity
phaseDeg = [0 15 30 45 60 75 90 120 150 180];
EbN0Phase = 6;
gammaPhase = db2lin_local(EbN0Phase);
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

fig = figure('Name', '2PSK phase ambiguity', 'Color', 'w');
semilogy(phaseDeg, max(berPhaseSim, 0.5/numBerBits), 'o-', ...
    'LineWidth', 1.2, 'MarkerSize', 6);
hold on;
semilogy(phaseDeg, berPhaseTheory, 'k--', 'LineWidth', 1.4);
grid on; ylim([1e-5 1.1]); xlim([0 180]);
xlabel('Carrier phase error / degree');
ylabel('Bit error rate');
title(sprintf('2PSK carrier phase ambiguity at E_b/N_0 = %g dB', EbN0Phase));
legend('Monte Carlo simulation', 'Theory with cos(theta) loss', ...
    'Location', 'northwest');
save_current_figure(fig, figDir, 'fig_2psk_phase_ambiguity');

%% Results
results = struct();
results.params = struct('Tb', Tb, 'Rb', Rb, 'sps', sps, 'fs', fs, ...
    'fc', fc, 'Eb', Eb, 'numBerBits', numBerBits);
results.bitsPlot = bitsPlot;
results.bitsHatPlot = bitsHatPlot;
results.EbN0dB = EbN0dB;
results.berSim = berSim;
results.berTheory = berTheory;
results.phaseDeg = phaseDeg;
results.berPhaseSim = berPhaseSim;
results.berPhaseTheory = berPhaseTheory;

fprintf('2PSK BER summary:\n');
for i = 1:numel(EbN0dB)
    fprintf('  Eb/N0 = %+3g dB, simulated BER = %.3e, theory = %.3e\n', ...
        EbN0dB(i), berSim(i), berTheory(i));
end

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

function y = db2lin_local(x)
y = 10.^(x/10);
end

function save_current_figure(fig, figDir, name)
fileName = fullfile(figDir, [name '.png']);
if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, fileName, 'Resolution', 180);
else
    saveas(fig, fileName);
end
end
