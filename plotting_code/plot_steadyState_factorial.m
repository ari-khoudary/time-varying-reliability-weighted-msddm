%% plot timeseries

clear;
load('colors.mat');
indir = {'../data/factorial/'};
pub_plot = 1;

%% load 
i = 1;
files = dir([indir{i} '*.mat']);
names = {files.name};

allData = [];
for k = 1:length(files)
    filepath = fullfile(files(k).folder, files(k).name);
    loaded = load(filepath);
    allData = [allData; loaded.data];  % horzcat struct arrays
end

cong_mask = ~strcmp({allData.congruent}, 'incongruent');
allData = allData(cong_mask);

cohLevels = unique([allData.trueCoherence]);
cueLevels = unique([allData.cue]);
gammaVals = unique([allData.memoryThinning]);

% compute averages across gamma levels
row_counter = 0;
for coh = 1:numel(cohLevels)
    coherence = cohLevels(coh);
    for c = 1:numel(cueLevels)
        cue = cueLevels(c);
        for g = 1:numel(gammaVals)
            row_counter = row_counter + 1;
            gamma = gammaVals(g);
            mask = [allData.trueCoherence] == coherence & ...
                [allData.cue] == cue & ...
                [allData.memoryThinning] == gamma;
            data = allData(mask);
            % compute mean timeseries
            thinMean(row_counter).memoryDrifts = mean([data.memoryDrifts], 2, 'omitnan');
            thinMean(row_counter).visionDrifts = mean([data.visionDrifts], 2, 'omitnan');
            thinMean(row_counter).memoryPrecisions = mean([data.memoryPrecisions], 2, 'omitnan');
            thinMean(row_counter).visionPrecisions = mean([data.visionPrecisions], 2, 'omitnan');
            thinMean(row_counter).decisionVariable = mean([data.decisionVariable], 2, 'omitnan');
            % write grouping variables
            thinMean(row_counter).trueCoherence = coherence;
            thinMean(row_counter).cue = cue;
            thinMean(row_counter).memoryThinning = gamma;
        end
    end
end

%% grid with gamma ranges + ribbon 

% default settings for main factorial figure
lineStyles = {'-', '--', ':'};
lineWidth = 2;
gammaLevels = {'1 (60Hz)', '5-10 (6-12Hz)', '12-30 (2-5Hz)'};

% make plot
figure;
t = tiledlayout('flow');
axHandles = gobjects(numel(cohLevels)*numel(cueLevels), 1);
idx = 0;
for i = 1:numel(cohLevels)
    for j = 1:numel(cueLevels)
        idx = idx + 1;
        axHandles(idx) = nexttile; hold on
        yline(0.5, 'LineStyle', ":", 'Color', [0.5 0.5 0.5]);
        for k = 1:numel(gammaLevels)
            % get ranges
                if k==1
                    gammaIdx = 1;
                elseif k==2
                    gammaIdx = 2:6;
                else
                    gammaIdx = 7:10;
                end
            % compute mask
            mask = [thinMean.trueCoherence] == cohLevels(i) & ...
                [thinMean.cue] == cueLevels(j) & ...
                ismember([thinMean.memoryThinning], gammaVals(gammaIdx));
            plotData = thinMean(mask);

            memMean = mean([plotData.memoryDrifts], 2);
            memSEM  = std([plotData.memoryDrifts], 0, 2) / sqrt(height(plotData));
            visMean = mean([plotData.visionDrifts], 2);
            visSEM  = std([plotData.visionDrifts], 0, 2) / sqrt(height(plotData));

            plotRibbon(memMean, memSEM, blue, lineStyles{k}, lineWidth);
            plotRibbon(visMean, visSEM, yellow, lineStyles{k}, lineWidth);
        end
        if ~pub_plot
            title(['cue = ', num2str(cueLevels(j)), ', coh = ', num2str(cohLevels(i))]);
        end
        ylabel('evidence weight (a.u.)')
        xlabel('time (a.u.)')
    end
end
% add legend for gamma only
styleHandles = gobjects(numel(gammaLevels), 1);
styleLabels  = cell(numel(gammaLevels), 1);
for k = 1:numel(gammaLevels)
    styleHandles(k) = plot(nan, nan, 'Color', 'k', ...
        'LineStyle', lineStyles{k}, 'LineWidth', lineWidth);
    styleLabels{k} = ['\gamma = ', gammaLevels{k}];
end
lgd = legend(styleHandles, styleLabels);
lgd.Layout.Tile = 'east';   % places one shared legend outside all subplots
linkaxes(axHandles, 'y');

exportgraphics(gcf, '../figures/steadyState_weights_betterLegend.png', 'Resolution', 300);

%% helper functions
function plotRibbon(y, err, color, lineStyle, lineWidth)
    y = y(:)';
    err = err(:)';
    x = 1:numel(y);

    % shaded region (upper/lower bound)
    xFill = [x, fliplr(x)];
    yFill = [y + err, fliplr(y - err)];
    fill(xFill, yFill, color, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');

    % mean line on top, with line style
    plot(x, y, 'Color', color, 'LineStyle', lineStyle, 'LineWidth', lineWidth);
end