using MakieMaestro
using Test
using Aqua

@testset "MakieMaestro.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(MakieMaestro)
    end
    # Write your tests here.
end
