module PlotsExt

using RetirementPlanners
using Distributions
using Plots
using SmoothingSplines
using DataFrames

import RetirementPlanners: plot_gradient
import RetirementPlanners: plot_sensitivity
import RetirementPlanners: to_dataframe

"""
    plot_gradient(
        x, 
        y::Array{<:Number, 2};
        n_slices = 300,
        n_divions_x = 100,
        n_lines = 0,
        kwargs...
    )

Returns a density ribbon for time series data, where darker shading indicates more likely outcomes. 

# Arguments

- `x`: x-axis variable, typically time  
- `y::Array{<:Number, 2}`: a 2D array in which the first dimension is time and the second dimension is repetitions of the simulation

# Keywords 

- `n_slices = 300`: the granularity of the density gradient along the y-axis
- `n_divions_x = 100`: the granularity of the density gradient along the x-axis
- `n_lines = 0`: the number of trajactories to plot on top of the density gradient 
- `kwargs...`: optional keyword arguments for the plot 
"""
function plot_gradient(
    x,
    y::Array{<:Number, 2};
    n_slices = 300,
    n_divions_x = 100,
    n_lines = 0,
    kwargs...
)
    # reshape data
    n_reps = size(y, 2)
    X = repeat(x, n_reps)
    Y = y[:]

    # fit normal distributions
    xx = range(extrema(X)..., length = n_divions_x)
    xᵢ = [(xx[i], xx[i + 1]) for i = 1:(length(xx) - 1)]
    x₀ = mean.(xᵢ)
    μ = similar(x₀)
    σ = similar(x₀)
    for (i, xᵢ) in pairs(xᵢ)
        ix = xᵢ[1] .<= X .<= xᵢ[2]
        h = fit(Normal, Y[ix])
        μ[i] = h.μ
        σ[i] = h.σ
    end

    # fit plines
    splμ = fit(SmoothingSpline, x₀, μ, 0.05)      # λ=0.05
    splσ = fit(SmoothingSpline, x₀, σ, 0.02)      # λ=0.02
    μp = SmoothingSplines.predict(splμ, x₀)
    σp = SmoothingSplines.predict(splσ, x₀)
    σp = max.(σp, eps())

    # PLOT RIBBONS WITH ALPHA TRANSPARENCY SCALED:
    qq = @. quantile(truncated(Normal(μp, σp), 0, Inf), LinRange(0.025, 0.975, n_slices))
    α = [LinRange(0.15, 0.5, n_slices ÷ 2); LinRange(0.5, 0.15, n_slices ÷ 2)]
    p1 = plot(legend = false, grid = false)
    for i = 2:(n_slices - 1)
        yᵢ = getindex.(qq, i)
        dy = yᵢ - getindex.(qq, i - 1)
        plot!(
            x₀,
            yᵢ - dy / 2,
            lw = 0,
            color = :purple,
            grid = false,
            fillalpha = α[i],
            ribbon = dy;
            kwargs...
        )
    end
    plot!(x, y[:, 1:n_lines])
    return p1
end

"""
    plot_sensitivity(
        df::DataFrame, 
        factors::Vector{Symbol}, 
        z::Symbol; 
        age = maximum(df.time), 
        kwargs...
    )

Visualizes a sensitivity analysis of two variables with a contour plot. 

# Arguments  

- `df::DataFrame`: long form dataframe containing columns for `factors` and `z`
- `factors::Vector{Symbol}`: two factors forming the x and y dimensions
- `z::Symbol`: third dimension represented as color

# Keywords 

- `age = nothing`: age on which the sensitivity plot is conditioned. If no value is specified, the maximum
    the sensitivity analysis is conditioned on the maximum age. A grid of plots is returns if a vector of ages is provided. 
- `z_func = mean`: function applied to z-axis
- `show_common_color_scale = true`: if true, a color bar is displayed on right when `age` is a vector 
- `colorbar_title = ""`: the title for the common color scale
- `kwargs...`: optional keyword arguments passed to `contour`
"""
function plot_sensitivity(
    df::DataFrame,
    factors::Vector{Symbol},
    z::Symbol;
    age = maximum(df.time),
    show_common_color_scale = true,
    z_func = mean,
    colorbar_title,
    kwargs...
)
    plots = _plot_sensitivity(df, factors, z, age; z_func, kwargs...)
    if show_common_color_scale
        color_bar_plot = plot(
            plots[end];
            xlabel = "",
            ylabel = "",
            colorbar = true,
            colorbar_title,
            title = ""
        )
        layout = @layout [a b{0.05w}]
        return plot(plots, color_bar_plot; layout)
    end
    return plots
end

"""
    plot_sensitivity(
        df::DataFrame,
        factors::Vector{Symbol},
        z::Symbol,
        row_var::Symbol;
        colorbar_title = string(z),
        age,
        z_func = mean,
        ylabel = "",
        colorbar = false,
        margin = 0.3Plots.cm,
        row_label = "",
        grid_label_size = 13,
        size,
        kwargs...
    )

Generates a grid of contour plots for sensitivity analysis. The x and y coordinates of each contour plot are defined by 
`factors`, and `z` is the primary outcome displayed as color within the contour plots. The rows of the grid correspond to 
`row_var` and the columns corresond to time slices defined by `age`.

# Arguments  

- `df::DataFrame`: long form dataframe containing data for sensitivity analysis
- `factors::Vector{Symbol}`: two factors forming the x and y dimensions of the contour plots
- `z::Symbol`: third dimension represented as color
- `row_var::Symbol`: variable name for the rows of the contour grid 

# Keywords 

- `colorbar_title = string(z)`: the title for the common color scale
- `age = nothing`: age on which the sensitivity plot is conditioned. If no value is specified, the maximum
    the sensitivity analysis is conditioned on the maximum age. A grid of plots is returns if a vector of ages is provided. 
- `z_func = mean`: function applied to z-axis
- `margin = 0.3Plots.cm`: the size of the margin between the contour plots 
- `colorbar = false`: a color bar is displayed for each contour plot if true 
- `ylabel = ""`: label of the y-axis for each contour plot 
- `grid_label_size = 13`: the font size of the row and column labels of the grid 
- `size`: the dimensions of the entire plot 
- `kwargs...`: optional keyword arguments passed to `contour`
"""
function plot_sensitivity(
    df::DataFrame,
    factors::Vector{Symbol},
    z::Symbol,
    row_var::Symbol;
    colorbar_title,
    age,
    z_func = mean,
    ylabel = "",
    colorbar = false,
    margin = 0.3Plots.cm,
    row_label = "",
    grid_label_size = 13,
    size,
    kwargs...
)
    df_row_var = groupby(df, row_var)
    row_vals = [values(k)[1] for k ∈ keys(df_row_var)]
    plots = map(pairs(df_row_var)) do (k, v)
        p = _plot_sensitivity(
            v,
            factors,
            z,
            age;
            ylabel,
            colorbar,
            margin,
            title = "",
            z_func,
            kwargs...
        )
        temp_layout = @layout [a{0.03w} b]
        p1 = plot(
            plot(
                (0, 0),
                xlims = (-1, 1),
                ylims = (-1, 1),
                leg = false,
                grid = false,
                axis = ([], false)
            ),
            p,
            layout = temp_layout
        )
        annotate!(
            p1[1],
            0.0,
            0.0,
            text(
                "$row_label $(values(k)[1])",
                grid_label_size,
                :center,
                :center,
                rotation = 90
            )
        )
        return p1
    end
    color_bar_plot = plot(
        plots[end][end];
        xlabel = "",
        ylabel = "",
        colorbar = true,
        colorbar_title,
        title = ""
    )

    [title!(plots[1][i + 1], "age: $(age[i])") for i ∈ 1:length(age)]
    layout = @layout [a e{0.05w}]
    return plot(
        plot(plots..., titlefontsize = grid_label_size, layout = (length(plots), 1)),
        color_bar_plot;
        layout,
        margin,
        size
    )
end

function _plot_sensitivity(
    df,
    factors::Vector{Symbol},
    z::Symbol,
    age::Real;
    z_func = mean,
    kwargs...
)
    df_end = filter(x -> x.time == age, df)
    df_c = combine(groupby(df_end, factors), z => z_func => z)
    sort!(df_c, factors)

    x = unique(df_c[!, factors[1]])
    y = unique(df_c[!, factors[2]])

    return contour(
        x,
        y,
        reshape(df_c[!, z], length(y), length(x)),
        levels = 9,
        title = "Age: $age",
        titlefontsize = 10,
        fill = (true, cgrad(:RdYlGn_9, scale = :log10, rev = false));
        kwargs...
    )
end

function _plot_sensitivity(
    df,
    factors::Vector{Symbol},
    z::Symbol,
    ages;
    z_func = mean,
    clims,
    layout = (1, length(ages)),
    size = (800, 400),
    kwargs...
)
    plots = map(a -> _plot_sensitivity(df, factors, z, a; clims, z_func), ages)
    return plot(plots...; size, layout, clims, kwargs...)
end

"""
    to_dataframe(model::AbstractModel, data::Tuple)

Converts output from `grid_search` to a long-form dataframe. 

# Arguments

- `model::AbstractModel`: a subtype of abstract model for performing Monte Carlo simulations of retirement scenarios 
- `data::Tuple`: data output from `grid_search`
"""
function to_dataframe(model::AbstractModel, data::Tuple)
    times = get_times(model)
    fields = fieldnames(typeof(data[2]))
    n_fields = length(fields)
    n_steps, n_reps = size(getfield(data[2], fields[1]))
    df = DataFrame(time = repeat(times, n_reps), rep = repeat(1:n_reps, inner = n_steps))
    for f ∈ fields
        df[!, f] = getfield(data[2], f)[:]
    end
    for k ∈ data[1]
        col_name = make_unique_name(k[1])
        df[!, col_name] .= k[2]
    end
    return df
end

function to_dataframe(model, data)
    return mapreduce(x -> to_dataframe(model, x), append!, data)
end

function make_unique_name(np_keys)
    str = split(String(np_keys[1]), "kw_")[2]
    return Symbol(str * "_" * String(np_keys[2]))
end
end
