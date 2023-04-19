project_path = "C:\Users\foxy3\OneDrive\Документы\MATLAB\min1pipe_data";
cd(project_path) ;
data = dir('*calculus*');

for video=1:length(data)
    path = fullfile(data(video).folder, data(video).name);
    videoname = "source_video_data_processed";
    file_path = fullfile(path, videoname);
    load(file_path, 'sigfn');
    video_duration = size(sigfn, 2);
    %sigfn_interp = interp1(1:video_duration, sigfn.', 0.05:0.05:video_duration, "next").';
    [events, baseline, ithres, data_smoothed, der] = events_processing(sigfn, 20, 5);
    results = struct('events',events, 'baseline', baseline, 'ithres', ...
        ithres, 'data_smoothed', data_smoothed, 'der', der, 'neurodata', sigfn);
    dt = preparing_events_data(results.events);
    cd(path)
    save('results_video.mat', "results");
    writetable(dt, 'dt_video.csv');
end

groups = ["30", "53", "hyp", "int"];
group_dt = table();
for i=1:length(groups)
    dt = process_group_data(groups(i));
    group_dt = cat(1, group_dt, dt);
end

cd(project_path);
writetable(group_dt, "group_dt.csv");
