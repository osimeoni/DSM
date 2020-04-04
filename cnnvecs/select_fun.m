function descfun = select_fun(params)

    if ~params.use_rvec 
            if ~params.use_ms
                    descfun = @(x, y) cnn_vecms (x, y, 1);
            else
                    descfun = @(x, y) cnn_vecms (x, y, [1, 1/sqrt(2), 1/2]);
            end  
    else 
            if ~params.use_ms
                    descfun = @(x, y) cnn_vecrms (x, y, 3, 1);
            else
                    descfun = @(x, y) cnn_vecrms (x, y, 3, [1, 1/sqrt(2), 1/2]);
            end  
    end
end
