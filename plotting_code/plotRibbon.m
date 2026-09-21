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