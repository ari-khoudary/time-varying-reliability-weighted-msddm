%% specify simulation settings
clear
nRuns = 1000; % how many runs of this simulation do you want to use to estimate a single subject?
nSub = 5; % how many individual subjects do you want? 
nTrial = 100; % how many trials, per cue, do you want each "subject" to complete on each run of the batch?
cue = [0.8 0.5];
cueSigma = [1];
trueCoherence = [0.8 0.55];
anticipatedCoherence = trueCoherence;
coherenceSigma = [1];
threshold = 250;
memoryThinning = [30, 20, 15, 12, 10, 8, 7, 6, 5, 1]; % mixture of memory "sampling rates"; convert to Hz using (1/(memoryThinning/vizPresentation)
% going for a mixture of "low" (2-5) and "high" (6-12); in Hz [2, 3, 4, 5, 6, 7.5, 8.5, 10, 12]
% also adding in 1:1 sample rate for baseline/comparison
visionThinning = 1;
vizPresentationRate = 1/60;
trialDuration = 3;

% early effect settings
delayPeriod = 1; % logical: do you want a delay period between cue and visual evidence?
delayDurations = [4 6 8]; % duration of cue + possible ISI values to be drawn at uniform

% what levels of bitNoise do you want?
bitNoise = linspace(0.01, 0.2, 5);

% do you want to save frame-by-frame information for each trial?
saveEvidence = 0;
saveAccumulators = 1;
saveDV = 1;
saveCounters = 0;
savePrecisions = 1;
saveDrifts = 1;

% where do you want to save the results?
outDir = 'bornstein_steadyState_allDurations/';

% write directories for the simulation
if ~exist(outDir, 'dir')
    mkdir(outDir);
    mkdir([outDir '/infiles']);
    mkdir([outDir '/results']);
end

%% write configs for each combination
% build base config from all workspace variables at once
vars = who();
for i = 1:length(vars)
    baseConfig.(vars{i}) = eval(vars{i});
end

% generate per-subject configs, overriding only what changes
uniqueConfigs = length(memoryThinning) * length(cue) * length(trueCoherence) * nSub * numel(bitNoise);
configs = cell(uniqueConfigs, 1);

counter = 0;
for n = 1:nSub
    for a = 1:length(trueCoherence)
        for b = 1:length(cue)
            for c = 1:length(memoryThinning)
                for d = 1:numel(bitNoise)
                    counter = counter + 1;
                    config = baseConfig;
                    config.trueCoherence = trueCoherence(a);
                    config.cue = cue(b);
                    config.anticipatedCoherence = trueCoherence(a);
                    config.memoryThinning = memoryThinning(c);
                    config.bitNoise = bitNoise(d);
                    config.seed = counter;
                    config.filename = sprintf('%.2fcue_%.2fcoh_%.2fthin_%.2fthresh_%.3fnoise_sub%03d', ...
                        cue(b), trueCoherence(a), memoryThinning(c), threshold, bitNoise(d), n);
                    configs{counter} = config;
                end
            end
        end
    end
end

%%
for s = 1:uniqueConfigs
    config = configs{s};
    save([config.outDir 'infiles/' config.filename '.mat'], 'config');
end

fprintf('Total configs written: %d\n', uniqueConfigs);
fprintf('Set  #SBATCH --array=1-%d', uniqueConfigs);
