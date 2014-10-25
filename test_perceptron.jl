using Base.Test
include("perceptron.jl")

p = PerceptronParams([:a, :b, :c])
pf = init_fit(p)
@test pf.outcomes == [:a, :b, :c]
update_weights!(pf.weights, :a, ((:f1,1), (:f2,1)), 1)
@test pf.weights[:a][:f1] == 1
@test pf.weights[:a][:f2] == 1

data = [(:c, ((:f1,1), (:f2,1), (:f3,1))), (:b, ((:f3,1), (:f4,1), (:f5,1)))]
pf = train(p, [data[1]], 1, randomize_order=false)
@test pf.weights[:c][:f1] == 1
@test pf.weights[:c][:f2] == 1
@test pf.weights[:c][:f3] == 1
@test pf.weights[:b][:f3] == -1
@test pf.weights[:b][:f3] == -1
@test pf.weights[:b][:f3] == -1

pf = train(p, data, 1, randomize_order=false)
@test pf.weights[:b][:f4] == 1
@test pf.weights[:b][:f1] == -1
@test pf.weights[:b][:f3] == 0
@test pf.weights[:c][:f3] == 0

pf100 = train(p, data, 100, randomize_order=false)
@test pf100.weights == pf.weights

prediction = predict(pf, ((:f1,1), (:f2,1)))
@test prediction[:b] == -2.0
@test prediction[:c] == 2.0
@test classify(prediction) == :c

apf = train_averaged(p, data, 100)
@test -.1 < apf.weights[:c][:f3] < .1
@test -.1 < apf.weights[:b][:f3] < .1
