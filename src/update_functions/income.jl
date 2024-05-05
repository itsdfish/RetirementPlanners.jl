"""
    update_income!(
        model::AbstractModel,
        t;
        income_sources = Transaction(0.0, -1.0, 0.0)
    )

Recieve income from multiple sources per time step, as indicated by `income_sources`.

# Arguments

- `model::AbstractModel`: an abstract Model object 
- `t`: current time of simulation in years 

# Keywords

- `income_sources = Transaction(0.0, -1.0, 0.0)`: a transaction or vector of transactions indicating the amount and time period
of income recieved per time step 
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
            state.income_amount += transact(source; t)
        end
    end
    return nothing
end

function _update_income!(model::AbstractModel, t, source::AbstractTransaction)
    (; state) = model
    state.income_amount = 0.0
    if is_available(source, t)
        state.income_amount += transact(source; t)
    end
    return nothing
end

is_available(source::AbstractTransaction, t) =
    (source.start_age ≤ t) && (source.end_age ≥ t)
transact(source::AbstractTransaction{T, D}; _...) where {T, D <: Real} = source.amount
transact(source::AbstractTransaction{T, D}; _...) where {T, D <: Distribution} =
    rand(source.amount)
