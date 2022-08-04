# ---
# title: Welfare Maximisation in the Community Signal Auction Model
# cover: assets/welfare_max.png
# id: csa_wm
# date: 2022-08-03
# author: "[Anirudh Patel](https://github.com/anirudh2)"
# julia: 1.7
# description: This experiment investigates whether the Community Signal Auction model is welfare-maximising. TL;DR - Okay for single auction. Non-decreasing across multiple auctions.
# ---

# Welfare maximisation is defined as in the
# [Curation v2](https://www.overleaf.com/read/hfymjbjmzwvf) yellowpaper.
# The main idea is that a welfare-maximising state is one in which curators that value
# subgraph most own the shares and the minimum viable signal is met for all curators
# Generally speaking, as we shall see, the community signal auction is welfare-maximising.

using CurationEnvironment
using Accessors
using CSV
using DataFrames
using CairoMakie

# Here we define a few helper functions for this experiment
rep(x, n) = repeat([x], n)

function utility(cump, c, s)
    ξ = ςs(c, id(s)) / ς(s)
    v̂max = v̂maxs(c, id(s))
    return ξ * v̂max - cump
end

function logc(m, d, i, c, nc, s)
    texnames = ["A", "B", "C", "D", "E"]
    name = texnames[i]
    tx = σ(nc) != σ(c) ? 1.0 : 0.0
    push!(d["curator$(name)trans"], d["curator$(name)trans"][end] + tx)
    p = σ(c) - σ(nc)
    push!(d["curator$(name)p"], d["curator$(name)p"][end] + p)
    push!(d["curator$(name)fees"], d["curator$(name)fees"][end] + latefees(m, p, s))
    push!(d["curator$(name)utility"], utility(d["curator$(name)p"][end], nc, s))
    push!(d["curator$(name)shares"], ςs(nc, id(s)))
    push!(d["curator$(name)max"], v̂maxs(nc, id(s)))
    push!(d["curator$(name)min"], v̂mins(nc, id(s)))
    return d
end

# Configuration
const feerate = 0.05
const t = τ(feerate)
const m = CRSPE(CommunitySignal())
const num_s = 1  # subgraphs
const num_c = 5  # curators
const πs = map(_ -> best_response, 1:num_c)
num_t = 50  # timesteps

# Create the curators and subgraph
# In this experiment, the curators have unlimited budget.
# We can make this assumption due to signal renting.
function network()
    v̂lows = (1000.0, 500.0, 1500.0, 1750.0, 0.0)
    v̂highs = (2500.0, 4000.0, 2000.0, 3500.0, 3000.0)
    shares = (0.0, 0.0, 0.0, 0.0, 0.0)
    stakes = (10000.0, 10000.0, 10000.0, 10000.0, 10000.0)
    cs = map(1:num_c, v̂lows, v̂highs, shares, stakes) do i, vl, vh, ς, σ
        return MinMaxCurator{num_s,Int64,Float64}(i, (vl,), (vh,), (ς,), σ)
    end
    s = Subgraph(1, 500.0, 500.0, t)

    return cs, s
end
cs, s = network()

# We can look at the generated curators
@show cs

# And the generated subgraph
@show s

# If the mechanism is welfare-maximising, we expect that curator B (2), will be the only
# curator to end up with shares.
# It has sufficient budget to own all of the shares.
# Thus, since it values the subgraphs the most, it should pay enough to get all of the
# shares.

# Create a dictionary for logging.
info = Dict(
    "time" => map(i -> i, 1:(num_t + 1)),
    "shares" => [ς(s)],
    "price" => [v(s) / ς(s)],
    "feeRate" => rep(feerate, num_t + 1),
    "curatorAtrans" => [0.0],
    "curatorAmax" => [v̂maxs(cs[1], 1)],
    "curatorAmin" => [v̂mins(cs[1], 1)],
    "curatorAfees" => [0.0],
    "curatorAutility" => [0.0],
    "curatorAp" => [0.0],  # running sum of payments
    "curatorAshares" => [0.0],
    "curatorBtrans" => [0.0],
    "curatorBmax" => [v̂maxs(cs[2], 1)],
    "curatorBmin" => [v̂mins(cs[2], 1)],
    "curatorBfees" => [0.0],
    "curatorButility" => [0.0],
    "curatorBp" => [0.0],
    "curatorBshares" => [0.0],
    "curatorCtrans" => [0.0],
    "curatorCmax" => [v̂maxs(cs[3], 1)],
    "curatorCmin" => [v̂mins(cs[3], 1)],
    "curatorCfees" => [0.0],
    "curatorCutility" => [0.0],
    "curatorCp" => [0.0],
    "curatorCshares" => [0.0],
    "curatorDtrans" => [0.0],
    "curatorDmax" => [v̂maxs(cs[4], 1)],
    "curatorDmin" => [v̂mins(cs[4], 1)],
    "curatorDfees" => [0.0],
    "curatorDutility" => [0.0],
    "curatorDp" => [0.0],
    "curatorDshares" => [0.0],
    "curatorEtrans" => [0.0],
    "curatorEmax" => [v̂maxs(cs[5], 1)],
    "curatorEmin" => [v̂mins(cs[5], 1)],
    "curatorEfees" => [0.0],
    "curatorEutility" => [0.0],
    "curatorEp" => [0.0],
    "curatorEshares" => [0.0],
    "signal" => [v(s)],
)

# Now we run the following experiment.
# At each timestep, curators play a greedy strategy to try to maximise their utility.
# We see at the end of this if the curator who values the subgraph the most owns all the
# new shares on the subgraph. Note that since we start with 500 shares on the subgraph,
# they won't own all the shares on the subgraph. Since the curators all have unlimited
# budgets, if the mechanism is welfare-maximising, we shouldn't have multiple curators
# curating the subgraph at the end of the this process.
for _ in 1:num_t
    ncs, ns = CurationEnvironment.step(m, πs, cs, s)
    for j in 1:num_c
        global info = logc(m, info, j, cs[j], ncs[j], ns)
    end
    push!(info["shares"], ς(ns))
    push!(info["price"], v(ns) / ς(ns))
    push!(info["signal"], v(ns))
    global cs = ncs
    global s = ns
end
@show v(s)

# Convert to a dataframe to view data
df = DataFrame(info)
CSV.write("assets/welfare_max.csv", df)
@show df

# You can download/inspect the [generated CSV](assets/welfare_max.csv) if you'd like.
# In any case, we can see that the mechanism is welfare-maximising in this case.
# Curator B (2) did ended up with all of the new shares on the subgraph.
time = info["time"]
f = Figure()
ax = Axis(f[1, 1]; title="Welfare Max CSA", xlabel="time", ylabel="shares")
lines!(ax, time, info["curatorAshares"]; label="A")
lines!(ax, time, info["curatorBshares"]; label="B")
lines!(ax, time, info["curatorCshares"]; label="C")
lines!(ax, time, info["curatorDshares"]; label="D")
lines!(ax, time, info["curatorEshares"]; label="E")
axislegend(ax)
save("assets/welfare_max.png", f)
f

# Now we turn to an experiment in which Curator valuations increase between auctions.
# In this case, we are curious to see whether the mechanism is still welfare-maximising
# across auctions.
# We begin by resetting the curators and the subgraph.
cs, s = network()

# Again, we create a dictionary for logging.
num_t = 5
info = Dict(
    "time" => map(i -> i, 1:(num_t + 1)),
    "shares" => [ς(s)],
    "price" => [v(s) / ς(s)],
    "feeRate" => rep(feerate, num_t + 1),
    "curatorAtrans" => [0.0],
    "curatorAmax" => [v̂maxs(cs[1], 1)],
    "curatorAmin" => [v̂mins(cs[1], 1)],
    "curatorAfees" => [0.0],
    "curatorAutility" => [0.0],
    "curatorAp" => [0.0],  # running sum of payments
    "curatorAshares" => [0.0],
    "curatorBtrans" => [0.0],
    "curatorBmax" => [v̂maxs(cs[2], 1)],
    "curatorBmin" => [v̂mins(cs[2], 1)],
    "curatorBfees" => [0.0],
    "curatorButility" => [0.0],
    "curatorBp" => [0.0],
    "curatorBshares" => [0.0],
    "curatorCtrans" => [0.0],
    "curatorCmax" => [v̂maxs(cs[3], 1)],
    "curatorCmin" => [v̂mins(cs[3], 1)],
    "curatorCfees" => [0.0],
    "curatorCutility" => [0.0],
    "curatorCp" => [0.0],
    "curatorCshares" => [0.0],
    "curatorDtrans" => [0.0],
    "curatorDmax" => [v̂maxs(cs[4], 1)],
    "curatorDmin" => [v̂mins(cs[4], 1)],
    "curatorDfees" => [0.0],
    "curatorDutility" => [0.0],
    "curatorDp" => [0.0],
    "curatorDshares" => [0.0],
    "curatorEtrans" => [0.0],
    "curatorEmax" => [v̂maxs(cs[5], 1)],
    "curatorEmin" => [v̂mins(cs[5], 1)],
    "curatorEfees" => [0.0],
    "curatorEutility" => [0.0],
    "curatorEp" => [0.0],
    "curatorEshares" => [0.0],
    "signal" => [v(s)],
)

# Now we run the following experiment.
# At each timestep, curators play a greedy strategy to try to maximise their utility.
# Also at each timestep, the subgraph's upper valuation increases by some fixed amount.
Δv = 100.0
for _ in 1:num_t
    ncs, ns = CurationEnvironment.step(m, πs, cs, s)
    for j in 1:num_c
        global info = logc(m, info, j, cs[j], ncs[j], ns)
        global ncs[j] = v̂maxs(ncs[j], id(ns), v̂maxs(ncs[j], id(ns)) + Δv)
        global ncs[j] = v̂mins(ncs[j], id(ns), v̂mins(ncs[j], id(ns)) + Δv)
    end
    push!(info["shares"], ς(ns))
    push!(info["price"], v(ns) / ς(ns))
    push!(info["signal"], v(ns))
    global cs = ncs
    global s = ns
end
@show v(s)

# Convert to a dataframe to view data
df = DataFrame(info)
CSV.write("assets/welfare_max_repeated.csv", df)
@show df

# You can download/inspect the [generated CSV](assets/welfare_max_repeated.csv) if you'd
# like.
# Similar to before, you can see that curator B ends up with all the stake.
# However, you can also see that, despite increasing v̂⁺, curator B does not decide to
# participate in the auction again unless v̂⁺ exceeds some value.
# This is because, by buying more shares, curator B is also diluting itself.
# Thus, the mechanism is not welfare maximising across auctions.
# However, since utility is always increasing, the mechanism does ensure that welfare
# does not decrease between auctions.
time = info["time"]
f = Figure()
ax = Axis(f[1, 1]; title="Welfare Max Multiple CSA", xlabel="time", ylabel="shares")
ax2 = Axis(f[2, 1]; title="Valuations", xlabel="time", ylabel="v̂⁺")
lines!(ax, time, info["curatorAshares"]; label="A")
lines!(ax, time, info["curatorBshares"]; label="B")
lines!(ax, time, info["curatorCshares"]; label="C")
lines!(ax, time, info["curatorDshares"]; label="D")
lines!(ax, time, info["curatorEshares"]; label="E")
lines!(ax2, time, info["curatorAmax"]; label="A")
lines!(ax2, time, info["curatorBmax"]; label="B")
lines!(ax2, time, info["curatorCmax"]; label="C")
lines!(ax2, time, info["curatorDmax"]; label="D")
lines!(ax2, time, info["curatorEmax"]; label="E")
axislegend(ax)
save("assets/welfare_max_repeated.png", f)
f
