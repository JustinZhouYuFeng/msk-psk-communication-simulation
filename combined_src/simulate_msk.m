function results = simulate_msk(figDir)
%SIMULATE_MSK  MSK waveform, spectrum, parameter study and BER.
%
% MSK is binary CPFSK with modulation index h = 0.5:
%   h = 2*Delta_f*T_b
%   Delta_f = h/(2*T_b) = 1/(4*T_b)
%   f_1 - f_0 = 2*Delta_f = 1/(2*T_b)
%
% The BER section uses the equivalent OQPSK form of MSK:
% the in-phase and quadrature branches are offset by T_b and shaped by
% half-sine pulses. Coherent matched filtering on the two branches gives
% the standard coherent MSK BER curve.

rng(2027);

%% Parameters
Tb = 1;                 % normalized bit period
Rb = 1 / Tb;
hMsk = 0.5;             % MSK modulation index
deltaF = hMsk / (2*Tb); % frequency deviation from carrier
fc = 4 * Rb;            % carrier frequency for passband plotting
Eb = 1;
amp = sqrt(2 * Eb / Tb);

spsPlot = 64;
fsPlot = spsPlot / Tb;
numPlotBits = 32;
numSpecBits = 1024;

spsBer = 16;
fsBer = spsBer / Tb;
numBerBits = 2e5;
EbN0dB = -4:2:12;

%% 1. Time-domain MSK waveform
bitsPlot = randi([0 1], 1, numPlotBits);
[bbPlot, phasePlot, freqDevPlot] = cpfsk_modulate(bitsPlot, hMsk, spsPlot);
tPlot = (0:length(bbPlot)-1) / fsPlot;
sMskPlot = amp * real(bbPlot .* exp(1j*2*pi*fc*tPlot));

fig = figure('Name', 'MSK waveform', 'Color', 'w');
subplot(4,1,1);
plot(tPlot, repelem(bitsPlot, spsPlot), 'k', 'LineWidth', 1.2);
ylim([-0.2 1.2]); grid on;
xlabel('Time / T_b'); ylabel('Bit');
title('Random binary data');

subplot(4,1,2);
plot(tPlot, freqDevPlot / Rb, 'LineWidth', 1.1);
grid on; ylim([-0.4 0.4]);
xlabel('Time / T_b'); ylabel('\Delta f / R_b');
title('Instantaneous frequency deviation');

subplot(4,1,3);
plot(tPlot, unwrap(phasePlot)/pi, 'LineWidth', 1.1);
grid on;
xlabel('Time / T_b'); ylabel('Phase / \pi');
title('Continuous baseband phase');

subplot(4,1,4);
plot(tPlot, sMskPlot, 'LineWidth', 0.9);
grid on;
xlabel('Time / T_b'); ylabel('Amplitude');
title('MSK passband signal');
save_current_figure(fig, figDir, 'fig_msk_waveform');

%% 2. Passband spectrum
bitsSpec = randi([0 1], 1, numSpecBits);
[bbSpec, ~, ~] = cpfsk_modulate(bitsSpec, hMsk, spsPlot);
tSpec = (0:length(bbSpec)-1) / fsPlot;
sMskSpec = amp * real(bbSpec .* exp(1j*2*pi*fc*tSpec));
[fAxis, specDb] = centered_spectrum(sMskSpec, fsPlot);

fig = figure('Name', 'MSK spectrum', 'Color', 'w');
plot(fAxis / Rb, specDb, 'LineWidth', 1.1);
grid on; ylim([-80 5]); xlim([-10 10]);
xlabel('Normalized frequency f / R_b');
ylabel('Magnitude / dB');
title('MSK passband spectrum');
save_current_figure(fig, figDir, 'fig_msk_spectrum');

%% 3. Parameter effect: h changes phase slope and spectrum width
hList = [0.25 0.5 0.75 1.0];
bitsParam = bitsSpec;
fig = figure('Name', 'MSK parameter effect', 'Color', 'w');

subplot(2,1,1);
hold on; grid on;
for i = 1:numel(hList)
    [~, phaseTmp, ~] = cpfsk_modulate(bitsPlot, hList(i), spsPlot);
    plot(tPlot, unwrap(phaseTmp)/pi, 'LineWidth', 1.0);
end
xlabel('Time / T_b'); ylabel('Phase / \pi');
title('Phase slope changes with modulation index h');
legend(compose('h = %.2g', hList), 'Location', 'best');

subplot(2,1,2);
hold on; grid on;
for i = 1:numel(hList)
    [bbTmp, ~, ~] = cpfsk_modulate(bitsParam, hList(i), spsPlot);
    [fb, psdDb] = centered_spectrum(bbTmp, fsPlot);
    plot(fb / Rb, psdDb, 'LineWidth', 1.0);
end
ylim([-80 5]); xlim([-2.5 2.5]);
xlabel('Normalized baseband frequency f / R_b');
ylabel('Magnitude / dB');
title('Baseband spectrum changes with h');
legend(compose('h = %.2g', hList), 'Location', 'best');
save_current_figure(fig, figDir, 'fig_msk_parameter_effect');

%% 4. BER with equivalent OQPSK coherent matched filtering
berSim = zeros(size(EbN0dB));
bitsBer = randi([0 1], 1, numBerBits);
[bbBer, pulseBer] = msk_oqpsk_modulate(bitsBer, spsBer);

for i = 1:numel(EbN0dB)
    gamma = db2lin_local(EbN0dB(i));
    N0 = Eb / gamma;
    noiseStd = sqrt(N0 * fsBer / 2);
    rx = bbBer + noiseStd * (randn(size(bbBer)) + 1j*randn(size(bbBer)));
    bitsHat = msk_oqpsk_demodulate(rx, pulseBer, spsBer, numBerBits);
    berSim(i) = mean(bitsHat ~= bitsBer);
end

berTheory = 0.5 * erfc(sqrt(db2lin_local(EbN0dB)));
berPlot = max(berSim, 0.5 / numBerBits);

fig = figure('Name', 'MSK BER', 'Color', 'w');
semilogy(EbN0dB, berPlot, 'o-', 'LineWidth', 1.2, 'MarkerSize', 6);
hold on;
semilogy(EbN0dB, berTheory, 'k--', 'LineWidth', 1.4);
grid on; ylim([1e-5 1]);
xlabel('E_b/N_0 / dB'); ylabel('Bit error rate');
title('MSK coherent matched-filter detection in AWGN');
legend('Matched-filter simulation', 'Theory: coherent MSK', 'Location', 'southwest');
save_current_figure(fig, figDir, 'fig_msk_ber');

%% Results
results = struct();
results.params = struct('Tb', Tb, 'Rb', Rb, 'h', hMsk, ...
    'deltaF', deltaF, 'f1MinusF0', 2*deltaF, 'fc', fc, ...
    'spsBer', spsBer, 'numBerBits', numBerBits);
results.bitsPlot = bitsPlot;
results.EbN0dB = EbN0dB;
results.berSim = berSim;
results.berTheory = berTheory;
results.hList = hList;

fprintf('MSK parameter relation:\n');
fprintf('  h = %.2f, Delta_f = %.3f/T_b, f1 - f0 = %.3f/T_b\n', ...
    hMsk, deltaF*Tb, 2*deltaF*Tb);
fprintf('MSK BER summary:\n');
for i = 1:numel(EbN0dB)
    fprintf('  Eb/N0 = %+3g dB, simulated BER = %.3e, theory = %.3e\n', ...
        EbN0dB(i), berSim(i), berTheory(i));
end

end

function [bb, phase, freqDev] = cpfsk_modulate(bits, h, sps)
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

function [bb, pulse] = msk_oqpsk_modulate(bits, sps)
bits = bits(:).';
sym = 2*bits - 1;
numBits = numel(bits);
numSamples = (numBits + 3) * sps;

pulseLen = 2*sps;
tau = (0:pulseLen-1) / sps;
pulse = sin(pi*tau/2);
pulse = pulse / sqrt(sum(pulse.^2) / sps); % unit-energy pulse

iWave = zeros(1, numSamples);
qWave = zeros(1, numSamples);

oddSymbols = sym(1:2:end);
evenSymbols = sym(2:2:end);

for n = 1:numel(oddSymbols)
    idx = (n-1)*2*sps + (1:pulseLen);
    iWave(idx) = iWave(idx) + oddSymbols(n) * pulse;
end

for n = 1:numel(evenSymbols)
    idx = (n-1)*2*sps + sps + (1:pulseLen);
    qWave(idx) = qWave(idx) + evenSymbols(n) * pulse;
end

bb = iWave + 1j*qWave;
end

function bitsHat = msk_oqpsk_demodulate(rx, pulse, sps, numBits)
rx = rx(:).';
pulseLen = numel(pulse);
Ts = 1 / sps;
bitsHat = false(1, numBits);

for k = 1:numBits
    branchIndex = floor((k-1)/2);
    if mod(k, 2) == 1
        idx = branchIndex*2*sps + (1:pulseLen);
        metric = sum(real(rx(idx)) .* pulse) * Ts;
    else
        idx = branchIndex*2*sps + sps + (1:pulseLen);
        metric = sum(imag(rx(idx)) .* pulse) * Ts;
    end
    bitsHat(k) = metric >= 0;
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
