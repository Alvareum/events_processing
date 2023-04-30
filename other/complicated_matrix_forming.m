function complicated_matrix_forming(source_video, roifn, wmeans, sigfn)
% сделать сложные матрицы по следующему тз:
% в каждой клетке матрицы будет число пикселей для следа клетки
    ncells = size(roifn, 2);
    roifn_1 = reshape(roifn, [512, 512, 490]);
    a = size(source_video, 1) * size(source_video, 2);
    b = size(source_video, 3);
    source_video_reshaped = reshape(source_video, [a, b]);
    foldername = "intensity_matrix_v4";
    mkdir(foldername);
    for ncell=1:ncells
%         if sum(roifn_1(:, :, ncell), 'all') == 0
%             continue
%         end
        pixels = find(roifn_1(:, :, ncell));
        pixels_intensity = source_video_reshaped(pixels, :);
        max_intensity = max(pixels_intensity, [], "all");
        min_intensity = min(pixels_intensity, [], "all");
        bin_size = (max_intensity - min_intensity)/100;
        bin_period = min_intensity:bin_size:max_intensity;
        [counts, centers] = hist(double(pixels_intensity), 500);
        figname = sprintf("cell_%d_intensity_matrix", ncell);
        filename = figname + ".mat";
        path_to_save_1 = fullfile(foldername, figname);
        path_to_save_2 = fullfile(foldername, filename);
        f = figure(1);
        imagesc(counts(:, 1:300));
        ax = gca;
        ax.YDir = 'normal';
        colormap(gca, 'jet');
        f.Units = 'inches';
        f.OuterPosition = [0.25 0.25 16 6];
        print(gcf, path_to_save_1, '-dpng');
        clf
        save(path_to_save_2,"counts", "bin_period", "centers");
        ks_array = zeros(length(centers), size(pixels_intensity, 2));
        for i=1:size(pixels_intensity, 2)
            x = ksdensity(double(pixels_intensity(:, i)), centers);
            ks_array(:, i) = x;    
        end
        %ks_array_max = max(ks_array, [], 'all');
        ks_array_max_col = max(ks_array, [], 1);
        ks_array_normalised = ks_array ./ ks_array_max_col;
        figname = sprintf("cell_%d_ks_array", ncell);
        filename = figname + ".mat";
        path_to_save_1 = fullfile(foldername, figname);
        path_to_save_2 = fullfile(foldername, filename);
        f = figure(6);
        tiledlayout(2,1)
        nexttile
        imagesc(1:300, centers(:, 1), ks_array_normalised(:, 1:300));
        ax = gca;
        ax.YDir = 'normal';
        colormap(gca, 'jet');
        f.Units = 'inches';
        f.OuterPosition = [0.25 0.25 16 10];
        nexttile
        yyaxis left
        plot(wmeans{1, ncell}, DisplayName = "wmean");
        x = 1:600;
        xq = 0.5:0.5:600;
        interpolated_signal = interp1(x, sigfn(ncell, :), xq);
        hold on
        yyaxis right
        plot(1:1200, interpolated_signal, DisplayName = "sigfn");
        xlim([0, 300]);
        legend();
        hold off;
        print(gcf, path_to_save_1, '-r300', '-dpng');
        clf;
        save(path_to_save_2,"ks_array", 'ks_array_normalised');
    end


end

