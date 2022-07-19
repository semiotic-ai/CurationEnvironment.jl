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

# ╔═╡ 6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
τ = 0.01

# ╔═╡ f0291b58-5cf5-4db2-9816-15adc6edb11d
num_subgraphs = 1

# ╔═╡ 6dc94b9d-baaf-41f3-bfe0-da48f2c90690
num_curators = 2

# ╔═╡ 9d2ef16c-7cb3-4352-abd0-f7c43b1db908
model = CurationEnvironment.CommunitySignalAuction()

# ╔═╡ 7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# Simulation Loop

# ╔═╡ 61888691-14dd-41e1-9061-e7dfde599a7a
begin
    # info = Dict(
    # 	"sValuation" => Float64[s.v],
    #        "sShares" => Float64[s.s],
    #        "sTau" => Float64[s.τ],
    #        "attackerShares" => Float64[attacker.ses[1]],
    #        "attackerBalance" => Float64[attacker.σ],
    # 	"honestShares" => Float64[honest.ses[1]],
    #        "honestBalance" => Float64[honest.σ],
    # )
    p = 100
    for q in 1:200
        s = Subgraph(1, 100, 1.0, τ)
        attacker = Curator{num_subgraphs}(1, 100, 0, 200)
        honest = Curator{num_subgraphs}(2, 100, 1.0, p)
        attacker, s = CurationEnvironment.curate(model, q, attacker, s)
        honest, s = CurationEnvironment.curate(model, p, honest, s)
        # Sell all shares
        qsell = CurationEnvironment.payment(model, -attacker.ses[1] / s.s, s.v, s.τ)
        attacker, s = CurationEnvironment.curate(model, qsell, attacker, s)
        @show attacker.σ
    end
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
# ╠═6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
# ╠═f0291b58-5cf5-4db2-9816-15adc6edb11d
# ╠═6dc94b9d-baaf-41f3-bfe0-da48f2c90690
# ╠═9d2ef16c-7cb3-4352-abd0-f7c43b1db908
# ╠═7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# ╠═61888691-14dd-41e1-9061-e7dfde599a7a
# ╠═9d313768-6dfe-49b2-9f71-a12ac2794e06
# ╠═5b7def33-a9da-4d37-9b03-8edc782679b1
# ╠═b6ce2034-35c0-4ad3-962e-a89750452c33
# ╠═ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
# ╠═55f7b282-ac9b-4712-8dab-fcec140602e2
