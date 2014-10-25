using GraphUtil

const ID, WORD, LEMMA, POS, POS2, MORPH, HEAD, ARC_LABEL = 1:8

immutable ConllWord
    id::Integer
    word::String
    lemma::String
    pos::Symbol
    pos2::Symbol
    morph::String
    head::Integer
    arc_label::Symbol
end

function ConllWord(parts::Array)
    ConllWord(int(parts[ID]),
              parts[WORD],
              parts[LEMMA],
              symbol(parts[POS]),
              symbol(parts[POS2]),
              parts[MORPH],
              int(parts[HEAD]),
              symbol(parts[ARC_LABEL]))
end

function read_conll(filename::String)
    sentences = Array{ConllWord}[]
    open(filename, "r") do f
        sentence = ConllWord[]
        for line in eachline(f)
            parts = split(strip(line))
            if size(parts, 1) == 0
                push!(sentences, sentence)
                sentence = ConllWord[]
                continue
            end
            word = ConllWord(parts)
            push!(sentence, word)
        end
    end
    sentences
end

function conll_sentence_parse(sentence::Array{ConllWord, 1}; arc_labels=false)
    parse = Graph(Dict([(word.id, word) for word in sentence]))
    for word in sentence
        arc = (word.head, word.id, arc_labels ? word.arc_label : :no_label)
        parse = add_arc(parse, arc)
    end
    parse
end

function read_conll_gold_parses(filename::String; arc_labels=false)
    sentences = read_conll(filename)
    map((sentence) -> (sentence, conll_sentence_parse(sentence, arc_labels=arc_labels)),
        sentences)
end
