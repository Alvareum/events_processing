function ithres = intensity_filter_v2(maxall)
    tmp1 = maxall;
    tmp1 = tmp1(tmp1 > 1/2^8); %%% above 0 in terms of single precision %%%
    if length(tmp1) > 1 %~isempty(tmp1)
        tmp1 = sort(tmp1);
        tmp2 = linspace(tmp1(1), 1 * tmp1(end), length(tmp1));
        tmp = tmp1(:) - 0.3 * tmp2(:);
        x = 1: length(tmp);
        sker = 2 * round(length(tmp) / 100) + 1;
        xq = [1 - sker: 0, x, length(tmp) + 1: length(tmp) + sker];
        tmpt = interp1(x, tmp, xq, 'linear', 'extrap');
        tmp0 = smooth(tmpt, sker);
        tmp0 = diff(tmp0);
        tmpg = smooth(tmp0, sker);
        tmpg = tmpg(x);
        tmpg_end = length(tmpg);
        tmpg_beg = idivide(int16(tmpg_end), int16(2));
        idthres = find(tmpg(double(tmpg_beg):end) >= 0, 1);
        ithres = min(prctile(tmp1, 90), tmp1(tmpg_beg+idthres-1));
        if isempty(idthres)
            idthres = find(tmpg(1:tmpg_beg) >= 0, 1, "last");
            ithres = min(prctile(tmp1, 90), tmp1(idthres));
        end
                
    else
        ithres = Inf;
    end
end