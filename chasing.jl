# change this to actual local git repo dir
cd("/home/xingyu/Cheetos") 

# precompile and usee the pkg
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Cheetos
chasing()