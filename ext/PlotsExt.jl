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

        # FIT NORMAL DISTRIBUTIONS WITH PARAMETERS: μ(x) and σ(x)
        xx = range(extrema(X)..., length=n_divions_x)
        xᵢ = [(xx[i], xx[i+1]) for i in 1:length(xx)-1]
        x₀ = mean.(xᵢ)
        μ = similar(x₀); σ = similar(x₀)
        for (i,xᵢ) in pairs(xᵢ)
            ix = xᵢ[1] .<= X .<= xᵢ[2]
            h = fit(Normal, Y[ix])
            μ[i] = h.μ;  σ[i] = h.σ
        end

        # FIT SMOOTHING SPLINES TO ABOVE
        splμ = fit(SmoothingSpline, x₀, μ, 0.05)      # λ=0.05
        splσ = fit(SmoothingSpline, x₀, σ, 0.02)      # λ=0.02
        μp = SmoothingSplines.predict(splμ, x₀)
        σp = SmoothingSplines.predict(splσ, x₀)

        # PLOT RIBBONS WITH ALPHA TRANSPARENCY SCALED:
        qq = @. quantile(truncated(Normal(μp, σp), 0, Inf), LinRange(0.01, 0.99, n_slices))
        α = [LinRange(0.15, 0.5, n_slices÷2); LinRange(0.5, 0.15, n_slices÷2)]
        p1 = plot(legend=false, grid=false)
        for i in 2:n_slices-1
            yᵢ = getindex.(qq, i)
            dy = yᵢ - getindex.(qq, i-1)
            plot!(x₀, yᵢ - dy/2, lw=0, color=:purple, grid=false, fillalpha=α[i], ribbon=dy; kwargs...)
        end
        plot!(x, y[:,1:n_lines])
        return p1
    end

    """
        plot_sensitivity(
            df::DataFrame, 
            factors::Vector{Symbol}, 
            z::Symbol; 
            age = nothing, 
            kwargs...
        )

    Visualizes a sensitivity analysis of two variables with a contour plot. 

    # Arguments  

    - `df::DataFrame`: long form dataframe containing columns for `factors` and `z`
    - `factors::Vector{Symbol}`:
    - `z::Symbol`: 

    # Keywords 

    - `age = nothing`: age on which the sensitivity plot is conditioned. If no value is specified, the maximum
        the sensitivity analysis is conditioned on the maximum age 
    - `kwargs...`: optional keyword arguments passed to `contour`
    """
    function plot_sensitivity(
            df::DataFrame, 
            factors::Vector{Symbol}, 
            z::Symbol; 
            age = nothing, 
            kwargs...
        )

        _age = isnothing(age) ? maximum(df.time) : age 
        df_end = filter(x -> x.time == _age, df)
        df_c = combine(
            groupby(df_end, factors), 
            z => mean => z
        )
        sort!(df_c, factors)

        x = unique(df_c[!,factors[1]])
        y = unique(df_c[!,factors[2]])

        return contour(
            x,
            y,
            reshape(df_c[!,z], length(y), length(x)),
            levels = 10,
            title = "Age: $_age",
            titlefontsize = 10,
            fill = (true, cgrad(:RdYlGn_9, scale = :log10, rev=false));
            kwargs...
        )
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
        n_steps,n_reps = size(getfield(data[2], fields[1]))
        df = DataFrame(
            time = repeat(times, n_reps),
            rep = repeat(1:n_reps, inner=n_steps)
        )
        for f ∈ fields 
            df[!,f] = getfield(data[2], f)[:]
        end
        for k ∈ data[1]
            col_name = make_unique_name(k[1])
            df[!,col_name] .= k[2]
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