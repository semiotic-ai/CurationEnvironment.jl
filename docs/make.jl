using CurationEnvironment
using Documenter
using DemoCards

# Generate demo files
experiments, postprocess_experiments, experiments_assets = makedemos("experiments")

DocMeta.setdocmeta!(
    CurationEnvironment, :DocTestSetup, :(using CurationEnvironment); recursive=true
)

assets = String[]
isnothing(experiments_assets) || push!(assets, experiments_assets)

# Normal Documenter stuff

makedocs(;
    modules=[CurationEnvironment],
    authors="Semiotic Labs",
    repo="https://github.com/semiotic-ai/CurationEnvironment.jl/blob/{commit}{path}#{line}",
    sitename="CurationEnvironment.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://semiotic-ai/CurationEnvironment.jl",
        assets=assets,
    ),
    pages=["Home" => "index.md", experiments],
)

# Postprocess
postprocess_experiments()

deploydocs(; repo="github.com/semiotic-ai/CurationEnvironment.jl", devbranch="main")
