tiledlayout('flow')
for t = 1:data.nTrial
    nexttile; hold on;
    title(['trial ' num2str(t)]);
    plot(data.memoryAccumulator(:, t));
    plot(data.visionAccumulator(:, t));
    plot(data.decisionVariable(:,t));
end