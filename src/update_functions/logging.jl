
"""
    default_log!(
        model::AbstractModel,
        logger,
        step,
        rep;
        _...
    )

Logs the following information on each time step of each simulation repetition:

- `net worth`
- `interest rate`
- `inflation rate`

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `logger`: a logger object
"""
function default_log!(model::AbstractModel, logger, step, rep; _...)
    logger.net_worth[step, rep] = model.state.net_worth
    logger.interest[step, rep] = model.state.interest_rate
    logger.inflation[step, rep] = model.state.inflation_rate
    return nothing
end
