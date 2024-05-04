"""
    default_log!(model::AbstractModel, logger, step, rep; _...)

Logs the following information on each time step of each simulation repetition:

- `net worth`
- `interest rate`
- `inflation rate`
- `total_income`

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `logger`: a logger object
"""
function default_log!(model::AbstractModel, logger, step, rep; _...)
    state = model.state
    logger.net_worth[step, rep] = state.net_worth
    logger.interest[step, rep] = state.interest_rate
    logger.inflation[step, rep] = state.inflation_rate
    logger.total_income[step, rep] = state.withdraw_amount + state.income_amount
    return nothing
end
