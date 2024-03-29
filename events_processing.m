function [temp_e, baseline, ithres, data_smoothed, der] = events_processing(data, bwindow, ewindow, dthres)
    %   data: по строкам будут клетки, по столбцам интенсивности в
    %   момент времени
    %   bwindow = окно для базовой линии
    %   window_e = окно для расчета событий
    %   baseline - базовая линия для дальнейшего расчета событий
    %   ithres - порог по интенсивности, выше которого будет событие (начальная
    %   разметка с базовой линией)
    %   dthres - порог по производной, ниже которого события нет (для разметки
    %   концов и начал)
    if nargin < 2 || isempty(bwindow)
        defpar = def_params;
        bwindow = defpar.bwindow;
    end

    if nargin < 3 || isempty(ewindow)
        defpar = def_params;
        ewindow = defpar.ewindow;
    end

    if nargin < 4 || isempty(dthres)
        defpar = def_params;
        dthres = defpar.dthres;
    end

%     поиск порога
    baseline = baseline_search(data, bwindow);
    ithres = ithres_search(data, baseline);

    %посчитаем скользящее среднее, чтобы от него взять производную
    data_smoothed = smoothdata(data, 2, 'sgolay', ewindow);

    %поиск событий для матриц
    e_mask = zeros(size(data));
    e_mask = data > baseline+ithres.'; % матрица с событиями
    nulls_der = zeros(size(data_smoothed, 1), 2);
    der = [nulls_der, diff(data_smoothed, 1, 2)]; % производная для скольз среднего

    %отсекаем короткие события
    nulls = zeros(length(e_mask(:, 1)), 1);
    temp_e = [nulls e_mask nulls];
    der_mask = diff(temp_e, 1, 2);
    sz = -6;
    ncells = length(data(:, 1));

    for ncell = 1:ncells
        temp_e = remove_short_events(temp_e, der_mask, ncell, sz);
        coors = [1, find(temp_e(ncell, :) > 0), length(temp_e(ncell, :))]; %массив с координатами событий
        for k = 1:length(coors) - 1
            gap = coors(k+1)-coors(k);
            if gap == 1
                continue
            elseif gap < 10
                temp_e = gap_less_ten(temp_e, coors, der, ncell, k, dthres);
            else
                temp_e = gap_greater_ten(temp_e, coors, der, ncell, k, dthres);
            end
        end
        temp_e(ncell, :) = rmv_boundary_events(temp_e(ncell, :));
    end

    %ithres = ithres(:, 1);
    ithres = ithres.';
    temp_e = temp_e(:, 2:end-1);
    der = der(:, 2:end);
end


function [moving_average] = baseline_search(data, window)
    if nargin < 2
        window = 20 * 4+1;
    end
    if mod(window, 2) == 0
        window = window + 1;
    end
    moving_average = smoothdata(data, 2, 'movmean', window);
    for j=1:9
        coordinates = ~(moving_average <  data);
        moving_average(coordinates)=data(coordinates);
        moving_average = smoothdata(moving_average, 2, 'sgolay', window);
    end
    moving_average = max(0, moving_average);
end

function ithres = ithres_search(data, baseline)
    %ithres = zeros(size(data));
    ithres_matrix = data - baseline;
    ncells = size(baseline, 1);
    means = mean(baseline, 2).';
    min_mean = min(means);
    max_mean = max(means);
    span_mean = max_mean - min_mean;
    n_ints = 50;
    size_ints = span_mean / n_ints;
    spread_mean = min_mean:size_ints:max_mean;
    ithres_1 = zeros(1, ncells);
    ithres_2 = zeros(1, ncells);
    ithres_3 = zeros(1, ncells); %ones(1, ncells);
    spread_intensity = cell(1, n_ints);
    for j = 2:n_ints+1
        if j == n_ints+1
           number_cells = find(means > spread_mean(j-1) & means <= spread_mean(j));
        else
            number_cells = find(means >= spread_mean(j-1) & means < spread_mean(j));
        end
        spread_intensity{1, j-1} = number_cells;
        ithres_1(number_cells) = intensity_filter_v2(ithres_matrix(number_cells, 10:10:size(data, 2)));
    end
    for ncell = 1:size(data, 1)
        ithres_2(ncell) = intensity_filter_v2(ithres_matrix(ncell, 10:10:size(data, 2)));
    end
    ithres = max(ithres_1, ithres_2);
    ithres = max(ithres, ithres_3);
end

function temp_e = remove_short_events(temp_e, der_mask, ncell, sz)
    c_pos = find(der_mask(ncell, :) > 0);
    c_neg = find(der_mask(ncell, :) < 0);
    short_e = find(c_pos-c_neg > sz); %координаты с короткими событиями
    for j=1:length(short_e)
        temp_e(ncell, c_pos(short_e(j))+1:(c_neg(short_e(j)))) = 0;
    end
end

function [temp_e] = gap_less_ten(temp_e, coors, der, ncell, k, dthres)
    %der_b = [0, der];
    der_b = der;
    [temp_e, nl] = begins_marking(temp_e, coors, der_b, ncell, k);
    nl = nl - 2;
    der_e = der(:, 2:end);
    for l = coors(k):nl %итерируемся по возрастающей
        if l+4 > length(der_e(1, :))
            break
        end
        if all(abs(der_e(ncell,l:l+4)) < dthres) && all(der_e(ncell, l:l+4) < 0) %если по модулю меньше порога и отриц
            temp_e(ncell, l:min(l + 3, nl)) = 1;
            break
        else
            temp_ls = der_e(ncell, l:l+4);
            en = find(temp_ls < 0);
            if length(en) > 3
                temp_e(ncell, l:min(l + 4, nl)) = 1;
            else
                ending = find(temp_ls >= -0.001);
                temp_e(ncell, l:min(l + ending(1) - 2, nl)) = 1;
                break
            end
            %           condition1 = find(temp_ls < 0);
            %            if ~isempty(condition1) %условие положительных производных
            %                if l + condition1(1) - 3 >= l
            %                    temp_e(ncell, l:l+condition1(1)-3)=1;
            %                end
            %                break
            %            else
            %                temp_e(ncell, l:l+4) = 1;
            %            end
        end
    end
end

function [temp_e] = gap_greater_ten(temp_e, coors, der, ncell, k, dthres)
    %der_b = [0, der];
    der_b = der;
    [temp_e, nl] = begins_marking(temp_e, coors, der_b, ncell, k);
    der_e = der(:, 2:end);
    %der_l = der;
    for l=coors(k):nl-6 %coors(k+1)%nl-4
        if l+4 > length(der_e(1, :))
            break
        end
        %если производная отрицательная и меньше 0.01 по модулю (или другого
        %порога), то завершаем событие и выходим из цикла
        %if (all(abs(der(ncell, l:l+4)) < dthres) && all(der(ncell, l:l+4) < 0))
        if (all(abs(der_e(ncell, l:l+4)) < dthres) && all(der_e(ncell, l:l+4) < 0))
            temp_e(ncell, l:l+3) = 1;
            temp_e(ncell, l+4) = 0;
            break
        else
            temp_ls = der_e(ncell, l:l+4);
            en = find(temp_ls < 0);
            %if all(der(ncell, l:l+4) < 0)
            if length(en) > 3
                temp_e(ncell, l:l+4) = 1;
            else
                ending = find(temp_ls >= -0.001);
                temp_e(ncell, l:l+ending(1)-2) = 1;
                break
            end
        end
    end
end

function [temp_e, nl] = begins_marking(temp_e, coors, der, ncell, k)
    for l = coors(k+1):-1:coors(k)
        if l > length(der) || (l-4 < 1)
            nl = l;
            break
        end
        temp_ls = der(ncell, l-4:l);
        beg = find(temp_ls > 0.001);
        nl = l - (length(beg) - 1);
        temp_e(ncell, nl:l)= 1;
        if length(beg) <= 3 %заменит условие с isempty
            break
        else
            %temp_e(ncell, l-4:l)= 1;

            %temp_e(ncell, l) = 1;
        end
    end

end

function temp_e = rmv_boundary_events(temp_e)
        event_beg = find(temp_e > 0, 1);
        event_end = find(temp_e > 0, 1, "last");
        if event_beg == 1
            event_beg_2 = find(temp_e == 0, 1);
            temp_e(event_beg:event_beg_2) = 0;
        end
        if event_end == size(temp_e, 2)
            event_end_2 = find(temp_e == 0, 1, "last");
            temp_e(event_end_2:event_end) = 0;
        end
end
