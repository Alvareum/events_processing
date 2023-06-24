function [dt] = preparing_events_data(events, sigfn, baseline)
%PREPARING_DATA Summary of this function goes here
%   Detailed explanation goes here
events_numbers = calculate_events_numbers(events);
working_cells = length(events_numbers(events_numbers > 0))/size(events, 1);
[mean_events_number, median_events_number] = calculate_duration(events, events_numbers);
%frames_number = size(events, 2)* ones(1, size(events, 1));
[mean_ampl, median_ampl] = amplitude_calc(events, sigfn, baseline, events_numbers);
nframes = size(events, 2);
num_cell = find(events_numbers > 0);
events_numbers = events_numbers(events_numbers > 0);
events_rate = events_numbers/nframes;
cells_rate = zeros(1, length(mean_events_number));
ncells = zeros(1, length(mean_events_number));
cells_rate(:) = working_cells;
ncells(:) = length(events_numbers(events_numbers > 0));

dt = table(num_cell.', events_numbers.', mean_events_number.', median_events_number.', ...
    events_rate', mean_ampl.', median_ampl.', ncells.', cells_rate.', 'VariableNames', ...
    {'cell_number', 'events_numbers', 'mean_events_number', 'median_events_number', ...
    'events_rate', 'mean_amplitude', 'median_amplitude', ...
    'working_cells_number', 'working_cells_rate'});

end

function events_numbers = calculate_events_numbers(events)
    events_numbers = zeros(1, size(events, 1));
    for n=1:size(events, 1)
        events_cell = events(n, :);
        events_number = 0;
        for i=2:size(events, 2)
            if events_cell(i) == 1
                continue
            elseif events_cell(i) == 0 && events_cell(i-1) == 1
                events_number = events_number + 1;
            else
                continue
            end
        end
        events_numbers(n) = events_number;
    end
    %events_numbers = events_numbers(events_numbers > 0);
end

function [means, medians] = calculate_duration(events, events_numbers)
    means = zeros(1, size(events, 1)); %по числу клеток
    medians = zeros(1, size(events, 1)); %по числу клеток
    for n=1:size(events, 1) %по клеткам
        events_duration = zeros(1, events_numbers(n)); %массив длиной числа событий
        events_cell = events(n, :); %выборка для одной клетки
        coors = find(events_cell < 1); %находим где ноль
        if events_numbers(n) == 1
            means(n) = sum(events_cell);
            medians(n) = sum(events_cell);
            continue
        end
        j = 1;
        for i = 2:length(coors) %по длине массива с нулями
            gap = coors(i)-coors(i-1);
            if gap > 1
                events_duration(j) = gap;
                j = j + 1;
            else
                continue
            end
        end
        means(n) = mean(events_duration);
        medians(n) = median(events_duration);
    end
    means = means(means > 0);
    medians = medians(medians > 0);
end

function [mean_ampl, median_ampl] = amplitude_calc(events, sigfn, baseline, events_numbers)
    mean_ampl = [];%zeros(1, size(sigfn, 1));
    median_ampl = [];%zeros(1, size(sigfn, 1));

    for ncell = 1:size(sigfn, 1)
        events_sig = sigfn(ncell, :);
        no_events = find((~events(ncell, :)));
        events_sig(no_events) = 0;
        amplitude = zeros(1, events_numbers(ncell));
        event_number = 1;
        if events_numbers(ncell) == 1
            [max_events, idx] = max(events_sig);
            min_events = baseline(ncell, idx);
            mean_ampl(1, end+1) = max_events - min_events;
            median_ampl(1, end+1) = max_events - min_events;
            continue
        end
        for j = 2:length(no_events)
            if no_events(j)-no_events(j-1) == 1
                continue
            else
                beg = no_events(j-1) + 1;
                ending = no_events(j) - 1;
                %min_events = min(events_sig(beg:ending));
                [max_events, idx] = max(events_sig(beg:ending));
                baseline_part = baseline(ncell, beg:ending);
                min_events = baseline_part(idx);
                amplitude(event_number) = max_events - min_events;
                event_number = event_number + 1;
            end
        end
        if event_number ~= 1
            mean_ampl(1, end+1) = mean(amplitude(amplitude > 0));
            median_ampl(1, end+1) = median(amplitude(amplitude > 0));
        end
    end
end