module DataFramesExt

    using DataFrames
    using Distributed: pmap
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
        kwargs...,
        )

        if include_constants
            output_params = collect(keys(config))
        else
            output_params = [k for (k, v) in config if typeof(v) <: Vector]
        end

        _config = map(d -> permute(d), config)
        config_keys = keys(_config)
        ranges = map(k -> 1:length(_config[k]), config_keys)
        indices = Iterators.product(ranges...)
        progress = ProgressMeter.Progress(length(indices); enabled = showprogress)
        mapfun = parallel ? pmap : map
        all_data = ProgressMeter.progress_map(indices; mapfun, progress) do indices
            x = map(i -> _config[i[1]][i[2]], zip(config_keys, indices))
            np = NamedTuple{config_keys}(x)
            println(np)
            println("")

            run_single(model, Logger, n_reps; config=np)
        end

        # df_agent = DataFrame()
        # df_model = DataFrame()
        # for (df1, df2) in all_data
        #     append!(df_agent, df1)
        #     append!(df_model, df2)
        # end

        # return df_agent, df_model
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