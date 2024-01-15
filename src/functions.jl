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
function update!(calc::AbstractCalculator, logger, t; 
        kw_withdraw=(), kw_invest=(), kw_inflation=(), 
        kw_interest=(), kw_net_worth=(), kw_log=())
    calc.withdraw!(calc, t; kw_withdraw...)
    calc.invest!(calc, t; kw_invest...) 
    calc.update_inflation!(calc, t; kw_inflation...) 
    calc.update_interest!(calc, t; kw_interest...) 
    calc.update_net_worth!(calc, t; kw_net_worth...)
    calc.log!(calc, logger; kw_log...)
    return nothing 
end 