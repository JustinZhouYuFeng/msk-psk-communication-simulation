function write_result_summary(cfg, result, filePath)
% 写入报告可用的关键数值结果。

fid = fopen(filePath, 'w');
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '第二题：2PSK 仿真结果摘要\n');
fprintf(fid, '由 MATLAB 脚本 run_all.m 生成\n\n');

fprintf(fid, '仿真参数\n');
fprintf(fid, 'Tb = %.4g\nRb = %.4g\nsps = %d\nfc = %.4g Rb\nEb = %.4g\n', ...
    cfg.Tb, cfg.Rb, cfg.sps, cfg.fc/cfg.Rb, cfg.Eb);
fprintf(fid, 'BER 统计比特数 = %.0f\n\n', cfg.numBerBits);

fprintf(fid, 'BER 对比\n');
fprintf(fid, 'Eb/N0(dB)\t仿真 BER\t理论 BER\n');
for i = 1:numel(result.EbN0dB)
    fprintf(fid, '%+7.1f\t%.6e\t%.6e\n', ...
        result.EbN0dB(i), result.berSim(i), result.berTheory(i));
end

fprintf(fid, '\n载波相位模糊分析，Eb/N0 = %.1f dB\n', cfg.phaseEbN0dB);
fprintf(fid, '相位误差(度)\t仿真 BER\t理论趋势\n');
for i = 1:numel(result.phaseDeg)
    fprintf(fid, '%7.1f\t%.6e\t%.6e\n', ...
        result.phaseDeg(i), result.berPhaseSim(i), result.berPhaseTheory(i));
end
end
