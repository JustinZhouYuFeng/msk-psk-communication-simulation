function draw_phase_decision_demo(cfg, figDir, palette)
% 展示载波相位误差如何改变判决结果。

theta = 0:1:180;
c = cosd(theta);

fig = figure('Name', 'Phase decision demo', 'Color', 'w', 'Position', [80 80 1120 640]);
axes('Position', [0 0 1 1]);
axis off;
text(0.5, 0.95, '载波相位误差导致的有效分量变化与判决极性', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold', ...
    'Color', palette.ink);

axes('Position', [0.10 0.45 0.80 0.38]);
plot(theta, c, 'Color', palette.blue, 'LineWidth', 2.0); hold on;
yline(0, '--', 'Color', palette.ink, 'LineWidth', 1.0);
xline(90, ':', 'Color', palette.amber, 'LineWidth', 1.3);
xline(180, ':', 'Color', palette.red, 'LineWidth', 1.3);
grid on; box off; xlim([0 180]); ylim([-1.1 1.1]);
xlabel('相位误差 \theta / 度'); ylabel('cos(\theta)');
text(35, 0.78, '有效判决距离下降', 'Color', palette.blue, 'FontName', cfg.fontName, 'FontSize', 11);
text(104, -0.72, '输出极性反转', 'Color', palette.red, 'FontName', cfg.fontName, 'FontSize', 11);
text(90, 1.0, '90°', 'Color', palette.amber, 'FontName', cfg.fontName, ...
    'FontSize', 10.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
text(174, 0.82, '180°', 'Color', palette.red, 'FontName', cfg.fontName, ...
    'FontSize', 10.5, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
set(gca, 'FontName', cfg.fontName, 'FontSize', 11, 'GridAlpha', 0.18);

axes('Position', [0 0 1 1]);
axis off; hold on; xlim([0 1]); ylim([0 1]);
cases = {'\theta=0°', '\theta=90°', '\theta=180°'};
notes = {'正常判决', '近似随机', '0/1 整体互换'};
colors = {palette.teal, palette.amber, palette.red};
for i = 1:3
    x = 0.17 + (i-1)*0.27;
    rectangle('Position', [x 0.18 0.17 0.17], 'Curvature', 0.06, ...
        'FaceColor', [0.96 0.98 1.00], 'EdgeColor', palette.line, 'LineWidth', 1.15);
    text(x+0.085, 0.29, cases{i}, 'HorizontalAlignment', 'center', ...
        'FontName', cfg.fontName, 'FontSize', 14, 'FontWeight', 'bold', 'Color', colors{i});
    text(x+0.085, 0.22, notes{i}, 'HorizontalAlignment', 'center', ...
        'FontName', cfg.fontName, 'FontSize', 12, 'Color', palette.ink);
end
text(0.5, 0.08, '结论：相干解调必须解决载波恢复问题，必要时可配合差分编码缓解 180° 相位模糊。', ...
    'HorizontalAlignment', 'center', 'FontName', cfg.fontName, 'FontSize', 12.5, 'Color', palette.muted);

exportgraphics(fig, fullfile(figDir, '07_phase_decision_demo.png'), ...
    'Resolution', cfg.exportDpi, 'BackgroundColor', 'white');
if isfield(cfg, 'saveFigFiles') && cfg.saveFigFiles
    savefig(fig, fullfile(figDir, '07_phase_decision_demo.fig'));
end
close(fig);
end
