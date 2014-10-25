immutable PerceptronParams
    outcomes::Array
end

immutable PerceptronFit
    outcomes::Array
    weights::Dict
end

function init_fit(parameters::PerceptronParams)
    PerceptronFit(parameters.outcomes,
                  [outcome=>Dict{Any,Float64}() for outcome in parameters.outcomes])
end

function train(perceptron::PerceptronParams,
               data,
               num_iterations::Int;
               randomize_order=true)
    fit = init_fit(perceptron)
    train!(fit, data, num_iterations, randomize_order=randomize_order)
end

function train!(fit::PerceptronFit,
                data,
                num_iterations::Int;
                randomize_order=true)
    for i in 1:num_iterations
        train_on_trials!(fit, randomize_order ? shuffle(data) : data)
    end
    fit
end


function train_averaged(perceptron::PerceptronParams,
                        data,
                        num_iterations::Int)
    fit = init_fit(perceptron)
    train_averaged!(fit, data, num_iterations)
end

function train_averaged!(fit::PerceptronFit,
                         data,
                         num_iterations::Int)
    cached_weights = deepcopy(fit.weights)
    c = 1
    for i in 1:num_iterations
        for (correct_outcome, features) in shuffle(collect(data))
            guess = classify(fit, features)
            if guess != correct_outcome
                update_weights!(fit.weights, guess, features, -1) 
                update_weights!(fit.weights, correct_outcome, features, +1)
                update_weights!(cached_weights, guess, features, -c)
                update_weights!(cached_weights, correct_outcome, features, +c)
            end
            c += 1
        end
    end

    for (outcome, outcome_weights) in fit.weights
        for (feature_name, weight) in outcome_weights
            correction = cached_weights[outcome][feature_name] / c
            outcome_weights[feature_name] = weight - correction
        end
    end
    fit
end
    
function train_on_trials!(fit::PerceptronFit, data)
    for (correct_outcome, features) in data
        train_on_trial!(fit, features, correct_outcome)
    end
    fit
end

function train_on_trial!(fit::PerceptronFit, features, correct_outcome)
    guess = classify(predict(fit, features))
    if guess != correct_outcome
        update_weights!(fit.weights, guess, features, -1)
        update_weights!(fit.weights, correct_outcome, features, +1)
    end
    fit
end

function update_weights!(weights::Dict,
                         outcome,
                         features,
                         delta::Number)
    for (feature_name, feature_value) in features
        if !haskey(weights[outcome], feature_name)
            weights[outcome][feature_name] = feature_value*delta 
        else
            weights[outcome][feature_name] += feature_value*delta
        end
    end
    weights
end
        
function predict(fit::PerceptronFit, features)
    preds = [outcome=>0.0 for outcome in fit.outcomes]
    for (feature_name, feature_value) in features
        for outcome in fit.outcomes
            if haskey(fit.weights[outcome], feature_name)
                preds[outcome] += feature_value*fit.weights[outcome][feature_name]
            end
        end
    end
    preds
end

second(x) = x[2]

function classify_withscore(predictions::Dict{Any, Float64})
    first(classify_withscores(predictions)) # consistent with classifier API?
end

function classify_withscores(predictions::Dict{Any, Float64})
    sort(map(reverse, predictions), by=first, rev=true)
end

function classify_withscores(fit::PerceptronFit, features)
    classify_withscores(predict(fit, features))
end

classify(predictions::Dict) = second(classify_withscore(predictions))
classify(fit::PerceptronFit, features) = classify(predict(fit, features))
