module ArcEager
using PushPop, GraphUtil, ArcParse

export parameterization, static_oracle_parameterization, dynamic_oracle_parameterization

const State = StackParserState

preconditions(op, state::State) = true
oracle_preconditions(op, state::State, gold::Graph) = true
dynamic_oracle_preconditions(op, state::State, gold::Graph) = true

immutable LeftArc <: ParserOperation
    arc_label::Symbol
end

LeftArc() = LeftArc(:no_label)

function do_op(op::LeftArc, state::State)
    i = last(state.stack)
    j = first(state.buffer)
    State(add_arc(state.graph, (j, i, op.arc_label)),
          state.buffer,
          butlast(state.stack))
end

function preconditions(op::LeftArc, state::State)
    if isempty(state.stack)
        return false
    end
    i = last(state.stack)
    i != 0 && !any((arc) -> arc[2] == i, state.graph.arcs)
end

function oracle_preconditions(op::LeftArc, state::State, gold::Graph)
    if isempty(state.stack) || isempty(state.buffer)
        return false
    end
    i = last(state.stack)
    j = first(state.buffer)
    (j, i, op.arc_label) in gold.arcs
end

function dynamic_oracle_preconditions(op::LeftArc, state::State, gold::Graph)
    if isempty(state.stack) || isempty(state.buffer)
        return false
    end
    s = last(state.stack)
    b = first(state.buffer)
    any((k) -> (k, s, op.arc_label) in gold.arcs
        || (s, k, op.arc_label) in gold.arcs,
        state.buffer)
end

immutable RightArc <: ParserOperation
    arc_label::Symbol
end


RightArc() = RightArc(:no_label)

function do_op(op::RightArc, state::State)
    i = last(state.stack)
    j = first(state.buffer)
    State(add_arc(state.graph, (i, j, op.arc_label)),
          shift(state.buffer)[2],
          push(state.stack, j))
end

# Goldberg and Nivre (2012) have no preconditions for RightArc
#function preconditions(op::RightArc, state::State)
#    j = first(state.buffer)
#    !isempty(state.stack) && !any((arc) -> arc[2] == j, state.graph.arcs)
#end

function oracle_preconditions(op::RightArc, state::State, gold::Graph)
    if isempty(state.stack) || isempty(state.buffer)
        return false
    end    
    i = last(state.stack)
    j = first(state.buffer)
    (i, j, op.arc_label) in gold.arcs
end

function dynamic_oracle_preconditions(op::RightArc, state::State, gold::Graph)
    if isempty(state.buffer)
        return false
    end    
    b = first(state.buffer)
    (any((k) -> (k, b, op.arc_label) in gold.arcs,
         filter((k) -> k in state.stack, state.buffer))
     || any((k) -> (b, k, op.arc_label) in gold.arcs,
            state.stack))
end


immutable Shift <: ParserOperation
end

function do_op(op::Shift, state::State)
    i = first(state.buffer)
    State(state.graph,
          butfirst(state.buffer),
          push(state.stack, i))
end

function dynamic_oracle_preconditions(op::Shift, state::State, gold::Graph)
    if isempty(state.buffer)
        return false
    end        
    b = first(state.buffer)
    (any((k) -> (k, b, op.arc_label) in gold.arcs, state.stack)
     || any((k) -> (b, k, op.arc_label) in gold_arcs, state.stack))
end


immutable Reduce <: ParserOperation
end

function do_op(op::Reduce, state::State)
    State(state.graph,
          state.buffer,
          butlast(state.stack))
end

function preconditions(op::Reduce, state::State)
    if isempty(state.stack)
        return false
    end        
    i = last(state.stack)
    any((arc) -> arc[2] == i, state.graph.arcs)
end

function oracle_preconditions(op::Reduce, state::State, gold::Graph)
    if isempty(state.buffer)
        return false
    end
    i = last(state.stack)    
    j = first(state.buffer)
    any((k) -> any((arc) -> ((arc[1]==k && arc[2]==j) || (arc[1]==j && arc[2]==k)),
                             gold.arcs),
         0:(i-1))
end

function dynamic_oracle_preconditions(op::Reduce, state::State, gold::Graph)
    if isempty(state.stack)
        return false
    end
    b = first(state.buffer)
    any((k) -> (s, k, op.arc_label) in gold.arcs, state.buffer)
end

halt(state::State) = isempty(state.buffer)

operations = (LeftArc(), RightArc(), Reduce(), Shift())

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

dynamic_oracle_parameterization = ParserParameterization(State,
                                                         operations,
                                                         do_op,
                                                         dynamic_oracle_preconditions,
                                                         halt)

end




