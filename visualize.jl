import Base.show

import ArcParse

function Base.show(io::IO, move::ArcParse.ParserMove)
    op = move.op
    print(io, move.state)
    print(io, "Next op: $op\n")    
end

function Base.show(io::IO, state::ArcParse.StackParserState)
    buffer = join([state.graph.nodes[i].word for i in state.buffer], " ")
    stack = join([state.graph.nodes[i].word for i in state.stack], " ")
    if !isempty(state.graph.arcs)
        heads, deps, arc_labels = zip(state.graph.arcs...)   
        heads = join([state.graph.nodes[i].word for i in heads], "\t")
        deps = join([state.graph.nodes[i].word for i in deps], "\t")
        arc_labels = join(arc_labels, "\t")
    else
        heads = ""
        deps = ""
        arc_labels = ""
    end
    print(io, "Buffer: $buffer\nStack: $stack\nArcs: $heads\n      $deps\n      $arc_labels\n")
end

function Base.show(io::IO, state::ArcParse.ListParserState)
    buffer = join([state.graph.nodes[i].word for i in state.buffer], " ")
    list1 = join([state.graph.nodes[i].word for i in state.list1], " ")
    list2 = join([state.graph.nodes[i].word for i in state.list2], " ")    
    if !isempty(state.graph.arcs)
        heads, deps, arc_labels = zip(state.graph.arcs...)   
        heads = join([state.graph.nodes[i].word for i in heads], "\t")
        deps = join([state.graph.nodes[i].word for i in deps], "\t")
        arc_labels = join(arc_labels, "\t")
    else
        heads = ""
        deps = ""
        arc_labels = ""
    end
    print(io, "Buffer: $buffer\nList 1: $list1\nList 2: $list2\nArcs: $heads\n      $deps\n      $arc_labels\n")
end
    
