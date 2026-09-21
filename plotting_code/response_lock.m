function [locked, valid_trials] = response_lock(timeseries, RT, window)
    % ts: [timesteps x n_trials]
    % RT: [1 x n_trials] or [n_trials x 1]
    % window: number of timesteps before response

    valid = RT > window;
    n_valid = sum(valid);
    locked = zeros(window + 1, n_valid);
    valid_trials = find(valid);

    for i = 1:numel(valid_trials)
        rt = RT(valid_trials(i));
        locked(:, i) = timeseries(rt - window : rt, valid_trials(i));
    end

    % if sum(~valid) > 0
    %     fprintf('Warning: %d trial(s) excluded (RT <= window)\n', sum(~valid));
    % end
end