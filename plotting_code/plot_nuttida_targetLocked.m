clear
rootdir = '../data/nuttida/';
outdir  = '../figures/';
flicker_type = {'fast', 'slow', 'both'}; % options: 'fast', 'slow', 'both'

for fig = 2

    for m = 1:length(flicker_type)

        flicker_mode = flicker_type{m};
        switch flicker_mode
            case 'fast'
                flicker_types = {'fast'};
            case 'slow'
                flicker_types = {'slow'};
            case 'both'
                flicker_types = {'fast', 'slow'};
        end
        n_flicker = length(flicker_types);

        if fig == 1
            tmp_files = dir([rootdir '0.10*0.5cue*_fastFlicker.mat']);
        else
            tmp_files = dir([rootdir '*0.5cue*_fastFlicker.mat']);
        end
        n_subs    = length(tmp_files);

        cong_by_flicker  = cell(n_flicker, 1);
        incon_by_flicker = cell(n_flicker, 1);
        neut_by_flicker  = cell(n_flicker, 1);

        for f = 1:n_flicker
            suffix = ['_' flicker_types{f} 'Flicker.mat'];

            if fig == 1
                neutral_files = dir([rootdir '0.10*0.5cue*coh*' suffix]);
                biased_files  = dir([rootdir '0.10*0.7cue*coh*' suffix]);
            else
                neutral_files = dir([rootdir '*0.5cue*coh*' suffix]);
                biased_files  = dir([rootdir '*0.7cue*coh*' suffix]);
            end

            tmp      = load(fullfile(rootdir, neutral_files(1).name)).data;
            n_frames = tmp.nFrames;

            sub_cong_drift  = nan(n_frames, n_subs);
            sub_incon_drift = nan(n_frames, n_subs);
            sub_neut_drift  = nan(n_frames, n_subs);

            for i = 1:n_subs
                neutral = load(fullfile(rootdir, neutral_files(i).name)).data;
                biased  = load(fullfile(rootdir, biased_files(i).name)).data;

                con_idx   = logical(biased.congruent);
                incon_idx = ~con_idx;

                con_drift   = biased.memoryDrifts(:, con_idx);
                incon_drift = biased.memoryDrifts(:, incon_idx);
                neut_drift  = neutral.memoryDrifts;

                con_rt   = biased.RT(con_idx);
                incon_rt = biased.RT(incon_idx);
                neut_rt  = neutral.RT;

                n_con   = size(con_drift,   2);
                n_incon = size(incon_drift, 2);
                n_neut  = size(neut_drift,  2);

                con_mask   = (1:n_frames)' > reshape(con_rt,   1, n_con);
                incon_mask = (1:n_frames)' > reshape(incon_rt, 1, n_incon);
                neut_mask  = (1:n_frames)' > reshape(neut_rt,  1, n_neut);

                con_drift(con_mask)     = NaN;
                incon_drift(incon_mask) = NaN;
                neut_drift(neut_mask)   = NaN;

                sub_cong_drift(:, i)  = mean(con_drift,   2, 'omitnan');
                sub_incon_drift(:, i) = mean(incon_drift, 2, 'omitnan');
                sub_neut_drift(:, i)  = mean(neut_drift,  2, 'omitnan');
            end

            cong_by_flicker{f}  = sub_cong_drift;
            incon_by_flicker{f} = sub_incon_drift;
            neut_by_flicker{f}  = sub_neut_drift;
        end

        % interpolate to common grid and average across flicker types within subject
        n_common = 100;
        common_t = linspace(0, 1, n_common)';

        sub_cong_drift  = nan(n_common, n_subs);
        sub_incon_drift = nan(n_common, n_subs);
        sub_neut_drift  = nan(n_common, n_subs);

        for i = 1:n_subs
            cong_interp  = nan(n_common, n_flicker);
            incon_interp = nan(n_common, n_flicker);
            neut_interp  = nan(n_common, n_flicker);

            for f = 1:n_flicker
                n_f = size(cong_by_flicker{f}, 1);
                t_f = linspace(0, 1, n_f)';
                cong_interp(:, f)  = interp1(t_f, cong_by_flicker{f}(:, i),  common_t, 'linear');
                incon_interp(:, f) = interp1(t_f, incon_by_flicker{f}(:, i), common_t, 'linear');
                neut_interp(:, f)  = interp1(t_f, neut_by_flicker{f}(:, i),  common_t, 'linear');
            end

            sub_cong_drift(:, i)  = mean(cong_interp,  2, 'omitnan');
            sub_incon_drift(:, i) = mean(incon_interp, 2, 'omitnan');
            sub_neut_drift(:, i)  = mean(neut_interp,  2, 'omitnan');
        end

        cong_mean  = mean(sub_cong_drift,  2, 'omitnan');
        cong_sem   = std(sub_cong_drift,   0, 2, 'omitnan') ./ sqrt(n_subs);
        incon_mean = mean(sub_incon_drift, 2, 'omitnan');
        incon_sem  = std(sub_incon_drift,  0, 2, 'omitnan') ./ sqrt(n_subs);
        neut_mean  = mean(sub_neut_drift,  2, 'omitnan');
        neut_sem   = std(sub_neut_drift,   0, 2, 'omitnan') ./ sqrt(n_subs);

        %% prep for plotting

        if strcmp(flicker_mode, 'both')
            % already computed on common_t grid above
            time = (1:n_common)';
        else
            % use raw frame indices from the single flicker type
            f = 1;
            sub_cong_drift  = cong_by_flicker{f};
            sub_incon_drift = incon_by_flicker{f};
            sub_neut_drift  = neut_by_flicker{f};

            n_raw = size(sub_cong_drift, 1);
            time  = (1:n_raw)';

            cong_mean  = mean(sub_cong_drift,  2, 'omitnan');
            cong_sem   = std(sub_cong_drift,   0, 2, 'omitnan') ./ sqrt(n_subs);
            incon_mean = mean(sub_incon_drift, 2, 'omitnan');
            incon_sem  = std(sub_incon_drift,  0, 2, 'omitnan') ./ sqrt(n_subs);
            neut_mean  = mean(sub_neut_drift,  2, 'omitnan');
            neut_sem   = std(sub_neut_drift,   0, 2, 'omitnan') ./ sqrt(n_subs);
        end

        %% plot
        blue = [79 135 210] ./ 255;
        red  = [196 76 70]  ./ 255;
        gray = [99 99 99]   ./ 255;

        alphaVal  = 0.2;
        lineWidth = 5;
        fontSize  = 18;
        figWidth = 600;
        figHeight = 450;

        figure('Position', [100, 100, figWidth, figHeight], 'Visible', 'on', ...
            'Color', 'white', 'InvertHardcopy', 'off');
        ax = gca;
        hold(ax, 'on');
        set(ax, 'Color', 'white', 'Box', 'off', 'LineWidth', 1, ...
            'TickDir', 'out', 'XColor', [0 0 0], 'YColor', [0 0 0], ...
            'FontSize', fontSize, 'FontName', 'Helvetica');

        conditions = {cong_mean,  cong_sem,  blue; ...
            incon_mean, incon_sem, red;  ...
            neut_mean,  neut_sem,  gray};

        for c = 1:3
            mn  = conditions{c, 1};
            sem = conditions{c, 2};
            col = conditions{c, 3};

            fill([time; flipud(time)], [mn+sem; flipud(mn-sem)], ...
                col, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
            plot(time, mn, 'Color', col, 'LineWidth', lineWidth);
        end

        legend({'expected', 'unexpected', 'neutral'}, 'Location', 'northwest');
        %ylabel('weight on memory (a.u.)');
        %xlabel('time (normalized)');
        ylim([0.45 0.7])

        switch flicker_mode
            case 'fast'
                subtitle('fast flicker only');
                filename = 'nuttida_weights_fast';
            case 'slow'
                subtitle('slow flicker only');
                filename = 'nuttida_weights_slow';
            case 'both'
                subtitle('fast & slow flicker');
                filename = 'nuttida_weights_both';
        end

        if fig == 1
            exportgraphics(gcf, fullfile(outdir, [filename '_0.1noise.png']), 'Resolution', 300);
        else
            exportgraphics(gcf, fullfile(outdir, [filename '_all.png']), 'Resolution', 300);
        end
    end
end