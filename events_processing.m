function [temp_e, baseline] = events_processing(data, bwindow, ewindow, ithres, dthres)
%переписываем функцию для обработки событий
%   для начала нужно понять, что подается на вход
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

if nargin < 4 || isempty(ithres)
%         defpar = def_params;
%         ithres = defpar.ithres;
        ithres = intensity_filter(data(:));

end

if nargin < 5 || isempty(dthres)
        defpar = def_params;
        dthres = defpar.dthres;
end

baseline = baseline_search(data, bwindow);

%посчитаем скользящее среднее, чтобы от него взять производную
data_smoothed = smoothdata(data, 2, 'movmean', ewindow);

%поиск событий для матриц
e_mask = data > baseline+ithres; % матрица с событиями
der = diff(data_smoothed, 1, 2); % производная для скольз среднего

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
       if gap < 10
           temp_e = gap_less_ten(temp_e, coors, der, ncell, k, dthres);
       else
           temp_e = gap_greater_ten(temp_e, coors, der, ncell, k, dthres);
       end
    end
end

temp_e = temp_e(:, 2:end-1);
end


function [moving_average] = baseline_search(data, window)
    if nargin < 2
        window = 20 * 4;
    end
    moving_average = smoothdata(data, 2, 'movmean', window);
        for j=1:9
            coordinates = ~(moving_average <  data);
            moving_average(coordinates)=data(coordinates);
            moving_average = smoothdata(moving_average, 2, 'movmean', window);
        end
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
   [temp_e, nl] = begins_marking(temp_e, coors, der, ncell, k);
   for l = coors(k):nl-4 %итерируемся по возрастающей
       if l+4 > length(der(1, :))
            break
       end
       if all(abs(der(ncell,l:l+4)) < dthres) && all(der(ncell, l:l+4) < 0) %если по модулю меньше порога и отриц
           temp_e(ncell, l:l+3) = 1;
           break
       else
           temp_ls = der(ncell, l:l+4);
           condition1 = find(temp_ls > 0);
           if ~isempty(condition1) %условие положительных производных
               if l + condition1(1) - 3 >= l
                   temp_e(ncell, l:l+condition1(1)-3)=1;
               end
               break
           else
               temp_e(ncell, l:l+4) = 1;
           end
       end
   end
end

function [temp_e] = gap_greater_ten(temp_e, coors, der, ncell, k, dthres)
   [temp_e, nl] = begins_marking(temp_e, coors, der, ncell, k);
   for l=coors(k):nl-4 %coors(k+1)%nl-4
        if l+4 > length(der(1, :))
            break;
        end
        %если производная отрицательная и меньше 0.01 по модулю (или другого
        %порога), то завершаем событие и выходим из цикла
        if (all(abs(der(ncell, l:l+4)) < dthres) && all(der(ncell, l:l+4) < 0))
            temp_e(ncell, l:l+3) = 1;
            temp_e(ncell, l+4) = 0; 
            break
        else
            if all(der(ncell, l:l+4) < 0)
                temp_e(ncell, l:l+4) = 1;
            else 
                temp_ls = der(ncell, l:l+4);
                ending = find(temp_ls >= 0);
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
       beg = find(temp_ls > 0);
       if length(beg) <= 3 %заменит условие с isempty
          break
       else
            temp_e(ncell, l-4:l)= 1;
       end
    end
    nl=l;
end