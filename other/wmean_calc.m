function [means, wmeans] = wmean_calc(source_video, roifn)
%Считаем среднее взвешенное и среднее по следам клетки 
[pixh, pixw, ~] = size(source_video);
[marks_array] = marks_to_array(roifn, pixh, pixw);
pixz = size(marks_array, 3);
[coors, weights] = getting_weights(marks_array);
[means, wmeans] = means_calc(source_video, coors, weights, pixz);
end

function marks_array = marks_to_array(roifn, pixh, pixw)
    pixz = size(roifn, 2);
    %marks_array = roifn; 
    marks_array = reshape(roifn, [pixh, pixw, pixz]);
end

function [coors, weights] = getting_weights(marks_array)
    coors = cell(1, size(marks_array, 3));
    weights = cell(1, size(marks_array, 3));
    frame_size = size(marks_array, 1) * size(marks_array, 2);
    for i=1:size(marks_array, 3)
        frame = marks_array(:, :, i);
        coors{1, i} = zeros(1, length(find(frame > 0)));
        k = 1;
        for j=1:frame_size
            if frame(j) ~= 0
                coors{1, i}(k) = j;
                k = k + 1;
            end
        end
        weights{1, i} = double(frame(coors{1, i}));
    end
end

function [means, wmeans] = means_calc(source_video, coors, weights, pixz)
means = cell(1, pixz);
wmeans = cell(1, pixz);
frames_number = size(source_video, 3);
for i=1:frames_number
    frame = double(source_video(:, :, i));
    for k=1:pixz
        m = mean(frame(coors{1, k}));
        wm = sum(weights{1, k} .* frame(coors{1, k}))/sum(weights{1, k});
        means{1, k}(end+1) = m;
        wmeans{1, k}(end+1) = wm;
    end  
end
end