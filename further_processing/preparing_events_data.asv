function [dt] = preparing_events_data(events)
%PREPARING_DATA Summary of this function goes here
%   Detailed explanation goes here
events_numbers = calculate_events_numbers(events);
[mean_events_number, median_events_number] = calculate_duration(events, events_numbers);
%frames_number = size(events, 2)* ones(1, size(events, 1));
frame = size(events, 2);
events_rate = events_numbers/frame;
dt = table(events_numbers.', mean_events_number.', median_events_number.', ...
    events_rate', 'VariableNames', {'events_numbers', 'mean_events_number', ...
    'median_events_number', 'events_rate'});

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
end

function [means, medians] = calculate_duration(events, events_numbers)
    means = zeros(1, size(events, 1)); %по числу клеток
    medians = zeros(1, size(events, 1)); %по числу клеток
    for n=1:size(events, 1) %по клеткам
        events_duration = zeros(1, events_numbers(n)); %массив длиной числа событий
        events_cell = events(n, :); %выборка для одной клетки
        coors = find(events_cell < 1); %находим где ноль
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
end

