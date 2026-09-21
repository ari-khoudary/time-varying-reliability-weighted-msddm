%% make plots to go in the paper
clear;
load('colors.mat')
rootdir = '../data/bornstein_steadyState_';
   % 'midISI/results/'];
cueLevels = [0.5 0.8];
simTypes = {'lowISI', 'midISI', 'highISI'};
pub_plot = 1;

for sim = 1:numel(simTypes)
    s = simTypes{sim};

    files = dir(fullfile([rootdir s], ['results/*.mat']));
    names = {files.name};
    allData = [];
    for k = 1:length(files)
        filepath = fullfile(files(k).folder, files(k).name);
        loaded = load(filepath);
        allData = [allData; loaded.data];  % horzcat struct arrays
    end

%%
cong_mask = ~strcmp({allData.congruent}, 'incongruent');
cue_mask = ismember([allData.cue], cueLevels);
configs = [allData.config];
bitNoise = [configs.bitNoise];


%% 
for fig = 1:2
    if fig == 1 % main text / subsetted just to bitNoise 0.11
        noise_mask = bitNoise == 0.105;
        plotData = allData(cong_mask & cue_mask & noise_mask);
    else
        plotData = allData(cong_mask & cue_mask);
    end
    cohLevels = unique([plotData.trueCoherence]);
    cueLevels = unique([plotData.cue]);
    gammaVals = unique([plotData.memoryThinning]);

    %% plot

    % high-level params
    alphaVal = 0.2;
    lineWidth = 2;
    lineStyles = {':', '-'};
    vizOnset = plotData(1).delayDurations * 60;
    time = 1:height(plotData(1).memoryAccumulator);
    time = time(:);

    % Create the two figures before the cue loop, with tiled layouts
    fig_reliability = figure;
    tlo_rel = tiledlayout(fig_reliability, 1, length(cueLevels));

    fig_drift = figure;
    tlo_dri = tiledlayout(fig_drift, 1, length(cueLevels));

    for j = 1:length(cueLevels)
        ax_rel = nexttile(tlo_rel); hold(ax_rel, 'on');
        ax_dri = nexttile(tlo_dri); hold(ax_dri, 'on');

        handles = [];
        labels = {};

        % add horiztonal line at 0.5
        yline(ax_dri, 0.5, 'LineStyle', ":", 'Color', [0.5 0.5 0.5]);

        % and vertical line at evidence onset
        xline(ax_dri, vizOnset);
        xline(ax_rel, vizOnset);

        for k = 1:length(cohLevels)
            filter = [plotData.trueCoherence] == cohLevels(k) & ...
                [plotData.cue] == cueLevels(j);
            d = plotData(filter);

            % --- lambdas ---
            memWeight = horzcat(d.memoryPrecisions);
            vizWeight = horzcat(d.visionPrecisions);

            memMean = mean(memWeight, 2);
            memSEM = std(memWeight, 0, 2) / sqrt(size(memWeight, 2));
            vizMean = mean(vizWeight, 2);
            vizSEM = std(vizWeight, 0, 2) / sqrt(size(vizWeight, 2));

            fill(ax_rel, [time; flipud(time)], [memMean + memSEM; flipud(memMean - memSEM)], ...
                blue, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            h_mem = plot(ax_rel, time, memMean, 'Color', blue, 'LineStyle', lineStyles{k}, 'LineWidth', lineWidth);

            fill(ax_rel, [time; flipud(time)], [vizMean + vizSEM; flipud(vizMean - vizSEM)], ...
                yellow, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(ax_rel, time, vizMean, 'Color', yellow, 'LineStyle', lineStyles{k}, 'LineWidth', lineWidth);

            % --- weights ---
            memWeight = horzcat(d.memoryDrifts);
            vizWeight = horzcat(d.visionDrifts);

            memMean = mean(memWeight, 2);
            memSEM = std(memWeight, 0, 2) / sqrt(size(memWeight, 2));
            vizMean = mean(vizWeight, 2);
            vizSEM = std(vizWeight, 0, 2) / sqrt(size(vizWeight, 2));

            fill(ax_dri, [time; flipud(time)], [memMean + memSEM; flipud(memMean - memSEM)], ...
                blue, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            h_mem = plot(ax_dri, time, memMean, 'Color', blue, 'LineStyle', lineStyles{k}, 'LineWidth', lineWidth);

            fill(ax_dri, [time; flipud(time)], [vizMean + vizSEM; flipud(vizMean - vizSEM)], ...
                yellow, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(ax_dri, time, vizMean, 'Color', yellow, 'LineStyle', lineStyles{k}, 'LineWidth', lineWidth);

            handles = [handles, h_mem];
            labels = [labels, sprintf('coh=%.2f', cohLevels(k))];
        end % coh loop

        % Apply formatting to both axes on both figs

        % lambdas
        xlabel(ax_rel, 'time (a.u.)');
        ylabel(ax_rel, 'reliability estimate (bits)');
        ylim(ax_rel, [2 3.5]);
        xlim(ax_rel, [0 length(time)+1]);

        % drifts
        xlabel(ax_dri, 'time (a.u.)');
        ylabel(ax_dri, 'evidence weight (a.u.)');
        ylim(ax_dri, [0.38 0.62]);
        xlim(ax_dri, [0 length(time)+1]);

        % add titles & legends
        if pub_plot==0
            title(ax_rel, ['cue = ' num2str(cueLevels(j))]);
            legend(ax_rel, handles, labels, 'Location', 'best');

            title(ax_dri, ['cue = ' num2str(cueLevels(j))]);
            legend(ax_dri, handles, labels, 'Location', 'best');
        end

    end % cue loop

    aspectRatio = [500 200]; % width, height

    fontsize(tlo_rel, 10, 'points');
    fontsize(tlo_dri, 10, 'points');

    for foo = {fig_reliability, fig_drift}
        f = foo{1};
        figure(f);
        f.Position(3:4) = aspectRatio;
    end

    if fig == 1
       exportgraphics(fig_reliability, sprintf('../figures/bornstein_%s_lambdas_0.1noise.png', s), 'Resolution', 300);
       exportgraphics(fig_drift, sprintf('../figures/bornstein_%s_weights_0.1noise.png', s), 'Resolution', 300);
    else
       exportgraphics(fig_reliability, sprintf('../figures/bornstein_%s_lambdas_all.png',s), 'Resolution', 300);
       exportgraphics(fig_drift, sprintf('../figures/bornstein_%s_weights_all.png',s), 'Resolution', 300);
    end
end
end