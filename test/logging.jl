using MakieMaestro: InlineDict

@testset "unwrap_inline" begin 
    b_inline = InlineDict("c" => 1)
    d_inline = InlineDict("e" => 2)
    dict = Dict(
        "a" => Dict("b" => b_inline),
        "d" => d_inline
    )
    correct_inline = IdSet()
    push!(correct_inline, b_inline,d_inline)

    inline = MakieMaestro.inlineids(dict)

    @test inline == correct_inline
end

# TODO: Test the logging <15-08-25> 
