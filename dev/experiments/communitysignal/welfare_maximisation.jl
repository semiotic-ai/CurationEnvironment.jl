const seed = 343
using Random
Random.seed!(seed)

using CurationEnvironment
using Accessors

const feerate = 0.05
const t = τ(feerate)
const num_t = 150  # timesteps
const m = CommunitySignal()
const num_s = 1  # subgraphs
const num_c = 5  # curators
const π = best_response

const v̂lows = (1000.0, 500.0, 1500.0, 1750.0, 0.0)
const v̂highs = (2500.0, 4000.0, 2000.0, 2000.0, 3500.0, 3000.0)
const shares = (0.0, 0.0, 0.0, 0.0, 0.0)
const stakes = (10000.0, 10000.0, 10000.0, 10000.0, 10000.0)
cs = map(1:num_c, v̂lows, v̂highs, shares, stakes)  do i, vl, vh, ς, σ
        return MinMaxCurator{num_s,Int64,Float64}(i, (vl,), (vh,), (ς,), σ)
    end
s = Subgraph(1, 500.0, 500.0, t)

@show cs

@show s

is = collect(1:num_c)
for _ in 1:num_t
    i = rand(is)
    c = cs[i]
    nc, ns = CurationEnvironment.step(m, π, c, s)
    global cs = @set cs[i] = nc
    global s = ns
end

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

