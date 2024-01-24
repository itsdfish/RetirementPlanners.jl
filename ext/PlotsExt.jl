module PlotsExt

    using Distributions
    using Plots
    using RetirementPlanners
    using SmoothingSplines

    import RetirementPlanners: plot_gradient

    
    function plot_gradient(x, y::Array{<:Number, 2};
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
        α = [LinRange(0.10, 0.5, n_slices÷2); LinRange(0.5, 0.10, n_slices÷2)]
        p1 = plot(legend=false, grid=false)
        for i in 2:n_slices-1
            yᵢ = getindex.(qq, i)
            dy = yᵢ - getindex.(qq, i-1)
            plot!(x₀, yᵢ - dy/2, lw=0, color=:darkred, fillalpha=α[i], ribbon=dy; kwargs...)
        end
        plot!(x, y[:,1:n_lines])
        return p1
    end
end