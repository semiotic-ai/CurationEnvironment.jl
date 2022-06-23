using CurationEnvironment
using Documenter

DocMeta.setdocmeta!(CurationEnvironment, :DocTestSetup, :(using CurationEnvironment); recursive=true)

makedocs(;
    modules=[CurationEnvironment],
    authors="Semiotic Labs",
    repo="https://github.com/Semiotic Labs/CurationEnvironment.jl/blob/{commit}{path}#{line}",
    sitename="CurationEnvironment.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Semiotic Labs.github.io/CurationEnvironment.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Semiotic Labs/CurationEnvironment.jl",
    devbranch="main",
)
