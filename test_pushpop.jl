using Base.Test

using PushPop

@test push((1, 2, 3), 4) == (1, 2, 3, 4)
@test pop((1, 2, 3)) == (3,(1,2))
@test unshift((1, 2, 3), 4) == (4, 1, 2, 3)
@test shift((1, 2, 3)) == (1,(2,3))
