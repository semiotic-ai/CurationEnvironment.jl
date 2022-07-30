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

# ╔═╡ f0291b58-5cf5-4db2-9816-15adc6edb11d
num_subgraphs = 1

# ╔═╡ 6dc94b9d-baaf-41f3-bfe0-da48f2c90690
num_curators = 2

# ╔═╡ 9d2ef16c-7cb3-4352-abd0-f7c43b1db908
model = CurationEnvironment.CommunitySignalAuction()

# ╔═╡ 7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# Simulation Loop

# ╔═╡ b5aee30d-fe2b-43c4-a1e8-566372bfb4a4
function f(τ, q)
    p = q
    s = Subgraph(1, 100, 1.0, τ)
    attacker = Curator{num_subgraphs}(1, 100, 0, 10000)
    honest = Curator{num_subgraphs}(2, 100, 1.0, 10000)
    attacker, s = CurationEnvironment.curate(model, q, attacker, s)
    ψ = s.v
    honest, s = CurationEnvironment.curate(model, p, honest, s)
    honest, s = CurationEnvironment.curate(model, p, honest, s)
    # return s.v / ψ
    # Sell all shares
    qsell = CurationEnvironment.payment(model, -attacker.ses[1] / s.s, s.v, s.τ)
    attacker, s = CurationEnvironment.curate(model, qsell, attacker, s)

    return 100 * (attacker.σ - 10000) / 10000
end

# ╔═╡ d5fdb831-3bd0-4db3-a940-048e19179220
function g(τ, c)
    q = 100
    σ = 10000
    p = q
    s = Subgraph(1, 100, 1.0, τ)
    attacker = Curator{num_subgraphs}(1, 100, 0, σ)
    honest = Curator{num_subgraphs}(2, 100, 1.0, σ)
    attacker, s = CurationEnvironment.curate(model, q, attacker, s)
    ψ = s.v
    for _ in 1:c
        honest, s = CurationEnvironment.curate(model, p, honest, s)
    end
    # return s.v / ψ
    # Sell all shares
    qsell = CurationEnvironment.payment(model, -attacker.ses[1] / s.s, s.v, s.τ)
    attacker, s = CurationEnvironment.curate(model, qsell, attacker, s)
    qnew = attacker.σ - σ
    return 100 * qnew / q
end

# ╔═╡ d8b721fd-974d-461b-9776-92724ee11e60
function em(τ, c)
    q = 100
    σ = 10000
    # Needs to be constant x, not constant p
    p = q
    s = Subgraph(1, 100, 1.0, τ)
    attacker = Curator{num_subgraphs}(1, 100, 0, σ)
    honest = Curator{num_subgraphs}(2, 100, 1.0, σ)
    attacker, s = CurationEnvironment.curate(model, q, attacker, s)
    ψ = s.v
    for _ in 1:c
        honest, s = CurationEnvironment.curate(model, p, honest, s)
    end
    m = s.v / ψ
    return 100 * (m^(τ / (1 + τ)) - 1)
end

# ╔═╡ 61888691-14dd-41e1-9061-e7dfde599a7a
begin
    τ = 0:0.05:0.5
    q = 1:100
    c = 1:10
end

# ╔═╡ 7b3c3a8c-0f8a-45ab-ba90-772beccfbd33
contour(τ, q, f; fill=true, xlabel="τ", ylabel="q", title="s₁/s₀")

# ╔═╡ 179f12e9-21d3-4b9a-b303-4ec51d6f4b44
contour(
    τ,
    c,
    g;
    fill=true,
    xlabel="τ",
    ylabel="number successive transactions",
    title="% profit",
)

# ╔═╡ 46221d3a-b534-40e2-8b06-54451fa2af25
begin
    τs = 0.0:0.1:0.5
    i = 2
    vs = map(t -> g.(t, c), τs)
    plot(
        vs[i];
        label="τ=0.0",
        legend=:topleft,
        xlabel="number successive transactions",
        ylabel="% profit",
        xlims=(1, 10),
        xticks=1:10,
    )
    # ms = map(t -> em.(t, c), τs)
    # plot!(ms[i])
    for (i, t) in enumerate(τs[2:end])
        plot!(vs[i + 1]; label="τ=$t")
    end
    current()
end

# ╔═╡ 9d313768-6dfe-49b2-9f71-a12ac2794e06
# ╠═╡ disabled = true
#=╠═╡
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
    # plot!(info["cABalance"]; label="c1 balance")
    plot!(info["cAValuation"]; label="c1 valuation")
    # plot!(info["cBBalance"]; label="c2 balance")
    plot!(info["cBValuation"]; label="c2 valuation")
    # plot!(info["cCBalance"]; label="c3 balance")
    plot!(info["cCValuation"]; label="c3 valuation")
end
  ╠═╡ =#

# ╔═╡ 5b7def33-a9da-4d37-9b03-8edc782679b1
# ╠═╡ disabled = true
#=╠═╡
begin
    plot(info["sShares"]; label="subgraph shares")
    plot!(info["cAShares"]; label="c1 shares")
    plot!(info["cBShares"]; label="c2 shares")
    plot!(info["cCShares"]; label="c3 shares")
end
  ╠═╡ =#

# ╔═╡ b6ce2034-35c0-4ad3-962e-a89750452c33
# ╠═╡ disabled = true
#=╠═╡
info["time"] = map(i -> i, 1:(num_timesteps + 1))
  ╠═╡ =#

# ╔═╡ ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
# ╠═╡ disabled = true
#=╠═╡
df = DataFrame(info)
  ╠═╡ =#

# ╔═╡ 55f7b282-ac9b-4712-8dab-fcec140602e2
# ╠═╡ disabled = true
#=╠═╡
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
  ╠═╡ =#

# ╔═╡ Cell order:
# ╠═4bbe2bf4-73b1-46f1-9da7-e8ce76f3eebf
# ╠═53f46a83-b904-4e09-af82-7460ca012808
# ╠═25540dc0-093f-44d2-95a0-c57483883691
# ╠═a0b68675-3a6f-4517-88c9-278dce3e02f4
# ╠═39b3d75a-c74a-4cb3-bfba-738dfdb1ef65
# ╠═d2c9d87c-a64b-42d1-89bb-e9067bdf2136
# ╠═9f9efda3-184e-4aca-b0cd-ff1499a65bba
# ╠═df9d0388-7149-490a-b4bc-f5bce671f304
# ╠═00dfd03e-5359-4d44-b104-338bdb79071c
# ╠═493e644b-0540-4a94-8f3c-86113b86d67d
# ╠═f0291b58-5cf5-4db2-9816-15adc6edb11d
# ╠═6dc94b9d-baaf-41f3-bfe0-da48f2c90690
# ╠═9d2ef16c-7cb3-4352-abd0-f7c43b1db908
# ╠═7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# ╠═b5aee30d-fe2b-43c4-a1e8-566372bfb4a4
# ╠═d5fdb831-3bd0-4db3-a940-048e19179220
# ╠═d8b721fd-974d-461b-9776-92724ee11e60
# ╠═61888691-14dd-41e1-9061-e7dfde599a7a
# ╠═7b3c3a8c-0f8a-45ab-ba90-772beccfbd33
# ╠═179f12e9-21d3-4b9a-b303-4ec51d6f4b44
# ╠═46221d3a-b534-40e2-8b06-54451fa2af25
# ╠═9d313768-6dfe-49b2-9f71-a12ac2794e06
# ╠═5b7def33-a9da-4d37-9b03-8edc782679b1
# ╠═b6ce2034-35c0-4ad3-962e-a89750452c33
# ╠═ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
# ╠═55f7b282-ac9b-4712-8dab-fcec140602e2
