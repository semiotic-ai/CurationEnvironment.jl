# ---
# title: Welfare Maximisation in the Community Signal Model
# cover: assets/welfare_max.png
# id: cs_wm
# date: 2022-08-03
# author: "[Anirudh Patel](https://github.com/anirudh2)"
# julia: 1.7
# description: This experiment investigates whether the Community Signal model is welfare-maximising. TL;DR - Failed.
# ---

# Welfare maximisation is defined as in the
# [Curation v2](https://www.overleaf.com/read/hfymjbjmzwvf) yellowpaper.
# The main idea is that a welfare-maximising state is one in which curators that value
# subgraph most own the shares and the minimum viable signal is met for all curators
# Generally speaking, as we shall see, there exist equilibria for the Community Signal (CS)
# model of curation that are not welfare-maximising.

# Seed for reproducibility
const seed = 343
using Random
rng = MersenneTwister(seed)

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
    return d
end

function logc(m, d, i, c)
    texnames = ["A", "B", "C", "D", "E"]
    name = texnames[i]
    push!(d["curator$(name)trans"], d["curator$(name)trans"][end])
    push!(d["curator$(name)utility"], d["curator$(name)utility"][end])
    push!(d["curator$(name)fees"], d["curator$(name)fees"][end])
    push!(d["curator$(name)p"], d["curator$(name)p"][end])
    push!(d["curator$(name)shares"], d["curator$(name)shares"][end])
    return d
end

# Constants
const feerate = 0.05
const t = τ(feerate)
const num_t = 50  # timesteps
const m = CommunitySignal()
const num_s = 1  # subgraphs
const num_c = 5  # curators
const π = best_response

# Create the curators and subgraph
# In this experiment, the curators have unlimited budget.
# We can make this assumption due to signal renting.
const v̂lows = (1000.0, 500.0, 1500.0, 1750.0, 0.0)
const v̂highs = (2500.0, 4000.0, 2000.0, 3500.0, 3000.0)
const shares = (0.0, 0.0, 0.0, 0.0, 0.0)
const stakes = (10000.0, 10000.0, 10000.0, 10000.0, 10000.0)
cs = map(1:num_c, v̂lows, v̂highs, shares, stakes) do i, vl, vh, ς, σ
    return MinMaxCurator{num_s,Int64,Float64}(i, (vl,), (vh,), (ς,), σ)
end
s = Subgraph(1, 500.0, 500.0, t)

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
    "curatorAmax" => rep(v̂maxs(cs[1], 1), num_t + 1),
    "curatorAmin" => rep(v̂mins(cs[1], 1), num_t + 1),
    "curatorAfees" => [0.0],
    "curatorAutility" => [0.0],
    "curatorAp" => [0.0],  # running sum of payments
    "curatorAshares" => [0.0],
    "curatorBtrans" => [0.0],
    "curatorBmax" => rep(v̂maxs(cs[2], 1), num_t + 1),
    "curatorBmin" => rep(v̂mins(cs[2], 1), num_t + 1),
    "curatorBfees" => [0.0],
    "curatorButility" => [0.0],
    "curatorBp" => [0.0],
    "curatorBshares" => [0.0],
    "curatorCtrans" => [0.0],
    "curatorCmax" => rep(v̂maxs(cs[3], 1), num_t + 1),
    "curatorCmin" => rep(v̂mins(cs[3], 1), num_t + 1),
    "curatorCfees" => [0.0],
    "curatorCutility" => [0.0],
    "curatorCp" => [0.0],
    "curatorCshares" => [0.0],
    "curatorDtrans" => [0.0],
    "curatorDmax" => rep(v̂maxs(cs[4], 1), num_t + 1),
    "curatorDmin" => rep(v̂mins(cs[4], 1), num_t + 1),
    "curatorDfees" => [0.0],
    "curatorDutility" => [0.0],
    "curatorDp" => [0.0],
    "curatorDshares" => [0.0],
    "curatorEtrans" => [0.0],
    "curatorEmax" => rep(v̂maxs(cs[5], 1), num_t + 1),
    "curatorEmin" => rep(v̂mins(cs[5], 1), num_t + 1),
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
is = collect(1:num_c)
for _ in 1:num_t
    i = rand(rng, is)
    c = cs[i]
    nc, ns = CurationEnvironment.step(m, π, c, s)
    global info = logc(m, info, i, c, nc, ns)
    js = filter(j -> j != i, is)
    for j in js
        global info = logc(m, info, j, cs[j])
    end
    push!(info["shares"], ς(ns))
    push!(info["price"], v(ns) / ς(ns))
    push!(info["signal"], v(ns))
    global cs = @set cs[i] = nc
    global s = ns
end
@show v(s)

# Convert to a dataframe to view data
df = DataFrame(info)
CSV.write("assets/welfare_max.csv", df)
@show df

# You can download/inspect the [generated CSV](assets/welfare_max.csv) if you'd like.
# In any case, we can see that the mechanism is not welfare-maximising in this case.
# Curator B (2) did not end up with all of the new shares on the subgraph.
time = info["time"]
f = Figure()
ax = Axis(f[1, 1]; title="Welfare Max CS", xlabel="time", ylabel="shares")
lines!(ax, time, info["curatorAshares"]; label="A")
lines!(ax, time, info["curatorBshares"]; label="B")
lines!(ax, time, info["curatorCshares"]; label="C")
lines!(ax, time, info["curatorDshares"]; label="D")
lines!(ax, time, info["curatorEshares"]; label="E")
axislegend(ax)
save("assets/welfare_max.png", f)
f
