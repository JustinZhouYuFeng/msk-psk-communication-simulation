clear; clc; close all;

outDir = fullfile(pwd, 'MSK_Output_Figures');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

rng(7);
EbNoDb = 12;
nPerState = 30;
sigma = 0.075;

states = [1 + 0j, 0 + 1j, -1 + 0j, 0 - 1j];
stateLabels = {'+I', '+Q', '-I', '-Q'};
theta = linspace(0, 2*pi, 500);
unitCircle = exp(1j * theta);

rx = [];
for k = 1:numel(states)
    noise = sigma * (randn(1, nPerState) + 1j * randn(1, nPerState));
    rx = [rx, states(k) + noise]; %#ok<AGROW>
end

fig = figure('Color', 'w', 'Position', [80, 80, 1280, 720]);
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'loose');

nexttile;
plot(real(unitCircle), imag(unitCircle), '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.4);
hold on;
plot(cos(theta(theta >= 0 & theta <= pi/2)), sin(theta(theta >= 0 & theta <= pi/2)), ...
    'Color', [0.00 0.25 0.90], 'LineWidth', 4);
plot(real(states), imag(states), 'o', 'MarkerSize', 10, ...
    'MarkerFaceColor', [0.95 0.10 0.05], 'MarkerEdgeColor', 'w', 'LineWidth', 1.4);
quiver(0.72, 0.68, -0.10, 0.10, 0, 'Color', [0.00 0.25 0.90], ...
    'LineWidth', 2, 'MaxHeadSize', 1.3);
xline(0, ':', 'Color', [0.72 0.72 0.72]);
yline(0, ':', 'Color', [0.72 0.72 0.72]);
for k = 1:numel(states)
    text(1.13 * real(states(k)), 1.13 * imag(states(k)), stateLabels{k}, ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end
title('MSK 连续相位轨迹', 'FontSize', 15, 'FontWeight', 'bold');
xlabel('I'); ylabel('Q');
axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
set(gca, 'FontSize', 11, 'LineWidth', 1.0, 'GridAlpha', 0.15);

nexttile;
plot(real(unitCircle), imag(unitCircle), '--', 'Color', [0.25 0.25 0.25], 'LineWidth', 1.4);
hold on;
xline(0, '-', 'Color', [0.70 0.70 0.70], 'LineWidth', 1.1);
yline(0, '-', 'Color', [0.70 0.70 0.70], 'LineWidth', 1.1);
scatter(real(rx), imag(rx), 28, 'MarkerFaceColor', [0.00 0.48 0.78], ...
    'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.72);
plot(real(states), imag(states), 'o', 'MarkerSize', 12, ...
    'MarkerFaceColor', [0.95 0.10 0.05], 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
for k = 1:numel(states)
    rectangle('Position', [real(states(k))-0.18, imag(states(k))-0.18, 0.36, 0.36], ...
        'Curvature', [1, 1], 'EdgeColor', [0.00 0.62 0.36], 'LineWidth', 1.6, ...
        'LineStyle', '-');
end
title(sprintf('AWGN 后判决采样点  E_b/N_0 = %d dB', EbNoDb), ...
    'FontSize', 15, 'FontWeight', 'bold');
xlabel('I'); ylabel('Q');
axis equal; axis([-1.35 1.35 -1.35 1.35]); grid on;
set(gca, 'FontSize', 11, 'LineWidth', 1.0, 'GridAlpha', 0.15);

sgtitle('MSK 星座图与 I/Q 平面分析', 'FontSize', 18, 'FontWeight', 'bold');

exportgraphics(fig, fullfile(outDir, '10_MSK_constellation_clean_ppt.png'), 'Resolution', 220);
exportgraphics(fig, fullfile(outDir, '10_MSK_constellation.png'), 'Resolution', 220);
close(fig);

fprintf('Clean constellation figure saved to %s\n', outDir);
