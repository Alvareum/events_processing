function group_dt = process_group_data(group)
%PROCESS_GROUP_DATA Summary of this function goes here
%   Detailed explanation goes here
% group - *53*, *30*, *hyp*, *int*
path = "E:\practice\lab_data\results";
cd(path);
chosen_group = sprintf("*calculus_%s*", group);
data = dir(chosen_group);
mean_events_number = zeros(1, length(data));
median_events_number = zeros(1, length(data));
mean_events_duration = zeros(1, length(data));
median_events_duration = zeros(1, length(data));
mean_events_rate = zeros(1, length(data));
median_events_rate = zeros(1, length(data));
mean_events_amplitude = zeros(1, length(data));
median_events_amplitude = zeros(1, length(data));
working_cells_number = zeros(1, length(data));
working_cells_rate = zeros(1, length(data));
group_list = strings(1, length(data));
group_list(:) = group;
for i = 1:length(data)
    tablename = fullfile(data(i).folder, data(i).name);
    tablename = fullfile(tablename, "dt_video_v5.csv");
    dt = readtable(tablename);
    mean_events_number(i) = mean(dt.events_numbers, 'omitnan');
    median_events_number(i) = median(dt.events_numbers, 'omitnan');
    mean_events_duration(i) = mean(dt.mean_events_number, 'omitnan');
    median_events_duration(i) = median(dt.median_events_number, 'omitnan');
    mean_events_rate(i) = mean(dt.events_rate);
    median_events_rate(i) = median(dt.events_rate);
    mean_events_amplitude(i) = mean(dt.mean_amplitude);
    median_events_amplitude(i) = median(dt.mean_amplitude);
    working_cells_number(i) = dt.working_cells_number(1);
    working_cells_rate(i) = dt.working_cells_rate(1);
end

group_dt = table(group_list.', mean_events_number.', median_events_number.', ...
    mean_events_duration.', median_events_duration.', mean_events_rate.', ...
    median_events_rate.', mean_events_amplitude.', median_events_amplitude.', ...
    working_cells_number.', working_cells_rate.', 'VariableNames', {'group', ...
    'mean_events_number', 'median_events_number', 'mean_events_duration', ...
    'median_events_duration', 'mean_events_rate', 'median_events_rate', ...
    'mean_events_amplitude', 'median_events_amplitude', 'working_cells_number', ...
    'working_cells_rate'});
name_to_save = sprintf('dt_group_%s.csv', group);
%writetable(group_dt, name_to_save);
end

