using SafeTestsets

files = readdir()
filter!(f -> contains(f, ".jl") && f ≠ "runtests.jl", files)
include.(files)
