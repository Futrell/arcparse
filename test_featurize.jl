using Base.Test

using ArcParse
using ArcEager

include("featurize.jl")

mp = ArcParse.MockParser(ArcEager.parameterization)
state1 = start(greedy_moves(mp, "the cat sat"))
features = featurize(state1.parser_state)
features = Dict(zip(features...)...)
feature_keys = Set(keys(features))
@test all((x) -> isa(x, String), feature_keys)
@test "4 w=*root*, t=*root*" in feature_keys
@test "w=sat" in feature_keys
@test "val/d-6  0" in feature_keys
@test "s0w=*root*,  n0w=the" in feature_keys
@test all((x) -> isa(x, Integer), values(features))




