%% plots model components
clear
load('colors.mat')
infiles = {'hanks.mat', 'bornstein_lowCoh.mat', 'bornstein_lowCue.mat'};
outfiles = {'_hanks', '_bornstein', '_bornsteinLowCue'};
outdir = '../figures/hb_singleTrial/';
plotNoise = 0;
trials = [5 6 4];
fontSize = 12;
delayDuration = 240;
vertLineStyle = '-';
vertLineWidth = 1.5;
dvLineWidth = 2;
accLineWidth = 2;
threshValue = 30;

% 1 = accumulators
% 2 = reliabilities
% 3 = weights
% 4 = evidence
% 5 = beliefs
% 6 = vis accumulator
% 7 = memory accumulator
% 8 = vis + memory
panels_to_plot = [1:5];
plot_wide = 0;

for file = 3:numel(infiles)
    panels = struct();
    data = load(fullfile('../data/example_traces/', infiles{file})).data;
    trial = trials(file);
    if file ==1
        cutoff_idx = data.nFrames;
        time = 1:cutoff_idx;
        %wide = 400;
        %tall = 250;
        if plot_wide
            wide = 400;
            tall = 250;
        end
    else 
        thresh_idx = find(data.decisionVariable(:, trial) >= threshValue, 1);
        if isempty (thresh_idx)
            time = 1:data.nFrames;
            cutoff_idx = length(time);
        else
            time = 1:thresh_idx;
            cutoff_idx = length(time);
        end
    end

    panels(1).name = 'all_accumulators';
    panels(1).title = 'x_{t}: dynamic reliability-weighted accumulators';
    panels(1).ylabel = 'accumulated evidence (a.u.)';
    if file > 1
        panels(1).ylim = [-10, 35];
    end

    panels(2).name = 'both_reliabilities';
    panels(2).title = '\lambda_{s_{t}}: evidence reliability estimate';
    panels(2).ylabel = 'reliability (bits)';
    %panels(10).ylim = [0.15, 0.25];

    panels(3).name = 'both_weights';
    panels(3).title = 'w_{s_{t}}: evidence weights';
    panels(3).ylabel = 'evidence weight (a.u.)';
    %panels(13).ylim = [0.4, 0.6];

    panels(4).name = 'both_evidence';
    panels(4).title = 'o_{s_{t}}: momentary evidence';
    panels(4).ylabel = 'sample (a.u.)';
    panels(4).ylim = [-3, 3];

    panels(5).name = 'both_beliefs';
    panels(5).title =  'g_{s}(t): belief about signal strength';
    panels(5).ylabel = 'probability density';
    panels(5).ylim = [];
    if file == 1
        panels(5).xlim = [0, 200];
    end

    panels(6).name = 'vision_accumulator';
    panels(6).title = 'vision accumulator';
    panels(6).ylabel = 'accumulated evidence (a.u.)';
    if file == 1
        panels(6).ylim = [-4, 8];
    else
        panels(6).ylim = [-10, 35];
    end

    panels(7).name = 'memory_accumulator';
    panels(7).title = 'memory accumulator';
    panels(7).ylabel = 'accumulated evidence (a.u.)';
    if file == 1
        panels(7).ylim = [-4, 8];
    else
        panels(7).ylim = [-10, 35];
    end

    panels(8).name = 'memAndVis_accumulators';
    panels(8).title = '';
    panels(8).ylabel = 'accumulated evidence (a.u.)';
    if file == 1
        panels(8).ylim = [-4, 8];
    else
        panels(8).ylim = [-10, 35];
    end

    % thin out memory evidence for plotting
    memEvidence = NaN(data.nFrames, 1);
    memEvidence(mod(1:data.nFrames, data.memoryThinning)==1) = ...
        data.memoryEvidence(mod(1:data.nFrames, data.memoryThinning)==1, trial);

    % Clean vision evidence data once
    data.visionEvidence(data.visionEvidence == 0) = NaN;

    %% plot
    for f = 1:length(plotNoise)
        % iterate over plots with & without noise periods
        noisePeriods = plotNoise(f);

        % get counters for time-varying betas
        memoryAlphas = data.counters(:, 1, trial);
        memoryBetas = data.counters(:, 2, trial);
        visionAlphas = data.counters(:, 3, trial);
        visionBetas = data.counters(:, 4, trial);

        % Create static plots for each panel
        for panel_idx = panels_to_plot
            panel = panels(panel_idx);
            outfile = [panel.name outfiles{file} '.png'];

            wide = 350;
            tall = 300;

            if file > 1 && panel_idx > 1
                wide = 450;
            end

            % Create figure for this panel
            figure('Position', [100, 100, wide, tall], 'Visible', 'off', ...
                'Color', 'white', 'InvertHardcopy', 'off');
            ax = gca;
            hold(ax, 'on');

            % set up clean axes
            set(ax, 'Color', 'white', ...
                'Box', 'off', ...
                'LineWidth', 1, ...
                'TickDir', 'out', ...
                'XColor', [0 0 0], ...
                'YColor', [0 0 0], ...
                'FontSize', fontSize, ...
                'FontName', 'Helvetica');

            % start plotting different panels
            switch panel_idx

                case 1 % all accumulators
                    if file > 1
                        data.visionAccumulator(1:delayDuration, :) = NaN;
                    end
                    yline(0, 'LineStyle', ':');
                    if file == 1
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                        h3 = plot(time, data.decisionVariable(1:cutoff_idx, trial), '-', 'LineWidth', dvLineWidth + 2, 'Color', green);
                    elseif file == 2 % high cue, low coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', yellow);
                        h3 = plot(time, data.decisionVariable(1:cutoff_idx, trial), '-', 'LineWidth', dvLineWidth, 'Color', green);
                    elseif file == 3 % low cue, high coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                        h3 = plot(time, data.decisionVariable(1:cutoff_idx, trial), '-', 'LineWidth', dvLineWidth, 'Color', green);
                    end

                case 2 % both precisions
                    if file == 1
                        plot(time, data.memoryPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 2 % strong cue, weak coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        plot(time, data.memoryPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionPrecisions(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', yellow);
                    else % weak cue, strong coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        plot(time, data.memoryPrecisions(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    end

                case 3 % both weights
                    if file == 1
                        plot(time, data.memoryDrifts(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionDrifts(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 2 % strong cue, weak coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        plot(time, data.memoryDrifts(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionDrifts(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', yellow);
                    else % weak cue, strong coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        plot(time, data.memoryDrifts(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', blue);
                        plot(time, data.visionDrifts(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    end

                case 4 % both evidence streams
                    vizEvid = data.visionEvidence(1:cutoff_idx, trial);
                    validIdx = ~isnan(vizEvid);
                    vizEvid(~validIdx) = 0;
                    if file > 1
                        vizEvid(1:delayDuration) = NaN;
                    end
                    if file > 1
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                    end
                    h1 = plot(time, vizEvid, '.-', 'MarkerSize', 15, 'LineWidth', 0.5, 'Color', yellow);
                    validIdx = ~isnan(memEvidence);
                    validIdx = validIdx(1:cutoff_idx);
                    plot(time(validIdx), memEvidence(validIdx), '.-', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', blue);
                    if file==3
                        h2 = plot(time(validIdx), memEvidence(validIdx), ':.', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', blue,'LineStyle', ':');
                    else
                        h2 = plot(time(validIdx), memEvidence(validIdx), '.-', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', blue);
                    end

                    yline(0, 'LineStyle', ':', 'HandleVisibility', 'off');

                case 5 % both beliefs
                    mem_opt.refLine = data.cue;
                    viz_opt.refLine = data.trueCoherence;
                    if file > 1
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                    end
                    plotBetaTimeEvolution(time, memoryAlphas, memoryBetas, data.memoryThinning, blue, ax);
                    plotBetaTimeEvolution(time, visionAlphas, visionBetas, data.memoryThinning, yellow, ax);
                    yline(0, 'LineStyle', ':', 'HandleVisibility', 'off');


                case 6 % vision accumulator
                    if file > 1
                        data.visionAccumulator(1:delayDuration, :) = NaN;
                    end
                    yline(0, 'LineStyle', ':');
                    if file == 1
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 2 % high cue, low coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 3 % low cue, high coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    end

                case 7 % all accumulators
                    if file > 1
                        data.visionAccumulator(1:delayDuration, :) = NaN;
                    end
                    yline(0, 'LineStyle', ':');
                    if file == 1
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                    elseif file == 2 % high cue, low coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                    elseif file == 3 % low cue, high coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', blue);
                    end

                case 8 % all accumulators
                    if file > 1
                        data.visionAccumulator(1:delayDuration, :) = NaN;
                    end
                    yline(0, 'LineStyle', ':');
                    if file == 1
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 2 % high cue, low coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', yellow);
                    elseif file == 3 % low cue, high coh
                        xline(0, 'LineStyle', vertLineStyle, 'Color', blue, 'LineWidth', vertLineWidth);
                        xline(delayDuration, 'LineStyle', vertLineStyle, 'Color', yellow, 'LineWidth', vertLineWidth);
                        h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), ':', 'LineWidth', accLineWidth, 'Color', blue);
                        h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', accLineWidth, 'Color', yellow);
                    end


            end

            % Common axis properties
            if file > 1
                xlim([-50 max(time)]);
                % elseif file == 1 && panel_idx==1
                %     fontSize = fontSize + 4;
            elseif file == 1 && panel_idx==5
                xlim([0 cutoff_idx + 10]);
            else
                xlim([min(time), max(time)]);
            end
            if ~isempty(panel.ylim)
                ylim(panel.ylim);
            end
            if ~isempty(panel.ylabel)
                ylabel(panel.ylabel);
            end
            xlabel('time (a.u.)');
            %title(panel.title, 'FontSize', titleFontSize, 'Units', 'normalized', 'Position', [0.5, 1.02, 0]);

            % Save as PNG
            print(gcf, [outdir outfile], '-dpng', '-r300');
            close(gcf);

            fprintf('Created plot: %s\n', [outdir outfile]);
        end
    end
end

fprintf('All individual panel plots created successfully!\n');