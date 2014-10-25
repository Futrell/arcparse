using Base.Test

using ArcParse
import ArcEager

parser = ArcParse.MockParser(ArcEager.parameterization)

moves = greedy_moves(parser, "the cat sat on the mat")
state1 = start(moves)
@test state1.parser_state.stack == (0,)
@test state1.parser_state.buffer == (1, 2, 3, 4, 5, 6) 

move1, state2 = next(moves, state1)
@test move1.op == ArcEager.RightArc(:no_label)
@test move1.score == 2
@test move1.state.stack == state1.parser_state.stack
@test move1.state.buffer == state1.parser_state.buffer

move2, state3 = next(moves, state2)
@test move2.op == ArcEager.RightArc(:no_label)
@test move2.score == 2
@test move2.state.stack == state2.parser_state.stack
@test move2.state.buffer == state2.parser_state.buffer

parse = greedy_parse(parser, "the cat sat on the mat")
@test (0, 1, :no_label) in parse.arcs

