%% plots model components over a 2 second range
clear
load('colors.mat')
infiles = {'../data/example_traces/model_components.mat'};
outdir = '../blacklines/';
%outdir = '../figures/mc_singleTrial/';
trials = [7];
outfiles = {''};

% ===== SPECIFY WHICH PANELS TO PLOT =====
% Options: 1=memory_accumulator, 2=memory_belief, 3=memory_precision,
%          4=vision_accumulator, 5=vision_belief, 6=vision_precision,
%          7=all_accumulators, 8=vision_evidence, 9=memory_evidence,
%          10=both_precisions, 11=vision_weights, 12=memory_weights,
%          13=both_weights, 14=both_evidence, 15=both_beliefs

% panels_to_plot = [2:6, 8:9];  % SQUARE
% panels_to_plot = 13; % TALL
% panels_to_plot = [13, 14]; % WIDE

panels_to_plot = [4]; % ELSE

% =========================
plotType = 'wide';
if strcmp(plotType, 'square')
    width = 350;
    height = 350;
elseif strcmp(plotType, 'wide')
    width = 600;
    height = 350;
elseif strcmp(plotType, 'tall')
    width = 350;
    height = 650;
elseif strcmp(plotType,' big')
    width = 800;
    height = 600;
else
    width = 500;
    height = 450;
end
fontSize = 20;

for file = 1:length(infiles)
    panels = struct();
    data = load(fullfile(infiles{file})).data;
    trial = trials(file);
    time = 1:data.nFrames;
    cutoff_idx = length(time);

    panels(1).name = 'memory_accumulator';
    panels(1).title = 'Memory Accumulator';
    panels(1).ylabel = 'accumulated evidence (a.u.)';
    panels(1).ylim = [-5 20];

    panels(2).name = 'memory_belief';
    panels(2).title = 'Memory Belief';
    panels(2).ylabel = 'belief (density)';
    panels(2).ylim = [];

    panels(3).name = 'memory_reliability';
    panels(3).title = 'Memory Reliability';
    panels(3).ylabel = 'reliability (nats)';
    panels(3).ylim = [];

    panels(4).name = 'vision_accumulator';
    panels(4).title = 'Vision Accumulator';
    panels(4).ylabel = 'accumulated evidence (a.u.)';
    panels(4).ylim = [];

    panels(5).name = 'vision_belief';
    panels(5).title = 'Vision Belief';
    panels(5).ylabel = 'belief (density)';
    panels(5).ylim = [];

    panels(6).name = 'vision_reliability';
    panels(6).title = 'Vision Reliability';
    panels(6).ylabel = 'reliability (nats)';
    panels(6).ylim = [];

    panels(7).name = 'all_accumulators';
    panels(7).title = 'x_{t}: dynamic precision-weighted accumulators';
    panels(7).ylabel = 'accumulated evidence (a.u.)';
    panels(7).ylim = [];

    panels(8).name = 'vision_evidence';
    panels(8).title = 'Vision Evidence';
    panels(8).ylabel = 'sample (a.u.)';
    panels(8).ylim = [-3, 3];

    panels(9).name = 'memory_evidence';
    panels(9).title = 'Memory Evidence';
    panels(9).ylabel = 'sample (a.u.)';
    panels(9).ylim = [-3, 3];

    panels(10).name = 'both_reliabilities';
    panels(10).title = '\lambda_{s_{t}}: evidence reliability estimate';
    panels(10).ylabel = 'reliability (bits)';
    panels(10).ylim = [];

    panels(11).name = 'vision_weights';
    panels(11).title = 'Vision Weights';
    panels(11).ylabel = 'evidence weight (a.u.)';
    panels(11).ylim = [];

    panels(12).name = 'memory_weights';
    panels(12).title = 'Memory Weights';
    panels(12).ylabel = 'evidence weight (a.u.)';
    panels(12).ylim = [];

    panels(13).name = 'both_weights';
    panels(13).title = 'w_{s_{t}}: evidence weights';
    panels(13).ylabel = 'evidence weight (a.u.)';
    panels(13).ylim = [];

    panels(14).name = 'both_evidence';
    panels(14).title = 'o_{s_{t}}: momentary evidence';
    panels(14).ylabel = 'sample (a.u.)';
    panels(14).ylim = [-3, 3];

    panels(15).name = 'both_beliefs';
    panels(15).title =  'g_{s}(t): belief about signal strength';
    panels(15).xlabel = 'time (s)';
    panels(15).ylabel = 'probability density';
    panels(15).ylim = [];

    panels(16).name = 'mem_and_vis_accumulators';
    panels(16).title = '';
    panels(16).ylabel = 'accumulated evidence (a.u.)';
    panels(16).ylim = [-5 20];

    % thin out memory evidence for plotting
    memEvidence = NaN(data.nFrames, 1);
    memEvidence(mod(1:data.nFrames, data.memoryThinning)==1) = ...
        data.memoryEvidence(mod(1:data.nFrames, data.memoryThinning)==1, trial);

    % Clean vision evidence data once
    data.visionEvidence(data.visionEvidence == 0) = NaN;


    %% plot

    % get counters for time-varying betas
    memoryAlphas = data.counters(:, 1, trial);
    memoryBetas = data.counters(:, 2, trial);
    visionAlphas = data.counters(:, 3, trial);
    visionBetas = data.counters(:, 4, trial);

    % Create static plots for each panel
    for panel_idx = panels_to_plot  % Only loop through selected panels
        panel = panels(panel_idx);
        outfile = [panel.name outfiles{file} '.png'];

        % Create figure for this panel
        figure('Position', [100, 100, width, height], 'Visible', 'off', ...
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

        % Panel-specific plotting (complete timeseries)
        switch panel_idx
            case 1 % Memory accumulator
                yline(0, 'LineStyle', ':');
                plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);

            case 2 % Memory belief
                %mem_opt.refLine = data.cue;
                %yline(0, 'LineStyle', ':');
                plotBetaTimeEvolution(time, memoryAlphas(1:cutoff_idx), memoryBetas(1:cutoff_idx), data.memoryThinning, blue, ax);

            case 3 % Memory precision
                plot(time, data.memoryPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);

            case 4 % Vision accumulator
                yline(0, 'LineStyle', ':');
                plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);

            case 5 % Vision belief
                %viz_opt.refLine = data.trueCoherence;
                % yline(0, 'LineStyle', ':');
                plotBetaTimeEvolution(time, visionAlphas(1:cutoff_idx), visionBetas(1:cutoff_idx), data.memoryThinning, yellow, ax);

            case 6 % Vision precision
                plot(time, data.visionPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);

            case 7 % all accumulators
                yline(0, 'LineStyle', ':');
                h1 = plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);
                h2 = plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);
                h3 = plot(time, data.decisionVariable(1:cutoff_idx, trial), '-', 'LineWidth', 4, 'Color', green);
                xline(480);
                %legend([h1 h2 h3], {'memory', 'vision', 'DV'}, 'Location', 'best');

            case 8 % vision evidence
                yline(0, 'LineStyle', ':');
                vizEvid = data.visionEvidence(1:cutoff_idx, trial);
                plot(time, vizEvid, '.-', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', yellow);

            case 9 % memory evidence
                yline(0, 'LineStyle', ':');
                validIdx = ~isnan(memEvidence);
                validIdx = validIdx(1:cutoff_idx);
                plot(time(validIdx), memEvidence(validIdx), '.-', 'MarkerSize', 30, 'LineWidth', 0.5, 'Color', blue);

            case 10 % both precisions
                plot(time, data.memoryPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);
                plot(time, data.visionPrecisions(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);
                % legend({'Memory', 'Vision'}, 'Location', 'best');

            case 11 % vision weights
                plot(time, data.visionDrifts(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);

            case 12 % memory weights
                plot(time, data.memoryDrifts(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);

            case 13 % both weights
                plot(time, data.memoryDrifts(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);
                plot(time, data.visionDrifts(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);
                %legend({'Memory', 'Vision'}, 'Location', 'best');

            case 14 % both evidence streams
                vizEvid = data.visionEvidence(1:cutoff_idx, trial);
                validIdx = ~isnan(vizEvid);
                vizEvid(~validIdx) = 0;
                if file == 2
                    vizEvid(1:480) = 0;
                end
                yline(0, 'LineStyle', ':', 'HandleVisibility', 'off');
                h1 = plot(time, vizEvid, '.-', 'MarkerSize', 15, 'LineWidth', 0.5, 'Color', yellow);
                validIdx = ~isnan(memEvidence);
                validIdx = validIdx(1:cutoff_idx);
                plot(time(validIdx), memEvidence(validIdx), '.-', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', blue);
                h2 = plot(time(validIdx), memEvidence(validIdx), '.-', 'MarkerSize', 20, 'LineWidth', 0.5, 'Color', blue);
                % legend([h2 h1], {'memory', 'vision'}, 'Location', 'best');

            case 15 % both beliefs
                plotBetaTimeEvolution(time, memoryAlphas, memoryBetas, data.memoryThinning, blue, ax);
                plotBetaTimeEvolution(time, visionAlphas, visionBetas, data.memoryThinning, yellow, ax);
                %yline(0, 'LineStyle', ':', 'HandleVisibility', 'off');

            case 16 % mem & vis accumulators for layering plots
                yline(0, 'LineStyle', ':');
                plot(time, data.memoryAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', blue);
                plot(time, data.visionAccumulator(1:cutoff_idx, trial), '-', 'LineWidth', 3, 'Color', yellow);

        end

        % Common axis properties
        xlim([min(time), max(time)]);
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

fprintf('All individual panel plots created successfully!\n');