"""
    fixed_income(
        model::AbstractModel,
        t;
        social_security_income = 0.0,
        pension_income = 0.0,
        social_security_start_age = 67.0,
        pension_start_age = 67
    )

Recieve a fixed amount of income (e.g., social security, pension) per time step

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `social_security_income = 0.0`: income from social security on a per period basis
- `pension_income = 0.0`: income from pensions on a per period basis
- `social_security_start_age = 67.0`: age at which social security income begins 
- `pension_start_age = 67`: age at which pension income begins 
"""
function update_income!(model::AbstractModel, t; income_sources = [IncomeSource(0.0, -1.0, 0.0)])
    (; state) = model
    state.income_amount = 0.0
    for source ∈ income_sources
        if is_available(source, t)
            state.income_amount += receive(source)
        end
    end
    return nothing
end

is_available(source::AbstractIncomeSource, t) = (source.start_age ≤ t) && (source.end_age ≥ t)
receive(source::AbstractIncomeSource{T,D}) where {T,D<:Real} = source.amount 
receive(source::AbstractIncomeSource{T,D}) where {T,D<:Distribution} = rand(source.amount) 
