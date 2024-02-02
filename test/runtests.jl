using SafeTestsets

files = readdir()
filter!(f -> f ≠ "runtests.jl", files)
include.(files)