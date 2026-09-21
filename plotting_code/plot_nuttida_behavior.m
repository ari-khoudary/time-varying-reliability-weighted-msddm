clear
rootdir = '../data/nuttida/';
outdir  = '../figures/';
pub_plot = true;
fix_axis = 1;
green  = [42 99 26]  ./ 255;
purple = [94 14 146] ./ 255;
colors = {green, purple};  % green = fast, purple = slow
x_vals = 1:3;     % x positions for congruent / neutral / incongruent
x_pad  = 0.6;     % whitespace (in x-units) added before the first point and after the last

%%
for fig = 1:2

    % set up plot
    flicker_types = {'fast', 'slow'};
    figure('Position', [100, 100, 900, 350], 'Visible', 'on', ...
        'Color', 'white', 'InvertHardcopy', 'off');
    tiledlayout(1, 2, 'TileSpacing', 'loose', 'Padding', 'loose');
    ax_rt  = nexttile;
    ax_acc = nexttile;
    for ax = [ax_rt, ax_acc]
        hold(ax, 'on');
        xlim(ax, [x_vals(1) - x_pad, x_vals(end) + x_pad]);
        if ~pub_plot
            fontSize = 12;
            set(ax, 'Color', 'white', 'Box', 'off', 'LineWidth', 1, ...
                'TickDir', 'out', 'XColor', [0 0 0], 'YColor', [0 0 0], ...
                'FontSize', fontSize, 'FontName', 'Helvetica', ...
                'XTick', x_vals, 'XTickLabel', {'expected', 'neutral', 'unexpected'});
        else
            fontSize = 18;
            set(ax, 'Color', 'white', 'Box', 'off', 'LineWidth', 1, ...
                'TickDir', 'out', 'XColor', [0 0 0], 'YColor', [0 0 0], ...
                'FontSize', fontSize, 'FontName', 'Helvetica', ...
                'XTick', [], 'XTickLabel',[]);
        end
    end

    % compute & display
    for f = 1:length(flicker_types)
        flicker = flicker_types{f};
        col     = colors{f};
        suffix  = ['_' flicker 'Flicker.mat'];
        if fig == 1
            neutral_files = dir([rootdir '0.10*0.5cue*thresh*' suffix]);
            biased_files  = dir([rootdir '0.10*0.7cue*thresh*' suffix]);
        else
            neutral_files = dir([rootdir '*0.5cue*thresh*' suffix]);
            biased_files  = dir([rootdir '*0.7cue*thresh*' suffix]);
        end
        n_subs = length(neutral_files);
        sub_rt  = nan(n_subs, 3);  % rows = subjects, cols = [congruent, neutral, incongruent]
        sub_acc = nan(n_subs, 3);
        for i = 1:n_subs
            neutral  = load(fullfile(rootdir, neutral_files(i).name)).data;
            biased   = load(fullfile(rootdir, biased_files(i).name)).data;
            % Handle NaN choices
            neutral.choices(isnan(neutral.choices(:,1)), 1) = 0;
            biased.choices(isnan(biased.choices(:,1)), 1)   = 0;
            % Split biased into congruent / incongruent trials
            con_idx  = logical(biased.congruent);
            incon_idx = ~con_idx;
            % Within-subject RT (converted to seconds) and accuracy
            if strcmp(flicker, 'slow')
                rt_con    = (biased.RT(con_idx)   - 33) ./ 33.33;
                rt_neu    = (neutral.RT            - 33) ./ 33.33;
                rt_incon  = (biased.RT(incon_idx)  - 33) ./ 33.33;
            else
                rt_con    = (biased.RT(con_idx)   - 50) ./ 50;
                rt_neu    = (neutral.RT            - 50) ./ 50;
                rt_incon  = (biased.RT(incon_idx)  - 50) ./ 50;
            end
            sub_rt(i, :)  = [mean(rt_con),                        mean(rt_neu),   mean(rt_incon)];
            sub_acc(i, :) = [mean(biased.choices(con_idx, 1)),    mean(neutral.choices(:,1)),   mean(biased.choices(incon_idx, 1))];
        end
        % Group-level: mean of subject means ± SEM
        rt_means  = mean(sub_rt,  1);
        rt_sems   = std(sub_rt,   0, 1) ./ sqrt(n_subs);
        acc_means = mean(sub_acc, 1);
        acc_sems  = std(sub_acc,  0, 1) ./ sqrt(n_subs);
        errorbar(ax_rt,  x_vals, rt_means,  rt_sems,  '-o', 'LineWidth', 5, 'Color', col);
        errorbar(ax_acc, x_vals, acc_means, acc_sems, '-o', 'LineWidth', 5, 'Color', col);
    end
    if ~pub_plot
        legend(ax_acc, {'Fast Flicker', 'Slow Flicker'}, 'Location', 'northeastoutside');
    end
    if fix_axis
        ylim(ax_acc, [0.5 1]);
        ylim(ax_rt, [0.2 1]);
    end
    if fig == 1
        outfile = 'nuttida_behavior_0.1noise.png';
    else
        outfile = 'nuttida_behavior_all.png';
    end
    exportgraphics(gcf, fullfile(outdir, outfile), 'Resolution', 300);
end