function simulate!(calc::AbstractCalculator, logger::AbstractLogger, n_reps; kwargs...)
    for rep ∈ 1:n_reps 
        calc.rep = rep
        _simulate!(calc, logger; kwargs...)
    end
    return nothing
end

function _simulate!(calc::AbstractCalculator, logger::AbstractLogger; kwargs...)
    (;Δt,) = calc
    calc.state.net_worth = calc.start_amount
    for (s,t) ∈ enumerate(get_times(calc))
        calc.time_step = s
        update!(calc, logger, t; kwargs...)
    end
    return nothing 
end 

# periodic update within simulation 
function update!(calc::AbstractCalculator, logger::AbstractLogger, t; 
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

get_times(calc::AbstractCalculator) = calc.Δt:calc.Δt:calc.n_years