%% specify simulation settings
clear

plotTraces = 1;
nSub = 1;

% 60 trials per block
% (presumably) half are slowFlicker, half are fastFlicker (30 trials per flicker level)
% 4 blocks per cue type: neutral, color, orientation, motor
% 4 x 60 = 240 neutral trials per subject
% 4 x 3 x 60 = 720 biased per subject
% doSampling_nuttida automatically decreases number of trials for neutral runs
nTrial = 3 * 4 * 30;

cue = [0.5 0.7];
cueSigma = [1];
trueCoherence = [0.685];
anticipatedCoherence = trueCoherence;
coherenceSigma = [1];
%threshold = [3 4 5];
threshold = [2 3 4];
visionThinning = 1;

trialDuration = 0.85; % baseline duration before adding trial delay

% early effect settings
delayPeriod = 1; % logical: do you want a delay period between cue and visual evidence?
delayDurations = [1]; % duration of cue + possible ISI values to be drawn at uniform

% half neutral trials (boolean); only relevant if cue==0.5
halfNeutralTrials = 0;

% do you want to save frame-by-frame information for each trial?
saveEvidence = 1;
saveAccumulators = 1;
saveDV = 1;
saveCounters = 1;
savePrecisions = 1;
saveDrifts = 1;

% proportion of bitflip noise
bitNoise = linspace(0.01, 0.2, 5);

% where do you want to save the results? (subdirectory of current dir)
outDir = '../data/nuttida_lowerThresh/';

%% flicker-condition-specific settings
% each condition pairs a visual presentation rate with its own
% memoryThinning sweep. 

flickerConditions(1).label               = 'fastFlicker';
flickerConditions(1).vizPresentationRate = 1/50;
flickerConditions(1).memoryThinning      = [6 8 12 14 20 33];
% 6  = 8.3 Hz
% 8  = 6.25 Hz
% 12 = 4.16 Hz
% 14 = 3.5 Hz
% 20 = 2.5 Hz
% 33 = 1.5 Hz

flickerConditions(2).label               = 'slowFlicker';
flickerConditions(2).vizPresentationRate = 1/33;
flickerConditions(2).memoryThinning      = [4 6 8 10 12 20];
% 4  = 8.25 Hz
% 6  = 5.5 Hz
% 8  = 4.125 Hz
% 10 = 3.3 Hz
% 12 = 2.5 Hz
% 20 = 1.5 Hz

%% create config files & run simulation

for f = 1:length(flickerConditions)
    vizPresentationRate = flickerConditions(f).vizPresentationRate;
    memoryThinning = flickerConditions(f).memoryThinning;
    flickerLabel = flickerConditions(f).label;

    for n = 1:length(bitNoise)
        nCombo = length(trueCoherence)*length(cue)*length(threshold)*length(memoryThinning)*length(vizPresentationRate)*nSub;
        allConfigs = repmat({struct('myfield', {})}, 1, nCombo);
        counter = 0;
        subIDs = repelem(1:18, 2);
        for subj = 1:nSub
            for d = 1:length(memoryThinning)
                for c = 1:length(threshold)
                    for b = 1:length(cue)
                        counter = counter+1;
                        config.nTrial = nTrial;
                        config.nSub = nSub;
                        config.subID = subIDs(counter);
                        config.trueCoherence = trueCoherence;
                        config.cue = cue(b);
                        config.anticipatedCoherence = trueCoherence;
                        config.cueSigma = cueSigma;
                        config.coherenceSigma = coherenceSigma;
                        config.threshold = threshold(c);
                        config.memoryThinning = memoryThinning(d);
                        config.visionThinning = visionThinning;
                        config.vizPresentationRate = vizPresentationRate;
                        config.trialDuration = trialDuration;
                        config.delayPeriod = delayPeriod;
                        config.delayDurations = delayDurations;
                        config.halfNeutralTrials = halfNeutralTrials;

                        config.saveEvidence = saveEvidence;
                        config.saveAccumulators = saveAccumulators;
                        config.saveDV = saveDV;
                        config.saveCounters = saveCounters;
                        config.savePrecisions = savePrecisions;
                        config.saveDrifts = saveDrifts;
                        config.outDir = outDir;

                        config.bitNoise = bitNoise(n);

                        allConfigs{counter} = config;
                        thisConfig = allConfigs{counter};

                        % status update
                        sprintf(['running: noise= ' num2str(bitNoise(n)) ', subject=' num2str(subIDs(counter)), ', cue=' num2str(cue(b)) ', thresh=' num2str(threshold(c)), ...
                            ', gamma=', num2str(memoryThinning(d)), ', ' flickerLabel])

                        % run sim
                        doSampling_nuttida(thisConfig);
                    end
                end
            end
        end
    end
end

sprintf('all flicker conditions complete!')