"""
    grid_search(
        model_type::Type{<:AbstractModel},
        Logger::Type{<:AbstractLogger},
        n_reps,
        all_args;
        threaded::Bool = false,
        show_progress::Bool = false,
        yoked_values = ()
    )

Performs a grid search over vectorized inputs specified in the configuration setup. As an example, consider the following
configuration setup:

```julia 
config = (
    Δt = 1 / 12,
    start_age = 30.,
    duration = 55.0,
    start_amount = 10_000.0,
    # withdraw parameters 
    kw_withdraw = (
        distribution = [
            Normal(3000, 1000), 
            Normal(4000, 1000),
        ],
        start_age = 65,
    ),
    # invest parameters
    kw_invest = (
        distribution = [
            Normal(1000, 100),
            Normal(1500, 100),
        ]
        end_age = 65,
    ),
    # interest parameters
    kw_interest = (
        gbm = GBM(; μ = .07, σ = .05),
    ),
    # inflation parameters
    kw_inflation = (
        gbm = GBM(; μ = .035, σ = .005),
    )
)
```
In the example above, four simulations will be performed: one for each combination of withdraw distribution and investment distribution.

# Arguments

- `model_type::Type{<:AbstractModel}`: an abstract model type for performing Monte Carlo simulations of investment scenarios
- `Logger::Type{<:AbstractLogger}`: a type for collecting variables of the simulation. The constructor signature is
    `Logger(; n_reps, n_steps)`
- `n_reps`: the number of times the investiment simulation is repeated for each input combination. 
- `all_args`: a NamedTuple of configuration settings

# Keywords 

- `threaded::Bool = false`: runs simulations on separate threads if true 
- `show_progress::Bool = false`: shows progress bar if true
- `yoked_values = ()`: fix specified inputs to have the same values, such as: 
    `[Pair((:kw_withdraw, :start_age), (:kw_invest, :end_age))]`

# Output

Returns a vector of tuples where each tuple corresponds to the result of a single simulation condition. Each 
tuple consists of input values and output results. The function `to_dataframe` can be used to transform output 
into a long-form `DataFrame`.

# Notes 

This function was inspired by `parmscan` in Agents.jl.
"""
function grid_search(
    model_type::Type{<:AbstractModel},
    Logger::Type{<:AbstractLogger},
    n_reps,
    all_args;
    threaded::Bool = false,
    show_progress::Bool = false,
    yoked_values = ()
)
    fixed_inputs, config = separate_np_non_np_inputs(model_type; all_args...)
    np_combs = make_nps(config, yoked_values)
    var_parms = get_var_parms(config)

    progress = ProgressMeter.Progress(length(np_combs); enabled = show_progress)
    mapfun = threaded ? ThreadsX.map : map

    all_data = ProgressMeter.progress_map(np_combs; mapfun, progress) do np_combs
        var_vals = map(x -> Pair(x, get_value(np_combs, x)), var_parms)
        model = model_type(; fixed_inputs..., np_combs...)
        times = get_times(model)
        n_steps = length(times)
        logger = Logger(; n_steps, n_reps)
        simulate!(model, logger, n_reps)
        return var_vals, logger
    end
end

function make_np(config, config_keys, index)
    x = map(i -> config[i[1]][i[2]], zip(config_keys, index))
    return NamedTuple{config_keys}(x)
end

function matches(config, match_pairs)
    isempty(match_pairs) ? (return true) : false
    for (k, v) ∈ match_pairs
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
    for (k1, v1) ∈ pairs(config)
        for (k2, v2) ∈ pairs(config[k1])
            if typeof(v2) <: Vector
                push!(output, (k1, k2))
            end
        end
    end
    return output
end

function separate_np_non_np_inputs(
    model_type::Type{<:AbstractModel};
    Δt,
    duration,
    start_age,
    start_amount,
    withdraw! = variable_withdraw,
    invest! = variable_invest,
    update_income! = fixed_income,
    update_inflation! = dynamic_inflation,
    update_interest! = dynamic_interest,
    update_net_worth! = default_net_worth,
    log! = default_log!,
    config...)
    non_np = (;
        Δt,
        duration,
        start_age,
        start_amount,
        withdraw!,
        invest!,
        update_income!,
        update_inflation!,
        update_interest!,
        update_net_worth!,
        log!
    )

    return non_np, NamedTuple(config)
end
