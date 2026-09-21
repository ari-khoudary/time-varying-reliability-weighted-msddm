function data = doSampling_dotProduct_bernoulli(config, saveOut)

%% unpack params
nTrial = config.nTrial; %per cue
cue = config.cue;
anticipatedCoherence = config.anticipatedCoherence;
trueCoherence = config.trueCoherence;
threshold = config.threshold;
memoryThinning = config.memoryThinning;
visionThinning = config.visionThinning;
vizPresentationRate = config.vizPresentationRate;
trialDuration = config.trialDuration;
delayPeriod = config.delayPeriod;
delayDurations = config.delayDurations;
bitNoise = config.bitNoise;

% do you want to save any frame-by-frame information?
saveEvidence = config.saveEvidence;
saveAccumulators = config.saveAccumulators;
saveDV = config.saveDV;
saveCounters = config.saveCounters;
savePrecisions = config.savePrecisions;
saveDrifts = config.saveDrifts;

% where do you want to save the results?
outDir = config.outDir;

if isfield(config, 'subID')
    subID = config.subID;
end

%% translate parameters into simulation-space
if cue ~=0 
    congruentTrials = ceil(nTrial*cue);
    congruent = [ones(congruentTrials, 1); zeros(nTrial-congruentTrials,1)];
else
    congruent = ones(nTrial, 1);
end

% make noise durations
if delayPeriod == 1
    nFrames = round(max(delayDurations) + trialDuration) / vizPresentationRate;
else
    nFrames = trialDuration / vizPresentationRate;
end
% ensure an event amount of frames for computational convenience
if mod(nFrames,2)>0
    nFrames=nFrames+1;
end

%% create arrays to hold values
choices = zeros(nTrial, 2); %raw choice; forced choice (state of accumulator)
RTs = zeros(nTrial, 1);
startPoints = zeros(nTrial, 2); %DV start point in first and second noise periods
memoryAccumulator = zeros(nFrames, nTrial);
visionAccumulator = zeros(nFrames, nTrial);
decisionVariable = zeros(nFrames, nTrial);
memoryPrecisions = zeros(nFrames, nTrial);
visionPrecisions = zeros(nFrames, nTrial);
memoryDrift = zeros(nFrames, nTrial);
visionDrift = zeros(nFrames, nTrial);
counters = zeros(nFrames, 4, nTrial);

% create index variables
alphaMem_idx = 1;
betaMem_idx = 2;
alphaVis_idx = 3;
betaVis_idx = 4;

% set up
% precompute entropy distribution
p = 0.01:.01:0.99;
entropy = zeros(length(p), 1);
for i = 1:length(p)
    entropy(i) = computeEntropy(p(i));
end

% create memory evidence stream
if cue ~= 0
    memoryEvidence = (binornd(1, cue, [nFrames, nTrial])*2-1);
else
    memoryEvidence = NaN;
end

% create visual evidence stream
visionEvidence = (binornd(1,trueCoherence, [nFrames,nTrial])*2-1);


% compute delay periods
nDelays = length(delayDurations);
trialDelays = ones(1, nTrial);

% add to sensory evidence
if delayPeriod == 1
    for trial = 1:nTrial
        delayIdx = randi(nDelays);
        trialDelays(trial) = delayDurations(delayIdx) / vizPresentationRate;
        if anticipatedCoherence ~= trueCoherence
            visionEvidence(1:trialDelays(trial), trial) =  (binornd(1,anticipatedCoherence, [trialDelays(trial),1])*2-1);
        end
    end
end

% flip sign of memory for incongruent trials - upper bound always correct
if cue ~=0
    memoryEvidence(:, congruentTrials+1:nTrial) = -1*memoryEvidence(:, congruentTrials+1:nTrial);
end

% flexibly adjust output of mod() command used to control memoryThinning
if config.memoryThinning == 1
    modOutcome = 0;
else
    modOutcome = 1;
end

% add "bitflip" noise
allFrames = nFrames * nTrial;
randi_viz = randsample(allFrames, round(bitNoise * allFrames));
randi_mem = randsample(allFrames, round(bitNoise * allFrames));
visionEvidence(randi_viz) = -1 * visionEvidence(randi_viz);
memoryEvidence(randi_mem) = -1 * memoryEvidence(randi_mem);

%% run simulation
for trial=1:nTrial
    % initialize counters
    alphaMem = 1;
    betaMem = 1;
    alphaVis = 1;
    betaVis = 1;

    % compute time-varying drift rate
    for frame=1:nFrames

        % sample from true or simulated vision
        if frame < trialDelays(trial) && cue ~=0
            if mod(frame, memoryThinning)==modOutcome
                if visionEvidence(frame, trial) > 0
                    alphaVis = alphaVis + 1;
                elseif visionEvidence(frame, trial) < 0
                    betaVis = betaVis + 1;
                end
                % compute normalized beta pdf
                visionPDF = betapdf(p, alphaVis, betaVis) ./ sum(betapdf(p, alphaVis, betaVis));
                % compute precision as inverse belief-weighted entropy
                visionPrecisions(frame, trial) = 1/sum(visionPDF .* entropy');
            else
                visionPrecisions(frame, trial) = visionPrecisions(frame-1, trial);
            end
        else % if trialDelay has passed or cue == 0
            if mod(frame, visionThinning)==0
                if visionEvidence(frame,trial) > 0
                    alphaVis = alphaVis + 1;
                elseif visionEvidence(frame, trial) < 0
                    betaVis = betaVis + 1;
                end
            end
            % compute normalized beta pdf
            visionPDF = betapdf(p, alphaVis, betaVis) ./ sum(betapdf(p, alphaVis, betaVis));
            % compute precision as inverse belief-weighted entropy
            visionPrecisions(frame, trial) = 1/sum(visionPDF .* entropy');
        end

        % store counter values
        counters(frame, alphaVis_idx, trial) = alphaVis;
        counters(frame, betaVis_idx, trial) = betaVis;

        % sample from memory
        if cue ~= 0
        if memoryThinning == 1
            if mod(frame, memoryThinning)==modOutcome
                if memoryEvidence(frame, trial) > 0
                    alphaMem = alphaMem + 1;
                else
                    betaMem = betaMem + 1;
                end
    
                % compute normalized beta pdf
                memoryPDF = betapdf(p, alphaMem, betaMem) ./ sum(betapdf(p, alphaMem, betaMem));
                % compute precision as inverse belief-weighted entropy
                memoryPrecisions(frame, trial) = 1/sum(memoryPDF .* entropy');
            end
        else
        if mod(frame, memoryThinning)==modOutcome % this allows a memory sample on the first frame
            % update memory counters
            if memoryEvidence(frame, trial) > 0
                alphaMem = alphaMem + 1;
            else
                betaMem = betaMem + 1;
            end

            % compute normalized beta pdf
            memoryPDF = betapdf(p, alphaMem, betaMem) ./ sum(betapdf(p, alphaMem, betaMem));
            % compute precision as inverse belief-weighted entropy
            memoryPrecisions(frame, trial) = 1/sum(memoryPDF .* entropy');
        else
            memoryPrecisions(frame,trial) = memoryPrecisions(frame-1,trial);
        end
        end
        end %if cue ~= 0

        % store counter values
        counters(frame, alphaMem_idx, trial) = alphaMem;
        counters(frame, betaMem_idx, trial) = betaMem;

        % compute relative precision evidence weights
        if cue ~=0
            visionDriftRate = visionPrecisions(frame,trial) / (visionPrecisions(frame,trial) + memoryPrecisions(frame,trial));
            memoryDriftRate = memoryPrecisions(frame,trial) / (visionPrecisions(frame,trial) + memoryPrecisions(frame,trial));
            visionDrift(frame, trial) = visionDriftRate;
            memoryDrift(frame, trial) = memoryDriftRate;

            % compute time-varying relative precision-weighted decision variable
            memorySample = memoryEvidence(frame, trial);
            visualSample = visionEvidence(frame, trial);
    
            % accumulate evidence
            if frame==1
                memoryAccumulator(frame, trial) = memorySample * memoryDriftRate;
                if trialDelays(trial) == 1
                    visionAccumulator(frame, trial) = visualSample * visionDriftRate;
                    decisionVariable(frame, trial) = visualSample * visionDriftRate + memorySample * memoryDriftRate;
                else
                    decisionVariable(frame, trial) = memorySample * memoryDriftRate + binornd(1, 0.5)*visionDriftRate;
                end
    
            elseif frame <= trialDelays(trial)
                if mod(frame, memoryThinning)==modOutcome
                    memoryAccumulator(frame, trial) = memoryAccumulator(frame-1, trial) + memorySample * memoryDriftRate;
                    decisionVariable(frame, trial) = decisionVariable(frame-1, trial) + memorySample*memoryDriftRate + binornd(1, 0.5)*visionDriftRate;
                else
                    memoryAccumulator(frame, trial) = memoryAccumulator(frame-1, trial);
                    decisionVariable(frame, trial) = decisionVariable(frame-1, trial);
                end
    
            else % if frame > trialDelays(trial)
                visionAccumulator(frame, trial) = visionAccumulator(frame-1, trial) + visualSample * visionDriftRate;
                if mod(frame, memoryThinning) == modOutcome
                    memoryAccumulator(frame, trial) = memoryAccumulator(frame-1, trial) + memorySample * memoryDriftRate;
                    decisionVariable(frame, trial) = decisionVariable(frame-1, trial) + memorySample*memoryDriftRate + visualSample*visionDriftRate;
                else
                    memoryAccumulator(frame, trial) = memoryAccumulator(frame-1, trial);
                    decisionVariable(frame, trial) = decisionVariable(frame-1, trial) + visualSample*visionDriftRate;
                end
            end
        else
            % IF RUNNING WITH NO MEMORY SAMPLING (cue == 0)
            visionDriftRate = visionPrecisions(frame, trial);
            visualSample = visionEvidence(frame, trial);
            if frame == 1
                visionAccumulator(frame, trial) = visualSample * visionDriftRate;
                decisionVariable(frame, trial) = visionAccumulator(frame, trial);
            else
                visionAccumulator(frame, trial) = visionAccumulator(frame-1, trial) + visualSample * visionDriftRate;
                decisionVariable(frame, trial) = visionAccumulator(frame, trial);
            end
        end
    end
        

    % make decision
    % find point at which evidence crosses threshold
    boundaryIdx = find(abs(decisionVariable(:, trial))>threshold, 1);
    if isempty(boundaryIdx)
        boundaryIdx = nFrames;
    end

    % store crossing point as RT
    RTs(trial) = boundaryIdx;

    % populate choice matrix accordingly - first column is "raw"
    % responses, second is "forced"
    % upper bound is always correct
    if decisionVariable(boundaryIdx, trial) > threshold
        choices(trial, 1) = 1;
        choices(trial, 2) = 1;
    elseif boundaryIdx==nFrames 
        choices(trial, 1) = NaN;
        if decisionVariable(boundaryIdx, trial) > 0
            choices(trial, 2) = 1;
        else
            choices(trial, 2) = 0;
        end
    else % if wrong bound is reached
        choices(trial, 1) = 0;
        choices(trial, 2) = 0;
    end

    % populate startPoints matrix
    if delayDurations==1
        startPoints(trial, 1) = decisionVariable(trialDelays(trial)+1, trial);
    end
end

%% store results
% simulation settings
data.seed = config.seed;
data.nTrial = nTrial;
data.trialDuration = trialDuration;
data.cue = cue;
data.trueCoherence = trueCoherence;
data.anticipatedCoherence = anticipatedCoherence;
data.threshold = threshold;
data.congruent = logical(congruent);
data.memoryThinning = memoryThinning;
data.visionThinning = visionThinning;
data.nFrames = nFrames;
data.trialDuration = trialDuration;
data.delayPeriod = delayPeriod;
data.bitNoise = bitNoise;

if delayPeriod==1
    data.delayDurations = delayDurations;
    data.trialDelays = trialDelays;
else
    data.delayDurations = NaN;
    data.trialDelays = NaN;
end
data.counters = counters;
data.startPoints = startPoints;

% behavior
data.choices = choices;
data.RT = RTs;

% optional frame-by-frame info
if saveEvidence==1
    data.memoryEvidence = memoryEvidence;
    data.visionEvidence = visionEvidence;
end

if saveAccumulators==1
    data.memoryAccumulator = memoryAccumulator;
    data.visionAccumulator = visionAccumulator;
end

if saveDV==1
    data.decisionVariable = decisionVariable;
end

if saveCounters==1
    data.counters=counters;
end

if savePrecisions==1
    data.memoryPrecisions = memoryPrecisions;
    data.visionPrecisions = visionPrecisions;
end

if saveDrifts==1
    data.memoryDrifts = memoryDrift;
    data.visionDrifts = visionDrift;
end

if isfield(config, 'subID')
    data.subID = subID;
end
%% save results
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if saveOut
    if exist('subID', 'var')
        outfile = [outDir '/s' num2str(subID) '_' num2str(cue) 'cue_' num2str(trueCoherence) 'coh_' num2str(threshold) 'thresh_' num2str(memoryThinning) 'thin_' num2str(bitNoise) 'noise.mat'];
    else
        outfile = [outDir '/' num2str(cue) 'cue_' num2str(trueCoherence) 'coh_' num2str(threshold) 'thresh_' num2str(memoryThinning) 'thin_' num2str(bitNoise) 'noise.mat'];
    end
    save(outfile, 'data')
end
end

%% helper functions
function entropy = computeEntropy(distribution)
    entropy = -sum(distribution .* log2(distribution));
end




