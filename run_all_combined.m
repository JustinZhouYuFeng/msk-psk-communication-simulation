% Communication Principles seminar simulation entry point.
% Topic choice: 2PSK plus the required MSK topic.

clear; close all; clc;

projectRoot = fileparts(mfilename('fullpath'));
srcDir = fullfile(projectRoot, 'src');
figDir = fullfile(projectRoot, 'outputs', 'figures');

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

addpath(srcDir);

fprintf('Running 2PSK simulation...\n');
results2psk = simulate_2psk(figDir);

fprintf('\nRunning MSK simulation...\n');
resultsMsk = simulate_msk(figDir);

fprintf('\nGenerating explanatory comparison figures...\n');
resultsExtra = simulate_extras(figDir, results2psk, resultsMsk);

save(fullfile(projectRoot, 'outputs', 'simulation_results.mat'), ...
    'results2psk', 'resultsMsk', 'resultsExtra');

fprintf('\nDone. Figures saved to:\n%s\n', figDir);
