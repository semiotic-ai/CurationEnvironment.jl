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

# ╔═╡ 424fad76-f78c-46c2-9afb-fe427b5bace3
using Random

# ╔═╡ 53f46a83-b904-4e09-af82-7460ca012808
using Plots

# ╔═╡ 6dcd08ac-e82d-4f68-90fb-ba05b07539b7
using Accessors

# ╔═╡ 25540dc0-093f-44d2-95a0-c57483883691
using DataFrames

# ╔═╡ a0b68675-3a6f-4517-88c9-278dce3e02f4
using CSV

# ╔═╡ 682cf454-84ea-450d-a631-f472cccfbffe
using MLStyle

# ╔═╡ f82e4e46-e1b8-44eb-be84-d7ab2c7bebc1
Random.seed!(343)

# ╔═╡ 39b3d75a-c74a-4cb3-bfba-738dfdb1ef65
# Configuration

# ╔═╡ e98e8952-3f82-4ea6-bfde-0a5ac45bee6d
feerate = 0.05

# ╔═╡ 6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
t = τ(feerate)

# ╔═╡ 38bdbfb7-1204-4b93-b61a-6313b0b1c925
nt = 150

# ╔═╡ 9d2ef16c-7cb3-4352-abd0-f7c43b1db908
m = CommunitySignal()

# ╔═╡ a3be2084-4f32-4624-8eb1-37380718c1ba
# Initialisation

# ╔═╡ 6db36948-3aca-4091-ab5b-99d931d1e7ab
π = best_response

# ╔═╡ 6b2f9f92-6363-412e-bdaa-0dca7b67d1bc
begin
    s = Subgraph(1, 500.0, 500.0, t)
    ca = MinMaxCurator{1}(1, (1000.0,), (2500.0,), (0.0,), 10000.0)
    cb = MinMaxCurator{1}(2, (500.0,), (4000.0,), (0.0,), 10000.0)
    cc = MinMaxCurator{1}(3, (1500.0,), (2000.0,), (0.0,), 10000.0)
    cd = MinMaxCurator{1}(4, (1750.0,), (3500.0,), (0.0,), 10000.0)
    ce = MinMaxCurator{1}(5, (0.0,), (3000.0,), (0.0,), 10000.0)
    cs = (ca, cb, cc, cd, ce)
end

# ╔═╡ 7d0e5341-0cb9-478f-a035-07e84f9d2e78
function utility(cump, c, s)
    ξ = ςs(c, id(s)) / ς(s)
    v̂max = v̂maxs(c, id(s))
    return ξ * v̂max - cump
end

# ╔═╡ e9db4432-b2f9-4868-a5a6-a285519e41bf
function logc(m, d, i, c, nc, s)
    texnames = ["A", "B", "C", "D", "E"]
    name = texnames[i]
    tx = σ(nc) != σ(c) ? 1.0 : 0.0
    push!(d["curator$(name)trans"], d["curator$(name)trans"][end] + tx)
    p = σ(c) - σ(nc)
    push!(d["curator$(name)p"], d["curator$(name)p"][end] + p)
    push!(d["curator$(name)fees"], d["curator$(name)fees"][end] + latefees(m, p, s))
    push!(d["curator$(name)utility"], utility(d["curator$(name)p"][end], nc, s))
    return d
end

# ╔═╡ 6bd6b2d5-15f6-434b-b3ae-1ab0dbcc1ac3
function logc(m, d, i, c)
    texnames = ["A", "B", "C", "D", "E"]
    name = texnames[i]
    push!(d["curator$(name)trans"], d["curator$(name)trans"][end])
    push!(d["curator$(name)utility"], d["curator$(name)utility"][end])
    push!(d["curator$(name)fees"], d["curator$(name)fees"][end])
    push!(d["curator$(name)p"], d["curator$(name)p"][end])
    return d
end

# ╔═╡ 7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# Simulation Loop

# ╔═╡ 2de5a09d-cb8a-4010-8ccd-e1b5be6c14dc
begin
    rep(x, n) = repeat([x], n)
    info = Dict(
        "shares" => [ς(s)],
        "price" => [v(s) / ς(s)],
        "feeRate" => rep(feerate, nt + 1),
        "curatorAtrans" => [0.0],
        "curatorAmax" => rep(v̂maxs(ca, 1), nt + 1),
        "curatorAmin" => rep(v̂mins(ca, 1), nt + 1),
        "curatorAfees" => [0.0],
        "curatorAutility" => [0.0],
        "curatorAp" => [0.0],  # running sum of payments
        "curatorBtrans" => [0.0],
        "curatorBmax" => rep(v̂maxs(cb, 1), nt + 1),
        "curatorBmin" => rep(v̂mins(cb, 1), nt + 1),
        "curatorBfees" => [0.0],
        "curatorButility" => [0.0],
        "curatorBp" => [0.0],
        "curatorCtrans" => [0.0],
        "curatorCmax" => rep(v̂maxs(cc, 1), nt + 1),
        "curatorCmin" => rep(v̂mins(cc, 1), nt + 1),
        "curatorCfees" => [0.0],
        "curatorCutility" => [0.0],
        "curatorCp" => [0.0],
        "curatorDtrans" => [0.0],
        "curatorDmax" => rep(v̂maxs(cd, 1), nt + 1),
        "curatorDmin" => rep(v̂mins(cd, 1), nt + 1),
        "curatorDfees" => [0.0],
        "curatorDutility" => [0.0],
        "curatorDp" => [0.0],
        "curatorEtrans" => [0.0],
        "curatorEmax" => rep(v̂maxs(ce, 1), nt + 1),
        "curatorEmin" => rep(v̂mins(ce, 1), nt + 1),
        "curatorEfees" => [0.0],
        "curatorEutility" => [0.0],
        "curatorEp" => [0.0],
        "signal" => [v(s)],
    )
    local ncs = cs
    local _s = s
    local n = 0.01  # noise
    numc = length(ncs)
    is = collect(1:numc)
    for i in 1:nt
        i = rand(is)
        c = ncs[i]
        nc, ns = CurationEnvironment.step(m, π, c, _s)
        global info = logc(m, info, i, c, nc, ns)
        js = filter(j -> j != i, is)
        for j in js
            global info = logc(m, info, j, cs[j])
        end

        push!(info["shares"], ς(ns))
        push!(info["price"], v(ns) / ς(ns))
        push!(info["signal"], v(ns))
        ncs = @set ncs[i] = nc
        _s = ns

        # Noisy updates of valuations
        for (j, c) in enumerate(ncs)
            c = v̂maxs(c, v̂maxs(c, id(_s)) + (randn() * n * v̂maxs(c, id(_s))), id(_s))
            c = v̂mins(c, v̂mins(c, id(_s)) + (randn() * n * v̂mins(c, id(_s))), id(_s))
            ncs = @set ncs[j] = c
        end
    end
    # @show π(m, ncs[2], _s)
    # @show ςs(ncs[1], 1) / ς(_s)
    # @show ςs(ncs[2], 1) / ς(_s)
    # @show ςs(ncs[3], 1) / ς(_s)
    # @show ςs(ncs[4], 1) / ς(_s)
    # @show ςs(ncs[5], 1) / ς(_s)
    @show v(_s)
end

# ╔═╡ 96f54c91-5f0e-4969-bf21-40a4e60d2a57
begin
    plot(info["curatorAutility"]; label="A utility", legend=:bottomright, xlabel="time")
    plot!(info["curatorButility"]; label="B utility")
    plot!(info["curatorCutility"]; label="C utility")
    plot!(info["curatorDutility"]; label="D utility")
    plot!(info["curatorEutility"]; label="E utility")
    plot!(info["signal"]; label="signal")
end

# ╔═╡ 9d313768-6dfe-49b2-9f71-a12ac2794e06
begin
    plot(
        info["curatorAp"];
        label="A payment",
        legend=:bottomright,
        # ylabel="signal (GRT)",
        xlabel="time",
    )
    plot!(info["curatorBp"]; label="B payment")
    plot!(info["curatorCp"]; label="C payment")
    plot!(info["curatorDp"]; label="D payment")
    plot!(info["curatorEp"]; label="E payment")
end

# ╔═╡ b6ce2034-35c0-4ad3-962e-a89750452c33
info["time"] = map(i -> i, 1:(nt + 1))

# ╔═╡ ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
df = DataFrame(info)

# ╔═╡ 55f7b282-ac9b-4712-8dab-fcec140602e2
for i in 1:nt
    fname = "data-$i.tex"
    sharesCurr = df[i, :]["shares"]
    sharesNew = df[i + 1, :]["shares"]
    price = df[i, :]["price"]
    newEquity = (sharesNew - sharesCurr) / sharesNew
    body = """\\def\\sharesCurr{$(round(sharesCurr; digits=1))}
    \\def\\sharesNew{$(round(sharesNew; digits=1))}
    \\def\\price{$(round(price; digits=1))}
    \\def\\feeRate{$(round(df[i, :]["feeRate"]; digits=1))}
    \\def\\curatorAtrans{$(round(df[i, :]["curatorAtrans"]; digits=1))}
 \\def\\curatorAmax{$(round(df[i, :]["curatorAmax"]; digits=1))}
 \\def\\curatorAmin{$(round(df[i, :]["curatorAmin"]; digits=1))}
 \\def\\curatorAfees{$(round(df[i, :]["curatorAfees"]; digits=1))}
 \\def\\curatorAutility{$(round(df[i, :]["curatorAutility"]; digits=1))}
    \\def\\curatorBtrans{$(round(df[i, :]["curatorBtrans"]; digits=1))}
 \\def\\curatorBmax{$(round(df[i, :]["curatorBmax"]; digits=1))}
 \\def\\curatorBmin{$(round(df[i, :]["curatorBmin"]; digits=1))}
 \\def\\curatorBfees{$(round(df[i, :]["curatorBfees"]; digits=1))}
 \\def\\curatorButility{$(round(df[i, :]["curatorButility"]; digits=1))}
    \\def\\curatorCtrans{$(round(df[i, :]["curatorCtrans"]; digits=1))}
 \\def\\curatorCmax{$(round(df[i, :]["curatorCmax"]; digits=1))}
 \\def\\curatorCmin{$(round(df[i, :]["curatorCmin"]; digits=1))}
 \\def\\curatorCfees{$(round(df[i, :]["curatorCfees"]; digits=1))}
 \\def\\curatorCutility{$(round(df[i, :]["curatorCutility"]; digits=1))}
    \\def\\curatorDtrans{$(round(df[i, :]["curatorDtrans"]; digits=1))}
 \\def\\curatorDmax{$(round(df[i, :]["curatorDmax"]; digits=1))}
 \\def\\curatorDmin{$(round(df[i, :]["curatorDmin"]; digits=1))}
 \\def\\curatorDfees{$(round(df[i, :]["curatorDfees"]; digits=1))}
 \\def\\curatorDutility{$(round(df[i, :]["curatorDutility"]; digits=1))}
    \\def\\curatorEtrans{$(round(df[i, :]["curatorEtrans"]; digits=1))}
 \\def\\curatorEmax{$(round(df[i, :]["curatorEmax"]; digits=1))}
 \\def\\curatorEmin{$(round(df[i, :]["curatorEmin"]; digits=1))}
 \\def\\curatorEfees{$(round(df[i, :]["curatorEfees"]; digits=1))}
 \\def\\curatorEutility{$(round(df[i, :]["curatorEutility"]; digits=1))}
    \\def\\newEquity{$(round(newEquity; digits=1))}
    """
    open("experiments/$fname", "w") do f
        write(f, body)
    end
    fname = "data-$i.csv"
    CSV.write("experiments/$fname", df[1:i, (end - 1):end])
end

# ╔═╡ Cell order:
# ╠═424fad76-f78c-46c2-9afb-fe427b5bace3
# ╠═f82e4e46-e1b8-44eb-be84-d7ab2c7bebc1
# ╠═4bbe2bf4-73b1-46f1-9da7-e8ce76f3eebf
# ╠═53f46a83-b904-4e09-af82-7460ca012808
# ╠═6dcd08ac-e82d-4f68-90fb-ba05b07539b7
# ╠═25540dc0-093f-44d2-95a0-c57483883691
# ╠═a0b68675-3a6f-4517-88c9-278dce3e02f4
# ╠═682cf454-84ea-450d-a631-f472cccfbffe
# ╠═39b3d75a-c74a-4cb3-bfba-738dfdb1ef65
# ╠═e98e8952-3f82-4ea6-bfde-0a5ac45bee6d
# ╠═6ab3f2bd-7b72-4a85-b25b-9f59f09f177c
# ╠═38bdbfb7-1204-4b93-b61a-6313b0b1c925
# ╠═9d2ef16c-7cb3-4352-abd0-f7c43b1db908
# ╠═a3be2084-4f32-4624-8eb1-37380718c1ba
# ╠═6db36948-3aca-4091-ab5b-99d931d1e7ab
# ╠═6b2f9f92-6363-412e-bdaa-0dca7b67d1bc
# ╠═7d0e5341-0cb9-478f-a035-07e84f9d2e78
# ╠═e9db4432-b2f9-4868-a5a6-a285519e41bf
# ╠═6bd6b2d5-15f6-434b-b3ae-1ab0dbcc1ac3
# ╠═7f35bca2-abfa-4bea-9fa4-ba6b73ff39bb
# ╠═2de5a09d-cb8a-4010-8ccd-e1b5be6c14dc
# ╠═96f54c91-5f0e-4969-bf21-40a4e60d2a57
# ╠═9d313768-6dfe-49b2-9f71-a12ac2794e06
# ╠═b6ce2034-35c0-4ad3-962e-a89750452c33
# ╠═ac8c935f-c107-42d7-bd5c-2aeb07b4c0f9
# ╠═55f7b282-ac9b-4712-8dab-fcec140602e2
