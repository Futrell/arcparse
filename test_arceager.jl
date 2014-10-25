using Base.Test

using GraphUtil
using ArcParse
import ArcEager
include("visualize.jl")
include("oracle.jl")

sentence = "he wrote her a letter ."
gold_parse = init_parse(preprocess(sentence))
gold_arcs = [(0, 2, :no_label),
             (2, 1, :no_label),
             (2, 3, :no_label),
             (2, 5, :no_label),
             (2, 6, :no_label),
             (5, 4, :no_label)]

for arc in gold_arcs
    gold_parse = add_arc(gold_parse, arc)
end

op = make_oracle_parser(ArcEager.static_oracle_parameterization,
                        gold_parse)

moves = greedy_moves(op, sentence)
lmoves = collect(moves)

@test lmoves[1].op == ArcEager.Shift()
@test lmoves[2].op == ArcEager.LeftArc()
@test lmoves[3].op == ArcEager.RightArc()
@test lmoves[4].op == ArcEager.RightArc()
@test lmoves[8].op == ArcEager.RightArc()
@test lmoves[9].op == ArcEager.Reduce()
@test lmoves[10].op == ArcEager.RightArc()

@test gold_parse.arcs == last(lmoves).state.graph.arcs
