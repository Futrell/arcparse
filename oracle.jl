import Base

using GraphUtil
using ArcParse

function make_oracle_parser(params::ParserParameterization,
                            gold_parse::Graph,
                            score_next_ops::Function)
    function oracle_preconditions(op::ParserOperation, state::ParserState)
        params.preconditions(op, state, gold_parse)
    end
    
    Parser(params.init_state,
           params.do_op,
           oracle_preconditions,
           score_next_ops,
           params.halting_condition)
end

function make_deterministic_oracle_parser(params::ParserParameterization,
                                          gold_parse::Graph)
    score_next_ops(state::ParserState) = enumerate(params.operations)
    make_oracle_parser(params, gold_parse, score_next_ops)
end

function make_stochastic_oracle_parser(params::ParserParameterization,
                                       gold_parse::Graph)
    score_next_ops(state::ParserState) = zip(rand(length(params.operations)),
                                             params.operations)
    make_oracle_parser(params, gold_parse, score_next_ops)
end

function make_oracle_parser(params::ParserParameterization,
                            gold_parse::Graph)
    make_deterministic_oracle_parser(params, gold_parse)
end
