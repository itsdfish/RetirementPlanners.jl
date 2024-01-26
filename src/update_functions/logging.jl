
"""
    default_log!(model::AbstractModel, logger, step, rep; _...)

Logs the following information on each time step of each simulation repetition:

- `net worth`
- `interest rate`
- `inflation rate`

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `logger`: a logger object
"""
function default_log!(model::AbstractModel, df, step, rep; _...)
    vals = get_values(model.state)
    n = length(vals)
    df[model.step_count,1:n] = vals
    return nothing
end

function get_values(state::AbstractState)
    fields = fieldnames(typeof(state))
    return map(f -> getfield(state, f), fields)
end