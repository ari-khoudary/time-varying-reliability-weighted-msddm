%% specify simulation settings
clear
nSub = 1;
nTrial = 10; % per cue
cue = 0.8;
trueCoherence = 0.5;
anticipatedCoherence = trueCoherence;
threshold = 250;
memoryThinning = 10;
visionThinning = 1;
vizPresentationRate = 1/60;
trialDuration = 3;
bitNoise = 0.1;

% early effect settings
delayPeriod = 0; % logical: do you want a delay period between cue and visual evidence?
delayDurations = [1]; % duration of cue + possible ISI values to be drawn at uniform

% do you want to save frame-by-frame information for each trial?
saveEvidence = 1;
saveAccumulators = 1;
saveDV = 1;
saveCounters = 1;
savePrecisions = 1;
saveDrifts = 1;

% where do you want to save the results? (subdirectory of current dir)
outDir = '../data/example_traces/';

%% create cell array to store config files
nCombo = nSub*length(trueCoherence)*length(cue)*length(threshold)*length(memoryThinning);
allConfigs = repmat({struct('myfield', {})}, 1, nCombo);

%% create config files

counter=0;
for a = 1:length(trueCoherence)
    for b = 1:length(cue)
        for c = 1:length(threshold)
            for d = 1:length(memoryThinning)
                for s = 1:nSub

                    counter=counter+1;

                    config.nTrial = nTrial;
                    config.nSub = nSub;
                    config.subID = 1;
                    config.trueCoherence = trueCoherence(a);
                    config.cue = cue(b);
                    config.anticipatedCoherence = trueCoherence(a);
                    config.threshold = threshold(c);
                    config.memoryThinning = memoryThinning(d);
                    config.visionThinning = visionThinning;
                    config.vizPresentationRate = vizPresentationRate;
                    config.trialDuration = trialDuration;
                    config.delayPeriod = delayPeriod;
                    config.delayDurations = delayDurations;
                    config.bitNoise = bitNoise;

                    config.saveEvidence = saveEvidence;
                    config.saveAccumulators = saveAccumulators;
                    config.saveDV = saveDV;
                    config.saveCounters = saveCounters;
                    config.savePrecisions = savePrecisions;
                    config.saveDrifts = saveDrifts;
                    config.outDir = outDir;
                    config.seed = counter;

                    allConfigs{counter} = config;
                end
            end
        end
    end
end

%% run simulation
for i = 1:length(allConfigs)
    thisConfig = allConfigs{i};
    fprintf('Running trueCoh=%.2f, cue=%.2f, thinning=%.2f\n', ...
        thisConfig.trueCoherence, thisConfig.cue, thisConfig.memoryThinning);
    rng('shuffle')
    doSampling_dotProduct_bernoulli(thisConfig, 1);
end

