using Base.Test

using GraphUtil
using ArcParse
import ArcSwap
include("visualize.jl")
include("oracle.jl")

sentence = "a meeting is scheduled on the issue today ."
gold_parse = init_parse(preprocess(sentence))
gold_arcs = [(0, 3, :no_label),
             (2, 1, :no_label),
             (3, 2, :no_label),
             (3, 4, :no_label),
             (2, 5, :no_label),
             (5, 7, :no_label),
             (7, 6, :no_label),
             (3, 8, :no_label),
             (3, 9, :no_label)]

for arc in gold_arcs
    gold_parse = add_arc(gold_parse, arc)
end

op = make_oracle_parser(ArcSwap.static_oracle_parameterization,
                        gold_parse)

moves = greedy_moves(op, sentence)
lmoves = collect(moves)

@test last(lmoves).state.graph.arcs == gold_parse.arcs

@test lmoves[1].op == ArcSwap.Shift()
@test lmoves[2].op == ArcSwap.Shift()
@test lmoves[3].op == ArcSwap.LeftArc()
@test lmoves[4].op == ArcSwap.Shift()
@test lmoves[5].op == ArcSwap.Shift()

include("read_conll.jl")
to_word(word::ConllWord) = Word(word.word, string(word.pos))
function test_oracle_correct(sentence, gold_parse)
    op = make_oracle_parser(ArcSwap.static_oracle_parameterization,
                            gold_parse)
    parse = greedy_parse(op, sentence)
    parse.arcs == gold_parse.arcs
end    

latin = read_conll_gold_parses("latin.conll")
latin = [(map(to_word, words), parse) for (words, parse) in latin]
@test all(thing -> test_oracle_correct(thing[1], thing[2]), latin)

finnish = read_conll_gold_parses("finnish.conll")
finnish = [(map(to_word, words), parse) for (words, parse) in finnish]
@test all((thing) -> test_oracle_correct(thing[1], thing[2]), finnish)
