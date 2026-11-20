set shell := ["bash", "-cu"]
set dotenv-load

hint := BLUE + "" + NORMAL
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

[doc("""
Internal: ensure a GitHub token is available for remote metadata.
Priority:
1. GITHUB_TOKEN environment variable
2. gh CLI (via `gh auth token`)
""")]
[group("release")]
[private]
[script("fish")]
_gh-authenticated:
    if not type -q gh
        echo "{{ fail }} GITHUB_TOKEN is not set and gh CLI is not installed." >&2
        echo "{{ hint }} Install gh and run: gh auth login" >&2
        exit 1
    end
    if not gh auth status &>/dev/null
        echo "{{ fail }} gh CLI is not authenticated. Run: gh auth login" >&2
        exit 1
    end

[doc("Regenerate CHANGELOG.md with enriched GitHub metadata.")]
[group("release")]
[script("fish")]
changelog: _gh-authenticated
    if not set -q GITHUB_TOKEN
        set -gx GITHUB_TOKEN (gh auth token)
    end
    git-cliff -o CHANGELOG.md
    if test $status -eq 0
        echo "{{ ok }} CHANGELOG.md generated." >&2
        echo "{{ hint }} Review the changes, then stage and commit if needed." >&2
    else
        echo "{{ fail }} CHANGELOG.md generation failed." >&2
    end

[arg("semantic-bump", pattern="patch|minor|major")]
[doc("Bump version, update changelog, tag, and open a Registrator.jl issue")]
[group("release")]
[script("fish")]
[working-directory(root-dir)]
register semantic-bump="patch": _gh-authenticated
    if not set -q GITHUB_TOKEN
        set -gx GITHUB_TOKEN (gh auth token)
    end

    set tag_version (git-cliff --bumped-version --bump {{ semantic-bump }})
    set pkg_version (string replace -r '^v' '' -- $tag_version)
    set branch (git branch --show-current)

    echo "{{ progress }} Bumping Project.toml version to $version ($tag_version)..."
    sed -i -E "s/^version = \".*\"/version = \"$pkg_version\"/" Project.toml
    echo "{{ ok }} Project.toml updated to $pkg_version."

    echo "{{ progress }} Generating CHANGELOG.md..."
    git-cliff --bump {{ semantic-bump }} -o CHANGELOG.md
    echo "{{ ok }} CHANGELOG.md updated."

    set release_notes (git-cliff --bump {{ semantic-bump }} --unreleased | string collect)

    echo "{{ progress }} Committing and tagging $tag_version..."
    git add Project.toml CHANGELOG.md
    git commit -m "chore(release): prepare for $tag_version"
    git tag --sign -a $tag_version -m "Release $tag_version"
    git push origin $branch --follow-tags
    echo "{{ ok }} Pushed commit and tag $tag_version to $branch."

    echo "{{ progress }} Creating GitHub registration issue..."
    set issue_body (printf "@JuliaRegistrator register branch=%s\n\nRelease notes:\n\n%s\n" "$branch" "$release_notes" | string collect)
    gh issue create --title "Register $tag_version" --body "$issue_body"
    echo "{{ ok }} Registration issue created for $tag_version."
