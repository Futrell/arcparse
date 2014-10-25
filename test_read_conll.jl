using Base.Test

include("read_conll.jl")

stuff = read_conll("finnish.conll")
x = first(stuff)
@test size(x, 1) == 2
@test first(x).morph == "pos=noun|number=sing|case=nom"
@test first(x).id == 1
@test first(x).arc_label == :root

sentence = stuff[2]
parsed = conll_sentence_parse(sentence, arc_labels=true)
@test in((3,8,:obj), parsed.arcs)
@test in((5,7,:conj), parsed.arcs)
@test in((8,5,:amod), parsed.arcs)
@test in((3,10,:punct), parsed.arcs)
@test in((3,2,:nsubj), parsed.arcs)
@test in((5,6,:cc), parsed.arcs)
@test in((2,1,:nmod), parsed.arcs)
@test in((0,3,:root), parsed.arcs)
@test in((3,4,:advmod), parsed.arcs)
@test in((8,9,:nmod), parsed.arcs)
