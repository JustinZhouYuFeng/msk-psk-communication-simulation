function cfg = default_2psk_config()
% 设置第二题 2PSK 仿真的默认参数。

cfg.Tb = 1;                 % 归一化比特周期
cfg.Rb = 1 / cfg.Tb;        % 比特率
cfg.sps = 80;               % 每符号采样点数
cfg.fs = cfg.sps / cfg.Tb;  % 采样频率
cfg.fc = 2 * cfg.Rb;        % 载波频率，降低后便于观察波形
cfg.Eb = 1;                 % 归一化比特能量
cfg.amp = sqrt(2 * cfg.Eb / cfg.Tb);

cfg.numPlotBits = 24;
cfg.numSpecBits = 1024;
cfg.numBerBits = 8e5;
cfg.EbN0dB = -4:2:12;
cfg.phaseDeg = [0 15 30 45 60 75 90 105 120 150 180];
cfg.phaseEbN0dB = 6;

cfg.fontName = 'Microsoft YaHei';
cfg.lineWidth = 1.55;
cfg.exportDpi = 240;
cfg.saveFigFiles = false;
end
