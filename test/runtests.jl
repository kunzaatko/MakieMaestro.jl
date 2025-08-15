using MakieMaestro
using Test, Documenter, CompatHelperLocal
using Aqua

include("./tools.jl")

const run_all = isempty(ARGS) ? true : false

skip = Dict{String,Bool}(
    "compat" => !(VERSION >= v"1.9"), # NOTE: `CompatHelperLocal` only compatible with later Julia version <28-02-25> 
    "aqua" => !haskey(ENV, "GITHUB_ACTIONS") && !haskey(ENV, "RUNTESTS_FULL"),
    "doctests" => !haskey(ENV, "RUNTESTS_FULL") && !(haskey(ENV, "RUNNER_OS") && ENV["RUNNER_OS"] == "Linux"),
    "ambiguities" => true # FIX: Fix the ambiguities <24-04-25> 
)

function should_test(arg::String)::Bool
    global run_all
    if run_all
        return !get(skip, arg, false)
    elseif arg in ARGS
        return true
    end
    return false
end

macro cond_testset(name, block)
    quote
        if should_test($name)
            @testset $name begin
                esc($block)
            end
        end
    end
end

@testset "MakieMaestro.jl" begin
    if should_test("documenter")
        @info "Building documenter/make.jl"
        @eval Main include("documenter/make.jl")
    end

    @testset "Code quality" begin
        @cond_testset "aqua" begin
            Aqua.test_all(
                MakieMaestro;
                ambiguities=false,
            )
        end

        @cond_testset "ambiguities" begin
            aqua_ambiguities = false
            if aqua_ambiguities
                Agua.test_ambiguities(MakieMaestro)
            else
                @test length(Test.detect_ambiguities(MakieMaestro)) == 0
            end
        end

        @cond_testset "compat" begin
            @test CompatHelperLocal.check(MakieMaestro; checktest=false)
        end
    end

    @cond_testset "doctests" begin
        # FIX: When running locally, do not ask for SSH key password <10-12-23> 
        # NOTE: Show for `Unitful.jl` does nm⁻¹ on macOS and nm^-1 on Linux. This is necessary, since the `jldoctest` is only one
        # NOTE: Better than doc-testing in `make.jl` because, I can track the coverage
        # NOTE: Show for `Unitful.jl` does nm⁻¹ on macOS and nm^-1 on Linux. This is necessary, since the `jldoctest` is only one
        DocMeta.setdocmeta!(
            MakieMaestro,
            :DocTestSetup,
            :(
                include(joinpath(@__DIR__, "doctestsetup.jl"));
                using Logging; # NOTE: This does not need to be in the `make.jl` of docs. We want `@warn ` to function there <19-12-24> 
                Logging.disable_logging(Logging.Warn));
            recursive=true,
        )
        !haskey(ENV, "FIX_DOCTESTS") && @info "You can fix doctests by setting `ENV[\"FIX_DOCTESTS\"] = true`."
        doctest(MakieMaestro; fix=ifelse(haskey(ENV, "FIX_DOCTESTS"), true, false))
    end

    @cond_testset "theming" begin
        include("theming.jl")
    end

    @cond_testset "logging" begin
        include("logging.jl")
    end

    @cond_testset "exporting" begin
        include("exporting.jl")
    end

    @cond_testset "documenter" begin
        include("documenter/test.jl")
    end

    @cond_testset "recipes" begin
        include("recipes.jl")
    end
end
