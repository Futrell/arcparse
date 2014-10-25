module GraphUtil
import Base: start, next, done

using PushPop

export Graph, add_arc, out_edges, children, left_children, right_children, in_order_traversal

immutable Graph
    nodes::Dict{Integer, Any}
    arcs::Set{(Integer, Integer, Any)}
end

Graph(nodes::Dict) = Graph(nodes, Set{(Integer, Integer, Any)}()) # WTF?
Graph(nodes::Vector) = Graph(Dict(nodes)) # WTF?

add_arc(graph::Graph, arc::(Integer, Integer, Any)) = Graph(graph.nodes, union(graph.arcs, Set([arc])))

out_edges(graph::Graph, node::Integer) = filter((arc) -> arc[1] == node, graph.arcs)

function in_order_traversal(graph::Graph, node::Integer)
    result = Integer[]

    function traverse(node::Integer)
        map(traverse, left_children(graph, node))
        push!(result, node)
        map(traverse, right_children(graph, node))
    end

    traverse(node)
    return result
end

children(graph::Graph, node::Integer) = sort([node2 for (node1, node2, label) in out_edges(graph, node)])
left_children(graph::Graph, node::Integer) = filter(child_node -> child_node < node, children(graph, node))
right_children(graph::Graph, node::Integer) = filter(child_node -> child_node > node, children(graph, node))

    
end
