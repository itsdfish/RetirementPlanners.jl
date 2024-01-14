# run one simulation
function simulate!(calc::Calculator, logger; kwargs...)
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
    deduct_taxes!(calc, t; kwargs...) 
    update_inflation!(calc, t; kwargs...) 
    update_interest!(calc, t; kwargs...) 
    update_net_worth!(calc, t; kwargs...)
    log!(calc, logger, t; kwargs...)
    return nothing 
end 

function to_years(calc::AbstractCalculator, t)
    return t
end

# function update_interest!(calc::AbstractCalculator, t; kwargs...)
#     error("update_interest! is not defined for defined for AbstractCalculator")
# end

# function withdraw!(calc::AbstractCalculator, t; kwargs...)
#     error("withdraw! is not defined for defined for AbstractCalculator")
# end

# function invest!(calc::AbstractCalculator, t; kwargs...)
#     error("invest! is not defined for defined for AbstractCalculator")
# end

# function update_inflation!(calc::AbstractCalculator, t; kwargs...)
#     error("update_inflation! is not defined for defined for AbstractCalculator")
# end

# function deduct_taxes!(calc::AbstractCalculator, t; kwargs...)
#     error("deduct_taxes! is not defined for defined for AbstractCalculator")
# end

# function update_networth!(calc::AbstractCalculator, t; kwargs...)
#     error("update_networth! is not defined for defined for AbstractCalculator")
# end

# function log!(calc, logger, t; kwargs...)
#     error("log! is not defined for defined for AbstractCalculator")
# end

function update_interest! end

function withdraw! end

function invest! end

function update_inflation! end

function deduct_taxes! end

function update_net_worth! end

function log! end