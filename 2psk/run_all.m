%% 通信原理研讨第二题：2PSK
% 本脚本用于生成第二题 2PSK 研讨所需的全部图像和结果数据。
% 脚本仅使用 MATLAB 基础函数，不依赖通信工具箱。

clear; clc; close all;
rng(2026);

rootDir = fileparts(mfilename('fullpath'));
outDir = fullfile(rootDir, 'outputs');
figDir = fullfile(outDir, 'figures');
if ~exist(outDir, 'dir'), mkdir(outDir); end
if ~exist(figDir, 'dir'), mkdir(figDir); end

addpath(fullfile(rootDir, 'src'));

cfg = default_2psk_config();
result = simulate_2psk_system(cfg, figDir);

save(fullfile(outDir, 'topic2_2psk_results.mat'), 'cfg', 'result');
write_result_summary(cfg, result, fullfile(outDir, 'result_summary.txt'));

fprintf('\n运行完成。图像已保存到：\n%s\n', figDir);
fprintf('结果摘要已保存到：\n%s\n', fullfile(outDir, 'result_summary.txt'));
