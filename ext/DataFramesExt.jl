module DataFramesExt

    using DataFrames
    using ThreadsX
    using ProgressMeter
    using NamedTupleTools
    using RetirementPlanners

    import RetirementPlanners: grid_search

    """
        grid_search(
            config::NamedTuple,
            include_constants::Bool = false,
            parallel::Bool = false,
            n = 1,
            showprogress::Bool = false,
            kwargs...,
        )

    # Arguments 
    """
    function grid_search(
        model::AbstractModel,
        Logger::Type{<:AbstractLogger},
        n_reps; 
        config::NamedTuple,
        include_constants::Bool = false,
        parallel::Bool = false,
        n = 1,
        showprogress::Bool = false,
        yoked_values = (),
        kwargs...,
        )

        np_combs = make_nps(config, yoked_values)    
        var_parms = get_var_parms(config)
        times = get_times(model)
        n_steps = length(times)


        progress = ProgressMeter.Progress(length(np_combs); enabled = showprogress)
        mapfun = parallel ? ThreadsX.map : map
        all_data = ProgressMeter.progress_map(np_combs; mapfun, progress) do np_combs
            var_vals = map(x -> Pair(x, get_value(np_combs, x)), var_parms)
            
            logger = Logger(;n_steps, n_reps)
            simulate!(model, logger, n_reps; np_combs...);
            return var_vals, logger
        end
    end

    function make_np(config, config_keys, index)
        x = map(i -> config[i[1]][i[2]], zip(config_keys, index))
        return NamedTuple{config_keys}(x)
    end

    function matches(config, match_pairs)
        isempty(match_pairs) ? (return true) : false
        for (k,v) ∈ match_pairs 
            if get_value(config, k) == get_value(config, v)
                return true
            end
        end
        return false 
    end

    function get_value(config, k) 
        return config[k[1]][k[2]]
    end

    function make_nps(config, dependent_values)
        _config = map(d -> permute(d), config)
        config_keys = keys(_config)
        ranges = map(k -> 1:length(_config[k]), config_keys)
        indices = Iterators.product(ranges...) |> collect
        nps = map(index -> make_np(_config, config_keys, index), indices[:])
        filter!(x -> matches(x, dependent_values), nps)
        return nps 
    end

    # This function is taken from DrWatson:
    function permute(c::NamedTuple)
        iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
        non_iterables = setdiff(keys(c), iterable_fields)

        iterable_np = NamedTuple{(iterable_fields...,)}(getindex.(Ref(c), iterable_fields))
        non_iterable_np = NamedTuple{(non_iterables...,)}(getindex.(Ref(c), non_iterables))

        vec(map(Iterators.product(values(iterable_np)...)) do vals
            dd = NamedTuple{keys(iterable_np)}(vals)
            if isempty(non_iterable_np)
                dd
            elseif isempty(iterable_np)
                non_iterable_np
            else
                merge(non_iterable_np, dd)
            end
        end)
    end

    function get_var_parms(config)
        output = Vector{Tuple{Symbol, Symbol}}()
        for (k1,v1) ∈ pairs(config)
            for (k2,v2) ∈ pairs(config[k1])
                if typeof(v2) <: Vector
                    push!(output, (k1,k2))
                end
            end
        end
        return output
    end

    function run_single(
        model::AbstractModel, 
        Logger::Type{<:AbstractLogger},
        n_reps;
        config, 
        )

        times = get_times(model)
        n_steps = length(times)
        logger = Logger(;n_steps, n_reps)
        simulate!(model, logger, n_reps; config...);

        df = DataFrame(logger)
        df.times = times

        # df_agent_single, df_model_single = run!(model, n; kwargs...)
        # output_params_dict = filter(j -> first(j) in output_params, param_dict)
        # insertcols!(df_agent_single, output_params_dict...)
        # insertcols!(df_model_single, output_params_dict...)
        # return (df_agent_single, df_model_single)
    end

    # config = (
    #     dict1 = (
    #         a = [1,2],
    #         b = [3,4]
    #     ),

    #     dict2 = (
    #         c = [mean,std],
    #         d = [77]
    #     )
    # )

    # _config = map(d -> np_list(d), config)
    # config_keys = keys(_config)
    # ranges = map(k -> 1:length(_config[k]), config_keys)
    # iters = Iterators.product(ranges...)

    # for i ∈ iters
    #     x = map(i -> _config[i[1]][i[2]], zip(config_keys, i))
    #     np = NamedTuple{config_keys}(x)
    #     println(np)
    # end
end