clear;
rootdir = '../data/hachisuka/';

%% main text first - 0.1 noise
files = dir([rootdir 'allData*.mat']);
names = {files.name};
allData = [];
for k = 1:length(files)
    filepath = fullfile(files(k).folder, files(k).name);
    loaded = load(filepath);
    allData = [allData, loaded.allData];  % vertcat struct arrays
end
nFrames = height(allData(1).memoryWeights);

noise_idx = [allData.bitNoise] == 0.105;
plotData = allData(noise_idx);

pre_idx = [plotData.cue] == 0.55;
n = size(plotData(pre_idx), 2);
pre_mean = mean(horzcat(plotData(pre_idx).meanDV), 2, 'omitnan');
post_mean = mean(horzcat(plotData(~pre_idx).meanDV), 2, 'omitnan');

pre_sem = std(horzcat(plotData(pre_idx).meanDV), 0, 2, 'omitnan') ./ sqrt(n);
post_sem = std(horzcat(plotData(~pre_idx).meanDV), 0, 2, 'omitnan') ./ sqrt(n);

%% plot
alphaVal = 0.2;
lineStyle = '-';
lineWidth = 2;
fontSize = 14;
time = 1:nFrames;
time_p = time(:);
orange = [253 105 16]/255;
blue = [31 119 180]/255;

% initialize figure
figConfig.size = [400, 350];   % [width, height] in pixels
fig = figure('Position', [100, 100, 500, 500], 'Visible', 'on', ...
    'Color', 'white', 'InvertHardcopy', 'off');
ax = gca;
hold(ax, 'on')
set(ax, 'Color', 'white', ...
    'Box', 'off', ...
    'LineWidth', 1, ...
    'TickDir', 'out', ...
    'XColor', [0 0 0], ...
    'YColor', [0 0 0], ...
    'FontSize', fontSize, ...
    'FontName', 'Helvetica');
%lgd = legend('Location', 'northwest');

% add grid lines
ax.XGrid = 'on';
ax.YGrid = 'off';
ax.GridColor = [0 0 0];
ax.GridLineWidth = 0.5;
ax.GridLineStyle = '-';
ax.GridAlpha = 1;
ax.Layer = 'top';  % keeps axis lines/ticks on top; grid stays behind data
ax.XTick = 0:25:nFrames;  % grid line every 10 frames

% plot pre
fill(ax, [time_p; flipud(time_p)], [pre_mean + pre_sem; flipud(pre_mean - pre_sem)], ...
    blue, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(ax, time_p, pre_mean, 'Color', blue, 'LineStyle', lineStyle, 'LineWidth', lineWidth, 'DisplayName', 'pre');

% plot post
fill(ax, [time_p; flipud(time_p)], [post_mean + post_sem; flipud(post_mean - post_sem)], ...
    orange, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(ax, time_p, post_mean, 'Color', orange, 'LineStyle', lineStyle, 'LineWidth', lineWidth, 'DisplayName', 'post');

ylim([-0.5, 2.5])
xlim([-15, 150])
yline(0, 'LineStyle', ':', 'LineWidth', 3, 'HandleVisibility', 'off');
xline(0, 'LineStyle', ':', 'LineWidth', 3, 'HandleVisibility', 'off');
ylabel('decision variable (a.u.)')
xlabel('time (a.u.)')

fig.Position(3:4) = figConfig.size;
exportgraphics(fig, '../figures/DISS_hachisuka_all.png', 'Resolution', 300);

%% supplement - average across all noise levels
pre_idx = [allData.cue] == 0.55;
n = size(allData(pre_idx), 2);

pre_mean = mean(horzcat(allData(pre_idx).meanDV), 2, 'omitnan');
post_mean = mean(horzcat(allData(~pre_idx).meanDV), 2, 'omitnan');

pre_sem = std(horzcat(allData(pre_idx).meanDV), 0, 2, 'omitnan') ./ sqrt(n);
post_sem = std(horzcat(allData(~pre_idx).meanDV), 0, 2, 'omitnan') ./ sqrt(n);

% plot
outdir = '../figures/';
alphaVal = 0.2;
lineStyle = '-';
lineWidth = 2;
fontSize = 14;
time = 1:nFrames;
time_p = time(:);
orange = [253 105 16]/255;
blue = [31 119 180]/255;

% initialize figure
figConfig.size = [400, 350];   % [width, height] in pixels
fig = figure('Position', [100, 100, 500, 500], 'Visible', 'on', ...
    'Color', 'white', 'InvertHardcopy', 'off');
ax = gca;
hold(ax, 'on')
set(ax, 'Color', 'white', ...
    'Box', 'off', ...
    'LineWidth', 1, ...
    'TickDir', 'out', ...
    'XColor', [0 0 0], ...
    'YColor', [0 0 0], ...
    'FontSize', fontSize, ...
    'FontName', 'Helvetica');
lgd = legend('Location', 'none');

% add grid lines
ax.XGrid = 'on';
ax.YGrid = 'off';
ax.GridColor = [0 0 0];
ax.GridLineWidth = 0.5;
ax.GridLineStyle = '-';
ax.GridAlpha = 1;
ax.Layer = 'top';  % keeps axis lines/ticks on top; grid stays behind data
ax.XTick = 0:25:nFrames;  % grid line every 10 frames


% plot pre
fill(ax, [time_p; flipud(time_p)], [pre_mean + pre_sem; flipud(pre_mean - pre_sem)], ...
    blue, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(ax, time_p, pre_mean, 'Color', blue, 'LineStyle', lineStyle, 'LineWidth', lineWidth, 'DisplayName', 'pre');

% plot post
fill(ax, [time_p; flipud(time_p)], [post_mean + post_sem; flipud(post_mean - post_sem)], ...
    orange, 'FaceAlpha', alphaVal, 'EdgeColor', 'none', 'HandleVisibility', 'off');
plot(ax, time_p, post_mean, 'Color', orange, 'LineStyle', lineStyle, 'LineWidth', lineWidth, 'DisplayName', 'post');

ylim([-0.5, 2.5])
xlim([-15, 150])
yline(0, 'LineStyle', ':', 'LineWidth', 3, 'HandleVisibility', 'off');
xline(0, 'LineStyle', ':', 'LineWidth', 3, 'HandleVisibility', 'off');
ylabel('decision variable (a.u.)')
xlabel('time (a.u.)')

fig.Position(3:4) = figConfig.size;
exportgraphics(fig, '../figures/hachisuka_all.png', 'Resolution', 300);

