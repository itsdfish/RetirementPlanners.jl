module DataFramesExt

    using DataFrames
    using RetirementPlanners

    import RetirementPlanners: to_dataframe

    """
        to_dataframe(model::AbstractModel, data::Tuple)

    Converts output from `grid_search` to a long-form dataframe. 

    # Arguments

    - `model::AbstractModel`: a subtype of abstract model for performing Monte Carlo simulations of retirement scenarios 
    - `data::Tuple`: data output from `grid_search`
    """
    function to_dataframe(model::AbstractModel, data::Tuple)
        times = get_times(model)
        fields = fieldnames(typeof(data[2]))
        n_fields = length(fields)
        n_steps,n_reps = size(getfield(data[2], fields[1]))
        df = DataFrame(
            time = repeat(times, n_reps),
            rep = repeat(1:n_reps, inner=n_steps)
        )
        for f ∈ fields 
            df[!,f] = getfield(data[2], f)[:]
        end
        for k ∈ data[1]
            col_name = make_unique_name(k[1])
            x = typeof(k[2]) <: Number ? k[2] : Symbol(k[2])
            df[!,col_name] .= x
        end
        return df
    end
    
    function to_dataframe(model, data)
        return mapreduce(x -> to_dataframe(model, x), append!, data)
    end
    
    function make_unique_name(np_keys)
        str = split(String(np_keys[1]), "kw_")[2]
        return Symbol(str * "_" * String(np_keys[2]))
    end
end