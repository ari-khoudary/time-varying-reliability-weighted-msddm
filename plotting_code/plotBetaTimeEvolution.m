function h = plotBetaTimeEvolution(timePoints, alphaValues, betaValues, interval, color, targetAxis, options)
    % Creates a time-series plot of beta distributions with time on x-axis
    % Works with existing tiledlayout/nexttile
    % 
    % Parameters:
    % timePoints: vector of all time points
    % alphaValues: vector of alpha parameters at each time point
    % betaValues: vector of beta parameters at each time point
    % interval: interval at which to plot PDFs (default: 1)
    % color: color to use for distributions (default: orange)
    % targetAxis: axes handle to plot on (default: gca)
    % options: struct with additional optional parameters
    %   - xResolution: number of points to use for PDFs (default: 100)
    %   - maxHeight: maximum height for PDF scaling (default: auto)
    %   - width: width scaling for distributions (default: auto)
    %   - refLine: y-value for reference line (default: 0.5)
    %   - title: title for the plot (default: none)
    %
    % Returns:
    % h: handle to the axes containing the plot

    % WRITTEN BY CLAUDE 4 SONNET, WITH SOME MODIFICATIONS BY ARI KHOUDARY
    
    % Set defaults for direct parameters
    if nargin < 4 || isempty(interval)
        interval = 1;
    end
    
    if nargin < 5 || isempty(color)
        color = [0.9, 0.5, 0.2]; % Orange by default
    end
    
    % Add targetAxis as a parameter (6th parameter)
    if nargin < 6 || isempty(targetAxis)
        targetAxis = gca;
    end
    
    % Default options (7th parameter)
    if nargin < 7
        options = struct();
    end
    
    % Set other defaults
    if ~isfield(options, 'xResolution')
        options.xResolution = 100;
    end
    if ~isfield(options, 'refLine')
        options.refLine = 0.5;  % Default reference line position
    end
    
    % Grid for probability values (domain of beta distribution)
    p = linspace(0, 1, options.xResolution);
    
    % Select time points based on interval
    selectedIndices = 1:interval:length(timePoints);
    selectedTimes = timePoints(selectedIndices);
    selectedAlphas = alphaValues(selectedIndices);
    selectedBetas = betaValues(selectedIndices);
    
    % Calculate densities for selected time points
    densities = zeros(length(selectedTimes), length(p));
    for i = 1:length(selectedTimes)
        densities(i,:) = betapdf(p, selectedAlphas(i), selectedBetas(i));
    end
    
    % Determine maximum height for scaling if not provided
    if ~isfield(options, 'maxHeight')
        options.maxHeight = max(densities(:)) * 1.2;  % Add 20% for visual clarity
    end
    
    % Use the specified target axes
    h = targetAxis;
    hold(h, 'on');
    
    % Width of each distribution
    if ~isfield(options, 'width')
        % Auto calculate width based on time point spacing
        if length(selectedTimes) > 1
            options.width = min(diff(selectedTimes)) * 0.8;
        else
            options.width = 1;
        end
    end

    % Create a dummy plot for legend that won't be visible in the actual plot
    h_dummy = plot(targetAxis, NaN, NaN, 'Color', color, 'LineWidth', 2);

    % Add horizontal reference line 
    plot(targetAxis, [min(timePoints), max(timePoints)], [options.refLine, options.refLine], 'LineStyle', '-', 'LineWidth', 1, 'Color', 'black');
    
    % Plot each distribution
    for i = 1:length(selectedTimes)
        time = selectedTimes(i);
        density = densities(i,:);
        
        % Scale density for better visibility
        scaledDensity = density / options.maxHeight * options.width;
        
        % Plot only right side distribution (single color)
        fill(targetAxis, [time, time + scaledDensity, time + scaledDensity, time], ...
             [0, 0, p, p], ...
             color, 'EdgeColor', 'none', 'FaceAlpha', 0.75);
    end
    
    % Format axes - explicitly specify the target axes
    ylabel(targetAxis, 'density');
    if isfield(options, 'title')
        title(targetAxis, options.title);
    end
    xlim(targetAxis, [min(timePoints), max(timePoints) + options.width]);
    ylim(targetAxis, [0, 1]);
    
    hold(targetAxis, 'off');
    
    % Return the dummy handle for legend
    if nargout > 0
        h = h_dummy;
    end
end