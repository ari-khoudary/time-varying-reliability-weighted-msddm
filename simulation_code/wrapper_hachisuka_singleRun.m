%% specify simulation settings
clear
runParallel = 0;
plotTraces = 1;
nSub = 1;
nTrial = 30;
cue = [0.55 0.9];
cueSigma = [1];
trueCoherence = [0.545];
anticipatedCoherence = trueCoherence;
coherenceSigma = [1];
threshold = [4, 6];
memoryThinning = [6 7 8 9 10 12 15 18 21 30];
% 6 = 12.5
% 7 = 10.7 Hz
% 8 = 9.3 Hz
% 9 = 8.3 Hz
% 10 = 7.5 Hz
% 12 = 6.25 Hz
% 15 = 5 Hz
% 18 = 4.16 Hz
% 21 = 3.5 Hz
% 30 = 2.5 Hz
visionThinning = 1;
vizPresentationRate = [1/75];
trialDuration = 2;

% early effect settings
delayPeriod = 0; % logical: do you want a delay period between cue and visual evidence?
delayDurations = [0]; % duration of cue + possible ISI values to be drawn at uniform

% half neutral trials (boolean); only relevant if cue==0.5
halfNeutralTrials = 0;

% do you want to save frame-by-frame information for each trial?
saveEvidence = 0;
saveAccumulators = 0;
saveDV = 1;
saveCounters = 0;
savePrecisions = 0;
saveDrifts = 1;

% add noise
bitNoise = 0.105;
%bitNoise = linspace(0.01, 0.2, 5);

% where do you want to save the results? (subdirectory of current dir)
outDir = '../data/hachisuka_0.1only2/';

%% set up reproducible stochasticity & run sim

for n = 1:length(bitNoise)
    noise = bitNoise(n);
    uniqueSubs = length(threshold) * length(memoryThinning);
    subIDs = repelem(1:uniqueSubs, 2);

    nRuns = 1;
    totalIterations = nRuns * length(subIDs);
    rng('shuffle');
    allSeeds = randi(2^31 - 1, 1, totalIterations);

    nFrames = 150;
    post_dv = NaN(nFrames, nRuns);
    pre_dv = post_dv;

    % run simulation
    sim_counter = 0;
    run_counter = 1;
    while run_counter <= nRuns
        for d = 1:length(memoryThinning)
            for c = 1:length(threshold)
                for b = 1:length(cue)

                    sim_counter=sim_counter+1;
                    config.nTrial = nTrial;
                    config.nSub = nSub;
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
                    config.subID = nSub;

                    config.saveEvidence = saveEvidence;
                    config.saveAccumulators = saveAccumulators;
                    config.saveDV = saveDV;
                    config.saveCounters = saveCounters;
                    config.savePrecisions = savePrecisions;
                    config.saveDrifts = saveDrifts;
                    config.outDir = outDir;
                    rng(allSeeds(sim_counter))
                    config.seed = allSeeds(sim_counter);
                    config.bitNoise = bitNoise(n);

                    % status update
                    sprintf(['run= ', num2str(run_counter), ', sim=' num2str(sim_counter), ', cue=' num2str(cue(b)) ', thresh=' num2str(threshold(c)), ...
                        ', gamma=', num2str(memoryThinning(d)), 'noise = ', num2str(noise)])

                    % run sim
                    data = doSampling_dotProduct_bernoulli(config, 0);

                    % store relevant variables
                    allData(sim_counter).cue = data.cue;
                    %allData(counter).coh = data.trueCoherence;
                    allData(sim_counter).memoryThinning = data.memoryThinning;
                    allData(sim_counter).memoryWeights = data.memoryDrifts;
                    allData(sim_counter).RT = data.RT;
                    allData(sim_counter).decisionVariable = data.decisionVariable;
                    allData(sim_counter).bitNoise = noise;
                    % compute mean DV
                    dv = data.decisionVariable(:, logical(data.congruent));
                    for trial = 1:nTrial
                        if data.RT(trial) < data.nFrames
                            dv(data.RT(trial):data.nFrames, trial) = NaN;
                        end
                    end
                    allData(sim_counter).meanDV = mean(dv, 2, 'omitnan');
                end
            end
        end
        post = [allData.cue]==0.9;
        post_dv(:, run_counter) = mean(horzcat(allData(post).meanDV), 2, 'omitnan');
        pre_dv(:, run_counter) = mean(horzcat(allData(~post).meanDV), 2, 'omitnan');
        if nRuns >1
            run_counter = run_counter + 1;
        else
            pre_sem = std(horzcat(allData(~post).meanDV), 0, 2, 'omitnan') ./ sqrt(uniqueSubs);
            post_sem = std(horzcat(allData(post).meanDV), 0, 2, 'omitnan') ./ sqrt(uniqueSubs);
            break
        end
    end

    save([outDir 'allData_' num2str(noise) 'noise.mat'] , 'allData')
end