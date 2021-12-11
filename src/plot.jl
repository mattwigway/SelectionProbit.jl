const XY = collect(range(-3, 3, length=100))

function showplot()
    GLMakie.activate!()
    fig = Figure()
    buildplot!(fig[2, 1], fig[3, 1], Makie.Slider(fig[1, 1], range=XY, startvalue=0))
    fig
end

function buildplot!(pa1, pa2, slider)
    ρ = 0.7
    
    dist = MvNormal([0, 0], [1 ρ; ρ 1])

    grid = zeros(Float64, (100, 100))

    for (x, i) in enumerate(XY)
        for (y, j) in enumerate(XY)
            grid[x, y] = pdf(dist, [i, j])
        end
    end

    # compute shading and integral of portion above cutoff
    integrated = lift(slider.value) do ŷ
        integrated = zeros(Float64, 100)

        for (x, i) in enumerate(XY)
            for (y, j) in enumerate(XY)
                # probit likelihood function: P(ŷ + ϵ > 0), ϵ ~ N(0, 1)
                #                               = P(ϵ > -ŷ)
                if i > -ŷ
                    integrated[y] += grid[x, y]
                end
            end
        end

        integrated = integrated ./ sum(integrated)

        integrated
    end

    color = lift(slider.value) do ŷ
        color = Array{Any}(undef, 100, 100)

        for (x, i) in enumerate(XY)
            for (y, j) in enumerate(XY)
                color[x, y] = i > -ŷ ? colorant"#4B9CD3" : colorant"#AAAAAA"
            end
        end

        color
    end

    vertices = lift(slider.value) do ŷ
        top = maximum(grid)
        vertices = [
            3 -3 0;  # 1
            3 3 0;  # 2
            -ŷ 3 0; # 3
            -ŷ -3 0; # 4
            3 -3 top;  # 5
            3 3 top;  # 6
            -ŷ 3 top; # 7
            -ŷ -3 top; # 8
        ]
    end

    faces = [
        1 2 3; 4 1 3; # bottom
        5 6 7; 8 7 5; # top
        1 2 5; 5 6 2;
        2 3 6; 7 6 3;
        3 4 7; 8 7 4;
        4 1 5; 8 5 4;
    ]

    ax1 = Axis3(pa1, xlabel="Selection error term", ylabel="Outcome error term")
    surface!(ax1, XY, XY, grid)
    mesh!(ax1, vertices, faces, color=colorant"rgba(75, 156, 211, 0.5)")
    ax2 = Axis(pa2, ylims=(0, 15), yticks=[0])
    lines!(ax2, XY, integrated)
end

function wglplot(s, x...)
    WGLMakie.activate!()

    App() do session::Session
        fig = Figure(resolution=(1200, 900))
        slider = Makie.Slider(fig[1, 1], range=XY, startvalue=0)
        buildplot!(fig[2, 1], fig[3, 1], slider)
        return JSServe.record_states(session, DOM.div(slider, fig))
    end
end

function exportplot()
    JSServe.export_standalone(wglplot, joinpath(Base.source_dir(), "output"))
end