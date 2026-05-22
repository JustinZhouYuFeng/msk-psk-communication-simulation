function draw_signal_space_noise(cfg, figDir, palette)
% 绘制不同信噪比下的判决样本分布。

fig = figure('Name', 'Signal-space noise', 'Color', 'w', 'Position', [80 80 1480 470]);
axes('Position', [0 0 1 1]);
axis off;
text(0.5, 0.94, '2PSK 一维信号空间中的噪声与判决门限', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontName', cfg.fontName, 'FontSize', 15, 'FontWeight', 'bold', ...
    'Color', palette.ink);

snrList = [0 4 8];
num = 700;
positions = [0.055 0.18 0.27 0.64; 0.365 0.18 0.27 0.64; 0.675 0.18 0.27 0.64];
for i = 1:numel(snrList)
    axes('Position', positions(i,:));
    gamma = 10^(snrList(i)/10);
    sigma = sqrt(cfg.Eb / (2 * gamma));
    bits = randi([0 1], 1, num);
    sym = 2*bits - 1;
    y = sym + sigma * randn(size(sym));
    jitter = 0.10 * randn(size(y));
    idx0 = bits == 0; idx1 = bits == 1;
    scatter(y(idx0), jitter(idx0), 12, palette.red, 'filled', 'MarkerFaceAlpha', 0.45); hold on;
    scatter(y(idx1), jitter(idx1), 12, palette.teal, 'filled', 'MarkerFaceAlpha', 0.45);
    xline(0, '--', 'Color', palette.ink, 'LineWidth', 1.1);
    xline(-1, ':', 'Color', palette.red, 'LineWidth', 1.0);
    xline(1, ':', 'Color', palette.teal, 'LineWidth', 1.0);
    text(-1, 0.36, 's_0', 'Color', palette.red, 'FontName', cfg.fontName, ...
        'FontSize', 10.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(0, 0.36, '门限 0', 'Color', palette.ink, 'FontName', cfg.fontName, ...
        'FontSize', 10.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(1, 0.36, 's_1', 'Color', palette.teal, 'FontName', cfg.fontName, ...
        'FontSize', 10.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    ylim([-0.45 0.45]); xlim([-3.2 3.2]);
    title(sprintf('E_b/N_0 = %g dB', snrList(i)), 'FontName', cfg.fontName);
    xlabel('相关器输出 z_k'); yticks([]);
    grid on; box off;
    set(gca, 'FontName', cfg.fontName, 'FontSize', 10.5, 'GridAlpha', 0.16);
end

exportgraphics(fig, fullfile(figDir, '04_signal_space_noise.png'), ...
    'Resolution', cfg.exportDpi, 'BackgroundColor', 'white');
if isfield(cfg, 'saveFigFiles') && cfg.saveFigFiles
    savefig(fig, fullfile(figDir, '04_signal_space_noise.fig'));
end
close(fig);
end
