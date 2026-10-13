set shell := ["bash", "-cu"]
set dotenv-load

# hint := BLUE + "" + NORMAL
progress := CYAN + "●" + NORMAL
ok := GREEN + "✓" + NORMAL
# warn := YELLOW + "⚠" + NORMAL
fail := RED + "✗" + NORMAL

[doc("Default recipe shows available commands")]
[private]
default:
    @just --list

root-dir := justfile_directory()

[doc("Run unittests for the package")]
[group("test")]
[script("fish")]
[working-directory(root-dir)]
test:
    julia --project -e "using Pkg; Pkg.test()"

[doc("Launch the Julia project REPL")]
[group("dev")]
[script("fish")]
[working-directory(root-dir)]
repl:
    julia --project

[doc("Generate and open the package documenation")]
[group("docs")]
[script("fish")]
[working-directory(root-dir)]
docs:
    echo "{{ progress }} Generating documentation..."
    julia --project=docs --color=yes docs/make.jl
    echo "{{ ok }} Documentation generated."
    xdg-open docs/build/index.html

[doc("Instantiate the package environments")]
[group("dev")]
[script("fish")]
[working-directory(root-dir)]
pkg-instantiate:
    echo "{{ progress }} Instantiating project packages..."
    julia --project -e 'try; using Pkg; Pkg.instantiate(); println("{{ ok }} Instantiated."); catch e; println(stderr, "{{ fail }} Instantiation failed."); exit(1); end'
    echo "{{ progress }} Instantiating documentation packages..."
    julia --project=docs -e 'try; using Pkg; Pkg.instantiate(); println("{{ ok }} Instantiated."); catch e; println(stderr, "{{ fail }} Instantiation failed."); exit(1); end'
    echo "{{ progress }} Instantiating test packages..."
    julia --project=test -e 'try; using Pkg; Pkg.instantiate(); println("{{ ok }} Instantiated."); catch e; println(stderr, "{{ fail }} Instantiation failed."); exit(1); end'

[doc("Update the package environments")]
[group("dev")]
[script("fish")]
[working-directory(root-dir)]
pkg-update:
    echo "{{ progress }} Updating project packages..."
    julia --project -e 'try; using Pkg; Pkg.update(); println("{{ ok }} Updated."); catch e; println(stderr, "{{ fail }} Update failed."); exit(1); end'
    echo "{{ progress }} Updating documentation packages..."
    julia --project=docs -e 'try; using Pkg; Pkg.update(); println("{{ ok }} Updated."); catch e; println(stderr, "{{ fail }} Update failed."); exit(1); end'
    echo "{{ progress }} Updating test packages..."
    julia --project=test -e 'try; using Pkg; Pkg.update(); println("{{ ok }} Updated."); catch e; println(stderr, "{{ fail }} Update failed."); exit(1); end'

[doc("Resolve the package environments")]
[group("dev")]
[script("fish")]
[working-directory(root-dir)]
pkg-resolve:
    echo "{{ progress }} Resolving project packages..."
    julia --project -e 'try; using Pkg; Pkg.resolve(); println("{{ ok }} Resolved."); catch e; println(stderr, "{{ fail }} Resolving failed."); exit(1); end'
    echo "{{ progress }} Resolving documentation packages..."
    julia --project=docs -e 'try; using Pkg; Pkg.resolve(); println("{{ ok }} Resolved."); catch e; println(stderr, "{{ fail }} Resolving failed."); exit(1); end'
    echo "{{ progress }} Resolving test packages..."
    julia --project=test -e 'try; using Pkg; Pkg.resolve(); println("{{ ok }} Resolved."); catch e; println(stderr, "{{ fail }} Resolving failed."); exit(1); end'
