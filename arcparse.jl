module ArcParse
import GraphUtil: Graph

export Word, root_word, Parser, ParserState, StackParserState, ListParserState, ParserOperation, ParserParameterization, greedy_moves, greedy_parse, MockParser, init_parse, preprocess, done_op

function last_in_iterable(iterable)
    local thing
    for thing in iterable
    end
    thing
end    

immutable Word # how to make this flexible?
    word::String
    pos::String
end

Word(word::String) = Word(word, "")

function ==(w1::Word, w2::Word)
    w1.word == w2.word && w1.pos == w2.pos
end

const root_word = Word("*root*", "*root*")

abstract ParserOperation

immutable DoneOp <: ParserOperation
end

const done_op = DoneOp()

# Why are these different?

immutable ParserParameterization
    init_state::DataType
    operations::(ParserOperation...)
    do_op::Function
    preconditions::Function
    halting_condition::Function
end

immutable Parser
    init_state::DataType
    do_op::Function
    preconditions::Function
    score_next_ops::Function
    halting_condition::Function
end

function Parser(params::ParserParameterization, score_next_ops::Function)
    Parser(params.init_state,
           params.do_op,
           params.preconditions,
           score_next_ops,
           params.halting_condition)
end

abstract ParserState

immutable StackParserState <: ParserState
    graph::Graph
    buffer::(Int...,)
    stack::(Int...,)
end

function StackParserState(sentence)
    StackParserState(init_parse(sentence),
                     tuple([i for (i,_) in sentence[2:end]]...),
                     (0,))
end

immutable ListParserState <: ParserState
    graph::Graph
    buffer::(Int...,)
    list1::(Int...,)
    list2::(Int...,)
end

function ListParserState(sentence)
    ListParserState(init_parse(sentence),
                    tuple([i for (i,_) in sentence[2:end]]...),
                    (0,),
                    ())
end

immutable ParserMove
    op::ParserOperation
    state::ParserState
    score::Number
end

init_parse(sentence::Vector) = Graph(sentence)

function preprocess(sentence::String)
    words = map(Word, split(sentence))
    preprocess(words)
end

function preprocess(sentence::Vector)
    enumerated = collect(enumerate(sentence))
    unshift!(enumerated, (0, root_word))
end

abstract ParserMoveIterator

immutable GreedyParserMoveIterator <: ParserMoveIterator
    parser::Parser
    sentence::Vector
end

abstract ParserIteratorState

immutable DoneState <: ParserIteratorState
end

const done_state = DoneState()


immutable GreedyParserIteratorState <: ParserIteratorState
    parser_state::ParserState
end

function greedy_moves(parser::Parser, sentence)
    GreedyParserMoveIterator(parser, preprocess(sentence))
end

function choose_next_op(it::GreedyParserMoveIterator,
                        state::GreedyParserIteratorState)
    pstate = state.parser_state
    scored_ops = it.parser.score_next_ops(pstate)
    filtered_ops = filter((op) -> it.parser.preconditions(op[2], pstate),
                          scored_ops)
    if isempty(filtered_ops)
        error("Could not choose next operation because none are possible.")
    end
    first(filtered_ops)
end

function do_next_op(it::ParserMoveIterator,
                    op::ParserOperation,
                    state::ParserIteratorState)
    GreedyParserIteratorState(it.parser.do_op(op, state.parser_state)) # careful!
end
    

function Base.start(it::GreedyParserMoveIterator)
    GreedyParserIteratorState(it.parser.init_state(it.sentence))
end

function Base.next(it::ParserMoveIterator,
                   state::ParserIteratorState)
    if it.parser.halting_condition(state.parser_state)
        ParserMove(done_op, state.parser_state, 0), done_state
    else
        score, op = choose_next_op(it, state)
        ParserMove(op, state.parser_state, score), do_next_op(it, op, state)
    end
end

function Base.done(it::ParserMoveIterator,
                   state::ParserIteratorState)
    state === done_state
end

immutable ExploratoryParserMoveIterator <: ParserMoveIterator
    it1::GreedyParserMoveIterator
    it2::GreedyParserMoveIterator
    sentence::Vector
    p::Real
end

function exploratory_moves(parser1, parser2, sentence, p::Real)
    it1 = greedy_moves(parser1, sentence)
    it2 = greedy_moves(parser2, sentence)
    ExploratoryParserMoveIterator(it1, it2, sentence, p)
end

function Base.start(it::ExploratoryParserMoveIterator) 
    GreedyParserIteratorState(it.it1.parser.init_state(it.sentence))
end

function choose_next_op(it::ExploratoryParserMoveIterator,
                        state::GreedyParserIteratorState)
    choose_next_op(rand() < it.p ? it.it1 : it.it2, state)
end


function greedy_parse(parser::Parser, sentence)
    last_move = last_in_iterable(greedy_moves(parser, sentence))
    last_move.state.graph
end

function MockParser(params::ParserParameterization)
    mock_next_ops(state::ParserState) = enumerate(params.operations)
    Parser(params, mock_next_ops)
end

end
