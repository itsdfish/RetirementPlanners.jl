function to_dataframe end

function plot_gradient end

function plot_sensitivity end

function Base.show(io::IO, ::MIME"text/plain", model::AbstractModel)
    return _show(io::IO, model)
end

function Base.show(io::IO, ::MIME"text/plain", logger::AbstractLogger)
    return _show(io::IO, logger)
end

function Base.show(io::IO, ::MIME"text/plain", logger::AbstractState)
    return _show(io::IO, logger)
end

function Base.show(io::IO, ::MIME"text/plain", model::AbstractTransaction)
    return _show(io::IO, model)
end

function Base.show(io::IO, ::MIME"text/plain", model::AdaptiveWithdraw)
    return _show(io::IO, model)
end

function Base.show(io::IO, ::MIME"text/plain", model::AdaptiveInvestment)
    return _show(io::IO, model)
end

function Base.show(io::IO, ::MIME"text/plain", model::AbstractGBM)
    return _show(io::IO, model)
end

function _show(io::IO, model)
    values = [getfield(model, f) for f in fieldnames(typeof(model))]
    values = map(x -> typeof(x) == Bool ? string(x) : x, values)
    T = typeof(model)
    model_name = string(T.name.name)
    return pretty_table(
        io,
        values;
        title = model_name,
        column_labels = ["Value"],
        stubhead_label = "Parameter",
        compact_printing = false,
        row_label_column_alignment = :l,
        row_labels = [fieldnames(typeof(model))...],
        formatters = [fmt__printf("%5.2f", [2,])],
        alignment = :l
    )
end
