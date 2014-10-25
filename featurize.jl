using GraphUtil, ArcParse

function children_on_side(parse::Graph, index::Integer, cmp_fn::Function)
    edges = filter((edge) -> cmp_fn(edge[2], index), out_edges(parse, index))
    [edge[1] for edge in edges]
end

left_children(parse::Graph, index::Integer) = children_on_side(parse, index, <)
right_children(parse::Graph, index::Integer) = children_on_side(parse, index, >)

function featurize(state::StackParserState)
    stack = state.stack
    parse = state.graph
    buffer = state.buffer

    function get_stack_context(max_depth::Number, stack::(Integer...), field::Symbol)
        depth = min(max_depth, size(stack, 1))
        if depth < 1
            ["" for i in 1:max_depth]
        else
            padding = ["" for i in depth:(max_depth-1)]
            results = [getfield(parse.nodes[stack[end-i]], field) for i in 0:(depth-1)]
            append!(results, padding)
        end
    end

    function get_buffer_context(max_depth::Number, buffer::(Integer...), field::Symbol)
        depth = min(max_depth, size(buffer, 1))
        if depth < 1
            ["" for i in 1:max_depth]
        else
            padding = ["" for i in depth:(max_depth-1)]                
            results = [getfield(parse.nodes[buffer[i]], field) for i in 1:depth]
            append!(results, padding)
        end
    end

    function get_parse_context(word::Integer, deps, field::Symbol)
        if word == -1
            return 0, "", ""
        end
        valency = size(deps, 1)
        if valency == 0
            0, "", ""
        elseif valency == 1
            1, getfield(parse.nodes[deps[end]], field), ""
        else
            (2,
             getfield(parse.nodes[deps[end]], field),
             getfield(parse.nodes[deps[end-1]], field))
        end
    end

    features = Dict()
    # Set up the context pieces --- the word, W, and tag, T, of:
    # S0-2: Top three words on the stack
    # N0-2: First three words of the buffer
    # n0b1, n0b2: Two leftmost children of the first word of the buffer
    # s0b1, s0b2: Two leftmost children of the top word of the stack
    # s0f1, s0f2: Two rightmost children of the top word of the stack    

    s0 = size(stack, 1) == 0 ? -1 : stack[end]
    n0 = size(buffer, 1) == 0 ? -1 : buffer[end] #TODO check this is right

    Ws0, Ws1, Ws2 = get_stack_context(3, stack, :word)
    Ts0, Ts1, Ts2 = get_stack_context(3, stack, :pos)

    Wn0, Wn1, Wn2 = get_buffer_context(3, buffer, :word)
    Tn0, Tn1, Tn2 = get_buffer_context(3, buffer, :pos)

    Vn0b, Wn0b1, Wn0b2 = get_parse_context(n0, left_children(parse, n0), :word)
    Tn0b, Tn0b1, Tn0b2 = get_parse_context(n0, left_children(parse, n0), :pos)

    Vn0f, Wn0f1, Wn0f2 = get_parse_context(n0, right_children(parse, n0), :word)
    _, Tn0f1, Tn0f2 = get_parse_context(n0, right_children(parse, n0), :pos)

    Vs0b, Ws0b1, Ws0b2 = get_parse_context(s0, left_children(parse, n0), :word)
    _, Ts0b1, Ts0b2 = get_parse_context(s0, left_children(parse, n0), :pos)

    Vs0f, Ws0f1, Ws0f2 = get_parse_context(s0, right_children(parse, n0), :word)
    _, Ts0f1, Ts0f2 = get_parse_context(s0, right_children(parse, n0), :pos)

    # Cap numeric features at 5? 
    # String-distance
    Ds0n0 = s0 != 0 ? min(n0 - s0, 5) : 0 # potential dependency distance (cool!)

    features["bias"] = 1

    for w in (Wn0, Wn1, Wn2, Ws0, Ws1, Ws2, Wn0b1, Wn0b2, Ws0b1, Ws0b2, Ws0f1, Ws0f2)
        if w != ""
            features["w=$w"] = 1
        end
    end

    for t in (Tn0, Tn1, Tn2, Ts0, Ts1, Ts2, Tn0b1, Tn0b2, Ts0b1, Ts0b2, Ts0f1, Ts0f2)
        if t != ""
            features["t=$t"] = 1
        end
    end    

    for (i, (w,t)) in enumerate(((Wn0, Tn0), (Wn1, Tn1), (Wn2, Tn2), (Ws0, Ts0)))
        if w != "" || t != ""
            features["$i w=$w, t=$t"] = 1
            end
    end

    # Add some bigrams # TODO BELOW HERE
    features["s0w=$Ws0,  n0w=$Wn0"] = 1
    features["wn0tn0-ws0 $Wn0 $Tn0 $Ws0"] = 1
    features["wn0tn0-ts0 $Wn0 $Tn0 $Ws0"] = 1
    features["ws0ts0-wn0 $Ws0 $Ts0 $Wn0"] = 1
    features["ws0-ts0 tn0 $Ws0/$Ts0 $Tn0"] = 1
    features["wt-wt $Ws0/$Ts0 $Wn0/$Tn0"] = 1
    features["tt s0=$Ts0 n0=$Tn0"] = 1
    features["tt n0=$Tn0 n1=$Tn1"] = 1
 
    # Add some tag trigrams
    trigrams = ((Tn0, Tn1, Tn2), (Ts0, Tn0, Tn1), (Ts0, Ts1, Tn0), 
                (Ts0, Ts0f1, Tn0), (Ts0, Ts0f1, Tn0), (Ts0, Tn0, Tn0b1),
                (Ts0, Ts0b1, Ts0b2), (Ts0, Ts0f1, Ts0f2), (Tn0, Tn0b1, Tn0b2),
                (Ts0, Ts1, Ts1))
    for (i, (t1, t2, t3)) in enumerate(trigrams)
        if t1 != "" || t2 != "" || t3 != ""
            features["ttt-$i $t1 $t2 $t3"] = 1
        end
    end

    # Add some valency and distance features
    vw = ((Ws0, Vs0f), (Ws0, Vs0b), (Wn0, Vn0b))
    vt = ((Ts0, Vs0f), (Ts0, Vs0b), (Tn0, Vn0b))
    d = ((Ws0, Ds0n0), (Wn0, Ds0n0), (Ts0, Ds0n0), (Tn0, Ds0n0),
         ("t $Tn0 $Ts0", Ds0n0), ("w $Wn0 $Ws0", Ds0n0))
    for (i, (w_t, v_d)) in enumerate(tuple(vw..., vt..., d...))
        if w_t != "" || v_d != ""
            features["val/d-$i $w_t $v_d"] = 1
        end
    end

    tuple(features...)
end

