@testset "communitysignal" begin
    model = CommunitySignal()
    @testset "payment" begin
        @testset "direct method" begin
            # Example
            τ = 0
            x = 1 / 3
            v = 300
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p ≈ 150

            # Negative proportion, τ doesn't apply
            τ = 0
            x = -1 / 3
            v = 300
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p ≈ -100

            # If τ = 0 and I want half of the shares, I'll need to double the signal.
            τ = 0
            x = 0.5
            v = 100
            p = CurationEnvironment.payment(model, x, v, τ)
            @test p == 100

            # For equivalent τ, the more proportion I want, the more I'll need to pay.
            τ = 0.01
            v = 100
            xs = [0.25, 0.5, 0.75]
            ps = CurationEnvironment.payment.(model, xs, v, τ)
            @test issorted(ps)

            # As τ increases, the amount I'll need to pay for the same proportion increases.
            x = 0.5
            v = 100
            τs = [0.0, 0.01, 0.1, 0.5]
            ps = CurationEnvironment.payment.(model, x, v, τs)
            @test issorted(ps)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
            x = 0.5
            @test CurationEnvironment.payment(model, x, s) == 100
        end
    end

    @testset "equity_proportion" begin
        @testset "direct method" begin
            # If τ = 0, and I pay p, then I get back p / new market value
            τ = 0
            p = 100
            v = 100
            x = CurationEnvironment.equity_proportion(model, p, v, τ)
            @test x == 0.5

            # For equivalent τ, if I want greater proportion, I will need to pay more
            τ = 0.01
            v = 100
            ps = [50, 100, 150]
            xs = CurationEnvironment.equity_proportion.(model, ps, v, τ)
            @test issorted(xs)

            # As τ increases, the proportion I'll get for the same payment decreases.
            τs = [0.0, 0.01, 0.1, 0.5]
            v = 100
            p = 100
            xs = CurationEnvironment.equity_proportion.(model, p, v, τ)
            @test issorted(xs; rev=true)

            # Don't apply τ if buring tokens (p < 0)
            τs = [0.0, 0.01, 0.1, 0.5]
            v = 100
            p = -100
            xs = CurationEnvironment.equity_proportion.(model, p, v, τ)
            @test all(x -> x == xs[1], xs)
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
            p = 100
            @test CurationEnvironment.equity_proportion(model, p, s) == 0.5
        end
    end

    @testset "shares" begin
        @testset "direct method" begin
            # Example
            x = 1 / 3
            s = 300
            v = 300
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns ≈ 150

            # Negative proportion
            x = -1 / 3
            s = 300
            v = 300
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns ≈ -100

            # If you don't stake more, you don't mint new shares
            x = 0
            s = 100
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns == 0

            # As x increases, the number of shares minted increases
            xs = [0.25, 0.5, 0.75]
            s = 100
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares.(model, xs, s, v, τ)
            @test issorted(ns)

            # If s == 0, s -> p
            x = 0.5
            s = 0
            v = 100
            τ = 0.0
            ns = CurationEnvironment.shares(model, x, s, v, τ)
            @test ns == 100
        end

        @testset "domain model method" begin
            s = CurationEnvironment.Subgraph(1, 100.0, 1.0, 0.0)
            x = 0.0
            @test CurationEnvironment.shares(model, x, s) == 0
        end
    end

    @testset "curate" begin
        c = CurationEnvironment.Curator{1,Int64,Float64}(1, (100.0,), (0.0,), 100.0)
        s = CurationEnvironment.Subgraph(1, 1.0, 0.0, 0.0)
        p = 10

        c, s = CurationEnvironment.curate(model, p, c, s)
        @test ςs(c, 1) ≈ 10
        @test σ(c) == 90
    end

    @testset "best_response" begin
        @testset "MinMaxCurator" begin
            # best responses pushes v closer to vmax
            s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
            c = MinMaxCurator{1,Int64,Float64}(1, (100.0,), (150.0,), (0.0,), 100.0)
            popt = CurationEnvironment.best_response(model, c, s)
            @test popt ≈ √(150 * 100) - 100

            s = CurationEnvironment.Subgraph(1, 100.0, 0.0, 0.0)
            c = MinMaxCurator{1,Int64,Float64}(1, (50.0,), (150.0,), (0.0,), 100.0)
            popt = CurationEnvironment.best_response(model, c, s)
            @test popt ≈ √(150 * 100) - 100
        end
    end

    @testset "step" begin
        @testset "multiple curators" begin
            t = τ(0.05)
            π = best_response
            s = Subgraph(1, 500.0, 500.0, t)
            ca = MinMaxCurator{1,Int64,Float64}(1, (1000.0,), (2500.0,), (0.0,), 10000.0)
            cb = MinMaxCurator{1,Int64,Float64}(2, (500.0,), (4000.0,), (0.0,), 10000.0)
            cc = MinMaxCurator{1,Int64,Float64}(3, (1500.0,), (2000.0,), (0.0,), 10000.0)
            cd = MinMaxCurator{1,Int64,Float64}(4, (2750.0,), (3500.0,), (0.0,), 10000.0)
            ce = MinMaxCurator{1,Int64,Float64}(5, (0.0,), (3000.0,), (0.0,), 10000.0)
            cs = (ca, cb, cc, cd, ce)
            cs, ns = CurationEnvironment.step(model, π, cs, s)
            # The subgraph's signal should have increased
            @test v(s) < v(ns)
        end
    end

    @testset "latefees" begin
        # Only apply in the case when we're minting
        s = Subgraph(1, 500.0, 500.0, 0.05)
        fees = latefees(model, -100, s)
        @test fees == 0.0

        # Minting case
        fees = latefees(model, 0.1, 100.0, 0.05)
        @test fees == 0.5
    end

    @testset "utility" begin
        # Mint
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = 50.0
        u = utility(model, p, c, s)
        @test u ≈ 16 + 2 / 3

        # Pay less than v̂min
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = 10.0
        u = utility(model, p, c, s)
        @test u ≈ -Inf

        # The utility hinges around v̂max
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = 100.0
        u = utility(model, p, c, s)
        @test u == 0.0

        # Burn
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.5,), 10000.0)
        s = Subgraph(1, 200.0, 1.0, 0.0)
        p = -10
        u = utility(model, p, c, s)
        @test u ≈ -2000 / (190) + 10
    end

    @testset "popt" begin
        # γ⁺ case
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = CurationEnvironment.popt(
            model, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p ≈ √(100 * 200) - 100

        # optimal > σ
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = CurationEnvironment.popt(
            model, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p ≈ 10.0

        # when v = v̂max, don't curate
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 200.0, 1.0, 0.0)
        p = CurationEnvironment.popt(
            model, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p ≈ 0.0

        # burn
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.5,), 10000.0)
        s = Subgraph(1, 300.0, 1.0, 0.0)
        p = CurationEnvironment.popt(
            model, v(s), v̂mins(c, id(s)), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p ≈ √(300 * 200) - 300
    end

    @testset "pmax" begin
        # When τ is 0, just return v̂max - v
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = CurationEnvironment.pmax(
            model, v(s), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p == 100.0

        # optimal > σ
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10.0)
        s = Subgraph(1, 100.0, 1.0, 0.0)
        p = CurationEnvironment.pmax(
            model, v(s), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p == 10.0

        # If v > v̂max, return 0
        c = MinMaxCurator{1,Int64,Float64}(1, (125.0,), (200.0,), (0.0,), 10000.0)
        s = Subgraph(1, 300.0, 1.0, 0.0)
        p = CurationEnvironment.pmax(
            model, v(s), v̂maxs(c, id(s)), τ(s), ςs(c, id(s)) / ς(s), σ(c)
        )
        @test p == 0.0
    end
end
