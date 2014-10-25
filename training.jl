using ArcParse

include("MyIterators.jl")
include("oracle.jl")
include("featurize.jl")
include("perceptron.jl")

function train_parser(params::ParserParameterization,
                      oracle_params::ParserParameterization,
                      featurize::Function,
                      data,
                      num_iterations::Int)
    fit = train_parser_classifier(oracle_params,
                                  data,
                                  featurize,
                                  num_iterations)
    score_next_ops(state::ParserState) = classify_withscores(fit, featurize(state))
    Parser(params, score_next_ops)
end

function greedy_oracle_moves(oracle_params::ParserParameterization,
                             data,
                             featurize::Function,
                             make_oracle_parser::Function)
    the_moves = Iterators.imap(data) do thing
        sentence, gold_parse = thing
        oracle_parser = make_oracle_parser(oracle_params, gold_parse)
        moves = greedy_moves(oracle_parser, sentence)
        filtered_moves = filter(move -> !is(move.op, done_op), moves)
        Iterators.imap(move -> (move.op, featurize(move.state)), filtered_moves)
    end
    Iterators.chain_from_iterable(the_moves)
end

function train_parser_classifier(oracle_params::ParserParameterization,
                                 data,
                                 featurize::Function,
                                 num_iterations::Int,
                                 make_oracle_parser::Function)
    the_moves = greedy_oracle_moves(oracle_params, data, featurize, make_oracle_parser)
    perceptron_params = PerceptronParams(collect(oracle_params.operations))
    train_averaged(perceptron_params, the_moves, num_iterations)
end

function train_parser_classifier(oracle_params::ParserParameterization,
                                 data,
                                 featurize::Function,
                                 num_iterations::Int)
    train_parser_classifier(oracle_params,
                            data,
                            featurize,
                            num_iterations,
                            make_deterministic_oracle_parser)
end

function exploratory_oracle_moves(oracle_params::ParserParameterization,
                                  parser::Parser,
                                  data,
                                  featurize::Function,
                                  k::Int,
                                  p::Real)
    the_moves = Iterators.imap(data) do thing
        sentence, gold_parse = thing
        oracle_parser = make_stochastic_oracle_parser(oracle_params, gold_parse)
        if i < k
            moves = greedy_moves(oracle_parser, sentence)
        else
            moves = exploratory_moves(parser,
                                      oracle_parser,
                                      sentence,
                                      p)
        end
        filtered_moves = filter(move -> !is(move.op, done_op), featurized_moves)        
        Iterators.imap(move -> (move.op, featurize(move.state)), filtered_moves)
    end
    Iterators.chain_from_iterable(the_moves)
end
    

function train_parser_classifier_with_exploration(oracle_params::ParserParameterization,
                                                  parser_params::ParserParameterization,
                                                  data,
                                                  featurize::Function,
                                                  num_iterations::Int,
                                                  k::Int,
                                                  p::Real)
    perceptron_params = PerceptronParams(collect(oracle_params.operations))
    fit = init_fit(perceptron_params)
    score_next_ops(state::ParserState) = classify_withscores(fit, featurize(state))
    regular_parser = Parser(parser_params, score_next_ops)
    moves = exploratory_oracle_moves(oracle_params, regular_parser, data, featurize, k, p)
    train_averaged!(fit, moves, num_iterations)
end
