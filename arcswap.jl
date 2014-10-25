# Arc Swap system from Nivre (2009)
module ArcSwap
using PushPop, GraphUtil, ArcParse
import Memoize: @memoize

export parameterization, static_oracle_parameterization

const State = StackParserState

preconditions(op, state::State) = true
oracle_preconditions(op, state::State, gold::Graph) = true

immutable LeftArc <: ParserOperation
    arc_label::Symbol
end

LeftArc() = LeftArc(:no_label)

function do_op(op::LeftArc, state::State)
    j = last(state.stack)
    i = state.stack[end-1]
    State(add_arc(state.graph, (j, i, op.arc_label)),
          state.buffer,
          tuple(state.stack[1:(end-2)]..., j))
end

function preconditions(op::LeftArc, state::State)
    if length(state.stack) < 2
        return false
    end
    i = state.stack[end-1]
    i != 0
end

function oracle_preconditions(op::LeftArc, state::State, gold::Graph)
    if length(state.stack) < 2
        return false
    end
    j = last(state.stack)
    i = state.stack[end-1]
    ((j, i, op.arc_label) in gold.arcs
     && all(arc -> arc in state.graph.arcs,
            filter(arc -> arc[1] == i, gold.arcs)))
end


immutable RightArc <: ParserOperation
    arc_label::Symbol
end

RightArc() = RightArc(:no_label)

function do_op(op::RightArc, state::State)
    j = last(state.stack)
    i = state.stack[end-1]
    State(add_arc(state.graph, (i, j, op.arc_label)),
          state.buffer,
          butlast(state.stack))
end

preconditions(op::RightArc, state::State) = length(state.stack) >= 2

function oracle_preconditions(op::RightArc, state::State, gold::Graph)
    if length(state.stack) < 2
        return false
    end
    j = last(state.stack)
    i = state.stack[end-1]    
    ((i, j, op.arc_label) in gold.arcs
     && all(arc -> arc in state.graph.arcs,
            filter(arc -> arc[1] == j, gold.arcs)))
end


immutable Shift <: ParserOperation
end

function do_op(op::Shift, state::State)
    i = first(state.buffer)
    State(state.graph,
          butfirst(state.buffer),
          push(state.stack, i))
end

preconditions(op::Shift, state::State) = !isempty(state.buffer)
oracle_preconditions(op::Shift, state::State, gold::Graph) = !isempty(state.buffer)


immutable Swap <: ParserOperation
end

function do_op(op::Swap, state::State)
    j = last(state.stack)
    i = state.stack[end-1]
    State(state.graph,
          unshift(state.buffer, i),
          tuple(state.stack[1:(end-2)]..., j))
end

function preconditions(op::Swap, state::State)
    if length(state.stack) < 2
        return false
    end
    j = last(state.stack)
    i = state.stack[end-1]
    0 < i < j
end

function oracle_preconditions(op::Swap, state::State, gold::Graph)
    if length(state.stack) < 2
        return false
    end
    j = last(state.stack)
    i = state.stack[end-1]
    projective_order = get_projective_order(gold)
    findfirst(projective_order, j) < findfirst(projective_order, i)
end

@memoize function get_projective_order(graph::Graph)
    in_order_traversal(graph, 0)
end

halt(state::State) = isempty(state.buffer) && state.stack == (0,)

operations = (LeftArc(), RightArc(), Swap(), Shift())
parameterization = ParserParameterization(State,
                                          operations,
                                          do_op,
                                          preconditions,
                                          halt)
static_oracle_parameterization = ParserParameterization(State,
                                                        operations,
                                                        do_op,
                                                        oracle_preconditions,
                                                        halt)


end
