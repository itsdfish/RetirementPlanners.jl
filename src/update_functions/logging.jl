"""
    default_log!(model::AbstractModel, logger, rep, t; _...)

Logs the following information on each time step of each simulation repetition:

- `net worth`
- `interest rate`
- `inflation rate`
- `total_income`

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `logger`: a logger object
- `rep`: indexes the repetition of the simulation
- `t`: current time in years 

# Keywords

- `_...`: optional keyword arguments which are not used 
"""
function default_log!(model::AbstractModel, logger, rep, t; _...)
    state = model.state
    idx = state.log_idx
    log_times = model.log_times
    (idx ≤ length(log_times)) && (t ≈ model.log_times[idx]) ? nothing : (return nothing)
    logger.net_worth[idx, rep] = state.net_worth
    logger.interest[idx, rep] = state.interest_rate
    logger.inflation[idx, rep] = state.inflation_rate
    logger.total_income[idx, rep] = state.withdraw_amount + state.income_amount
    state.log_idx += 1
    return nothing
end
