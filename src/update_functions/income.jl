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
function fixed_income(
        model::AbstractModel,
        t;
        social_security_income = 0.0,
        pension_income = 0.0,
        social_security_start_age = 67.0,
        pension_start_age = 67
    )
    model.state.income_amount = 0.0
    if social_security_start_age ≤ t 
        model.state.income_amount += social_security_income
    end
    if pension_start_age ≤ t 
        model.state.income_amount += pension_income
    end
    return nothing
end