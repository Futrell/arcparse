using Base.Test

include("training.jl")
include("read_conll.jl")
include("featurize.jl")
include("perceptron.jl")

import ArcSwap

to_word(word::ConllWord) = Word(word.word, string(word.pos))

data = map(read_conll_gold_parses("latin.conll", arc_labels=false)) do thing
    sentence, gold_parse = thing
    map(to_word, sentence), gold_parse
end;

tp = train_parser(ArcSwap.parameterization,
                  ArcSwap.static_oracle_parameterization,
                  featurize,
                  data,
                  1)

dtp = train_parser(ArcSwap.parameterization,
                   ArcSwap.dynamic_oracle_parameterization,
                   featurize,
                   data,
                   1)
                   
