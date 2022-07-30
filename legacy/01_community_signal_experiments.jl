### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 4bbe2bf4-73b1-46f1-9da7-e8ce76f3eebf
# Import local package
begin
    using Pkg: Pkg
    Pkg.activate(Base.current_project())
    Pkg.instantiate()
    using CurationEnvironment
end

# ╔═╡ dbae182f-35ab-496b-8021-0b2a657287ae
using Random

# ╔═╡ 53f46a83-b904-4e09-af82-7460ca012808
using Plots

# ╔═╡ 25540dc0-093f-44d2-95a0-c57483883691
using DataFrames

# ╔═╡ a0b68675-3a6f-4517-88c9-278dce3e02f4
using CSV

# ╔═╡ 39b3d75a-c74a-4cb3-bfba-738dfdb1ef65
# Configuration

# ╔═╡ d2c9d87c-a64b-42d1-89bb-e9067bdf2136
seed = 314

# ╔═╡ 9f9efda3-184e-4aca-b0cd-ff1499a65bba
minv = 50

# ╔═╡ df9d0388-7149-490a-b4bc-f5bce671f304
maxv = 100

# ╔═╡ 00dfd03e-5359-4d44-b104-338bdb79071c
minσ = 10

# ╔═╡ 493e644b-0540-4a94-8f3c-86113b86d67d
maxσ = 40

# ╔═╡ 6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
τ = 0.05

# ╔═╡ f0291b58-5cf5-4db2-9816-15adc6edb11d
num_subgraphs = 1

# ╔═╡ 6dc94b9d-baaf-41f3-bfe0-da48f2c90690
num_curators = 3

# ╔═╡ a36a0062-a785-42bc-8d1e-7c29b8d9eab5
num_timesteps = 80

# ╔═╡ 9d2ef16c-7cb3-4352-abd0-f7c43b1db908
model = CurationEnvironment.CommunitySignal()

# ╔═╡ a3be2084-4f32-4624-8eb1-37380718c1ba
# Initialisation

# ╔═╡ 33117076-2b42-4ee4-b557-ff304a1a7eda
Random.seed!(seed)

# ╔═╡ 6db36948-3aca-4091-ab5b-99d931d1e7ab
π = CurationEnvironment.best_response

# ╔═╡ ff36a706-f61b-442f-94c2-e10d1e5d65e1
# subgraphs = ntuple(_ -> Subgraph(1, rand(minv:maxv), 0.0, τ), num_subgraphs)

# ╔═╡ 5b52ec1b-ceec-4c5e-874d-5fc1d65d0d2e
# begin
#     curators = Curator[]
#     for i in 1:num_curators
#         v̂s = ntuple(_ -> rand(minv:maxv), num_subgraphs)
#         ses = ntuple(_ -> 0.0, num_subgraphs)
#         σ = rand(minσ:maxσ)
#         curator = Curator{num_subgraphs}(i, v̂s, ses, σ)
#         push!(curators, curator)
#     end
#     curators
# end

# ╔═╡ 6b2f9f92-6363-412e-bdaa-0dca7b67d1bc
begin
    Random.seed!(seed)
    subgraphs = ntuple(_ -> Subgraph(1, 1, 1.0, τ), num_subgraphs)
    c1 = Curator{1}(1, (53,), (0.0,), 40)
    c2 = Curator{1}(2, (90,), (0.0,), 45)
    c3 = Curator{1}(3, (96,), (0.0,), 50)
    curators = [c1, c2, c3]
    c = curators[1]
    curators[1] = Curator{num_subgraphs}(1, c.v̂s, (1.0,), c.σ)
end

# ╔═╡ 7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# Simulation Loop

# ╔═╡ 2de5a09d-cb8a-4010-8ccd-e1b5be6c14dc
begin
    info = Dict(
        "sValuation" => Float64[subgraphs[1].v],
        "sShares" => Float64[subgraphs[1].s],
        "sTau" => Float64[subgraphs[1].τ],
        "cAShares" => Float64[curators[1].ses[1]],
        "cABalance" => Float64[curators[1].σ],
        "cAValuation" => Float64[curators[1].v̂s[1]],
        "cBShares" => Float64[curators[2].ses[1]],
        "cBBalance" => Float64[curators[2].σ],
        "cBValuation" => Float64[curators[2].v̂s[1]],
        "cCShares" => Float64[curators[3].ses[1]],
        "cCBalance" => Float64[curators[3].σ],
        "cCValuation" => Float64[curators[3].v̂s[1]],
    )
    for t in 1:num_timesteps
        # Randomly pick a subgraph
        s = rand(subgraphs)
        # Every 10 timesteps, add query fees		
        if t % 10 == 0
            # # Increase subgraph price by 1
            # s = Subgraph(s.id, 1 * s.s + s.v, s.s, s.τ)
            # # Increase curators' valuation by price increase * num_shares
            # curators = map(x -> Curator{num_subgraphs}(x[1], (x[2].v̂s[s.id] + 1 * s.s,), x[2].ses, x[2].σ), enumerate(curators))

            # Increase subgraph price by 1
            s = Subgraph(s.id, 1 * 10.0 + s.v, s.s, s.τ)
            # Increase curators' valuation by price increase * num_shares
            curators = map(
                x -> Curator{num_subgraphs}(
                    x[1], (x[2].v̂s[s.id] + 10.0,), x[2].ses, x[2].σ
                ),
                enumerate(curators),
            )
        end
        # Randomly pick a curator
        c = rand(curators)
        # Let it stake or burn tokens
        nc, ns = CurationEnvironment.step(model, π, c, s)
        # Update curators and subgraphs
        curators[c.id] = nc
        subgraphs = (ns,)
        # Update info
        push!(info["sValuation"], subgraphs[1].v)
        push!(info["sShares"], subgraphs[1].s)
        push!(info["sTau"], subgraphs[1].τ)
        push!(info["cAShares"], curators[1].ses[1])
        push!(info["cBShares"], curators[2].ses[1])
        push!(info["cCShares"], curators[3].ses[1])
        push!(info["cABalance"], curators[1].σ)
        push!(info["cBBalance"], curators[2].σ)
        push!(info["cCBalance"], curators[3].σ)
        push!(info["cAValuation"], curators[1].v̂s[1])
        push!(info["cBValuation"], curators[2].v̂s[1])
        push!(info["cCValuation"], curators[3].v̂s[1])
    end
end

# ╔═╡ 9d313768-6dfe-49b2-9f71-a12ac2794e06
begin
    # @gif for i ∈ 2:length(info["sValuation"])
    # 	plot(info["sValuation"][1:i]; label="Subgraph Signal", legend=:bottomright, ylabel="signal (GRT)", xlabel="time")
    # 	plot!(info["cAValuation"][1:i]; label="A valuation")
    # 	plot!(info["cBValuation"][1:i]; label="B valuation")
    # 	plot!(info["cCValuation"][1:i]; label="C valuation")
    # end
    plot(
        info["sValuation"];
        label="Subgraph Signal",
        legend=:bottomright,
        ylabel="signal (GRT)",
        xlabel="time",
    )
    # plot!(info["c1_balance"]; label="c1 balance")
    plot!(info["cAValuation"]; label="A valuation")
    # plot!(info["c2_balance"]; label="c2 balance")
    plot!(info["cBValuation"]; label="B valuation")
    # plot!(info["c3_balance"]; label="c3 balance")
    plot!(info["cCValuation"]; label="C valuation")
end

# ╔═╡ 5b7def33-a9da-4d37-9b03-8edc782679b1
begin
    plot(info["sShares"]; label="subgraph shares")
    plot!(info["cAShares"]; label="c1 shares")
    plot!(info["cBShares"]; label="c2 shares")
    plot!(info["cCShares"]; label="c3 shares")
end

# ╔═╡ b6ce2034-35c0-4ad3-962e-a89750452c33
info["time"] = map(i -> i, 1:(num_timesteps + 1))

# ╔═╡ ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
df = DataFrame(info)

# ╔═╡ 55f7b282-ac9b-4712-8dab-fcec140602e2
for i in 1:num_timesteps
    fname = "data-$i.tex"
    sharesCurr = df[i, :]["sShares"]
    sharesNew = df[i + 1, :]["sShares"]
    price = df[i, :]["sValuation"] / sharesCurr
    curatorAtokens = df[i, :]["cABalance"]
    curatorAequity = df[i, :]["cAShares"] * price
    curatorBtokens = df[i, :]["cBBalance"]
    curatorBequity = df[i, :]["cBShares"] * price
    curatorCtokens = df[i, :]["cCBalance"]
    curatorCequity = df[i, :]["cCShares"] * price
    newEquity = (sharesNew - sharesCurr) / sharesNew
    body = """\\def\\sharesCurr{$sharesCurr}
    \\def\\sharesNew{$sharesNew}
    \\def\\price{$price}
    \\def\\feeRate{$τ}
    \\def\\curatorAtokens{$curatorAtokens}
    \\def\\curatorAequity{$curatorAequity}
    \\def\\curatorBtokens{$curatorBtokens}
    \\def\\curatorBequity{$curatorBequity}
    \\def\\curatorCtokens{$curatorCtokens}
    \\def\\curatorCequity{$curatorCequity}
    \\def\\newEquity{$newEquity}
    """
    open("experiments/$fname", "w") do f
        write(f, body)
    end
    fname = "data-$i.csv"
    CSV.write("experiments/$fname", df[1:i, :])
end

# ╔═╡ Cell order:
# ╠═4bbe2bf4-73b1-46f1-9da7-e8ce76f3eebf
# ╠═dbae182f-35ab-496b-8021-0b2a657287ae
# ╠═53f46a83-b904-4e09-af82-7460ca012808
# ╠═25540dc0-093f-44d2-95a0-c57483883691
# ╠═a0b68675-3a6f-4517-88c9-278dce3e02f4
# ╠═39b3d75a-c74a-4cb3-bfba-738dfdb1ef65
# ╠═d2c9d87c-a64b-42d1-89bb-e9067bdf2136
# ╠═9f9efda3-184e-4aca-b0cd-ff1499a65bba
# ╠═df9d0388-7149-490a-b4bc-f5bce671f304
# ╠═00dfd03e-5359-4d44-b104-338bdb79071c
# ╠═493e644b-0540-4a94-8f3c-86113b86d67d
# ╠═6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
# ╠═f0291b58-5cf5-4db2-9816-15adc6edb11d
# ╠═6dc94b9d-baaf-41f3-bfe0-da48f2c90690
# ╠═a36a0062-a785-42bc-8d1e-7c29b8d9eab5
# ╠═9d2ef16c-7cb3-4352-abd0-f7c43b1db908
# ╠═a3be2084-4f32-4624-8eb1-37380718c1ba
# ╠═33117076-2b42-4ee4-b557-ff304a1a7eda
# ╠═6db36948-3aca-4091-ab5b-99d931d1e7ab
# ╠═ff36a706-f61b-442f-94c2-e10d1e5d65e1
# ╠═5b52ec1b-ceec-4c5e-874d-5fc1d65d0d2e
# ╠═6b2f9f92-6363-412e-bdaa-0dca7b67d1bc
# ╠═7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# ╠═2de5a09d-cb8a-4010-8ccd-e1b5be6c14dc
# ╠═9d313768-6dfe-49b2-9f71-a12ac2794e06
# ╠═5b7def33-a9da-4d37-9b03-8edc782679b1
# ╠═b6ce2034-35c0-4ad3-962e-a89750452c33
# ╠═ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
# ╠═55f7b282-ac9b-4712-8dab-fcec140602e2
