# This is meant to test the infrastructure for oracles, not the correctness
# of any particular oracle. 

using Base.Test

using GraphUtil
using ArcParse
import ArcEager

include("oracle.jl")

# Arc-eager static oracle example from Goldberg & Nivre (2012)

