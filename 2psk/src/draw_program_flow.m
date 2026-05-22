function draw_program_flow(cfg, figDir, palette)
% 绘制 MATLAB 仿真流程图。

fig = figure('Name', 'MATLAB program flow', 'Color', 'w', 'Position', [80 80 900 900]);
axis off; hold on;
title('2PSK MATLAB 仿真流程', 'FontName', cfg.fontName, ...
    'FontSize', 18, 'FontWeight', 'bold', 'Color', palette.ink);

steps = {'设置参数', '生成随机二进制序列', '0/1 映射为 -1/+1', ...
    '生成 2PSK 通带波形', 'FFT 估计频谱', '加入不同 E_b/N_0 的 AWGN', ...
    '相干相关积分与过零判决', '统计 BER 并叠加理论曲线', '扫描载波相位误差'};

x = 0.24; y0 = 0.83; w = 0.52; h = 0.055; gap = 0.035;
for i = 1:numel(steps)
    y = y0 - (i-1)*(h+gap);
    fillColor = palette.pale;
    if i == 4 || i == 6
        fillColor = [0.88 0.98 0.97];
    elseif i == 8 || i == 9
        fillColor = [0.90 0.96 1.00];
    end
    rectangle('Position', [x y w h], 'Curvature', 0.10, ...
        'FaceColor', fillColor, 'EdgeColor', palette.line, 'LineWidth', 1.15);
    text(x+w/2, y+h/2, steps{i}, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontName', cfg.fontName, ...
        'FontSize', 11.5, 'Color', palette.ink);
    if i < numel(steps)
        annotation(fig, 'arrow', [0.5 0.5], [y-0.002 y-gap+0.014], ...
            'Color', palette.muted, 'LineWidth', 1.05);
    end
end

exportgraphics(fig, fullfile(figDir, '00_program_flow.png'), ...
    'Resolution', cfg.exportDpi, 'BackgroundColor', 'white');
if isfield(cfg, 'saveFigFiles') && cfg.saveFigFiles
    savefig(fig, fullfile(figDir, '00_program_flow.fig'));
end
close(fig);
end
