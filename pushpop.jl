module PushPop

export push, butlast, pop, unshift, butfirst, shift

push{T}(stack::(T...), thing::T) = tuple(stack..., thing)
push(stack::(), thing) = tuple(thing...)
butlast{T}(stack::(T...)) = stack[1:(end-1)]
pop{T}(stack::(T...)) = last(stack), butlast(stack)

unshift{T}(stack::(T...), thing::T) = tuple(thing, stack...)
unshift(stack::(), thing) = tuple(thing...)
butfirst{T}(stack::(T...)) = stack[2:end]
shift{T}(stack::(T...)) = first(stack), butfirst(stack)

end
