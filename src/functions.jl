function simulate!(calc::Calculator, logger_type, n_reps; kwargs...)
    logs = logger_type[]
    for _ ∈ 1:n_reps 
        logger = logger_type() 
        _simulate!(calc, logger; kwargs...)
        push!(logs, logger)
    end
    return logs
end

function _simulate!(calc::Calculator, logger; kwargs...)
    (;Δt,) = calc
    calc.state.net_worth = calc.start_amount
    for t ∈ Δt:Δt:calc.n_years
        update!(calc, logger, t; kwargs...)
    end
    return nothing 
end 

# periodic update within simulation 
function update!(calc::AbstractCalculator, logger, t; kwargs...)
    withdraw!(calc, t; kwargs...)
    invest!(calc, t; kwargs...) 
    update_inflation!(calc, t; kwargs...) 
    update_interest!(calc, t; kwargs...) 
    update_net_worth!(calc, t; kwargs...)
    log!(calc, logger; kwargs...)
    return nothing 
end 

function update_interest! end

function withdraw! end

function invest! end

function update_inflation! end

function update_net_worth! end

function log! end