function prep_gpus(params, net)

    numGpus = numel(params.use_gpu);
    if numGpus, fprintf('>> Prepring GPU(s)...\n'); end
    if numGpus > 1
            % check parallel pool integrity as it could have timed out
            pool = gcp('nocreate');
            if ~isempty(pool) && pool.NumWorkers ~= numGpus
                    delete(pool);
            end
            pool = gcp('nocreate');
            if isempty(pool)
                    parpool('local', numGpus);
            end
    end
    if numGpus >= 1
        if numGpus == 1
            gpuinfo = gpuDevice(params.use_gpu);
            net.move('gpu');
            fprintf('>>>> Running on GPU %s with Index %d\n', gpuinfo.Name, gpuinfo.Index);  
        else
            spmd
                gpuinfo = gpuDevice(params.use_gpu(labindex));
                fprintf('>>>> Running on GPU %s with Index %d\n', gpuinfo.Name, gpuinfo.Index);  
            end
        end
    end
end
