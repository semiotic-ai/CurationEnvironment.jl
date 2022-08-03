# ---
# title: Welfare Maximisation in the Community Signal Model
# id: cs_wm
# date: 2022-08-03
# author: "[Anirudh Patel](https://github.com/anirudh2)"
# julia: 1.7
# description: This experiment investigates whether the Community Signal model is welfare-maximising.
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
Random.seed!(seed)

using CurationEnvironment
using Accessors

# Constants
const feerate = 0.05
const t = τ(feerate)
const num_t = 150  # timesteps
const m = CommunitySignal()
const num_s = 1  # subgraphs
const num_c = 5  # curators
const π = best_response

# Create the curators and subgraph
# In this experiment, the curators have unlimited budget.
# We can make this assumption due to signal renting.
const v̂lows = (1000.0, 500.0, 1500.0, 1750.0, 0.0)
const v̂highs = (2500.0, 4000.0, 2000.0, 2000.0, 3500.0, 3000.0)
const shares = (0.0, 0.0, 0.0, 0.0, 0.0)
const stakes = (10000.0, 10000.0, 10000.0, 10000.0, 10000.0)
cs = map(1:num_c, v̂lows, v̂highs, shares, stakes)  do i, vl, vh, ς, σ
        return MinMaxCurator{num_s,Int64,Float64}(i, (vl,), (vh,), (ς,), σ)
    end
s = Subgraph(1, 500.0, 500.0, t)

# We can look at the generated curators
@show cs

# And the generated subgraph
@show s

# Now we run the following experiment.
# At each timestep, curators play a greedy strategy to try to maximise their utility.
# We see at the end of this if the curator who values the subgraph the most owns all the
# new shares on the subgraph. Note that since we start with 500 shares on the subgraph,
# they won't own all the shares on the subgraph. Since the curators all have unlimited
# budgets, if the mechanism is welfare-maximising, we shouldn't have multiple curators
# curating the subgraph at the end of the this process.
is = collect(1:num_c)
for _ in 1:num_t
    i = rand(is)
    c = cs[i]
    nc, ns = CurationEnvironment.step(m, π, c, s)
    global cs = @set cs[i] = nc
    global s = ns
end
