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

"""
function update_income!(
    model::AbstractModel,
    t;
    income_sources = Transaction(0.0, -1.0, 0.0)
)
    return _update_income!(model, t, income_sources)
end

function _update_income!(
    model::AbstractModel,
    t,
    income_sources::Vector{<:AbstractTransaction}
)
    (; state) = model
    state.income_amount = 0.0
    for source ∈ income_sources
        if is_available(source, t)
            state.income_amount += transact(source)
        end
    end
    return nothing
end

function _update_income!(model::AbstractModel, t, source::AbstractTransaction)
    (; state) = model
    state.income_amount = 0.0
    if is_available(source, t)
        state.income_amount += transact(source)
    end
    return nothing
end

is_available(source::AbstractTransaction, t) =
    (source.start_age ≤ t) && (source.end_age ≥ t)
transact(source::AbstractTransaction{T, D}) where {T, D <: Real} = source.amount
transact(source::AbstractTransaction{T, D}) where {T, D <: Distribution} =
    rand(source.amount)
