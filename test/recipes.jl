using MakieMaestro.Recipes

f = Figure()
for (arg,kw) in [((f,10), (;nrows=2)), ((f, 10),(;ncols=2)), ((f,10), (;nrows=2, ncols=5)), ((f[1,1], 10,), (; nrows=2, ncols=5)), ((f[1,1][1,1], 10,), (; nrows=2, ncols=5))]
    ax = Recipes.create_axes!(arg...; kw...)
    @test length(ax) == arg[2]
end
