# benchmark_engine
A minetest mod for benchmarking ingame.

Use the "/benchmark" command to run a benchmark.

## adding benchmarks
To add benchmarks use `benchmark.register`.  
First argument to the function is the id in the form "modname:benchmarkname".  
The second argument is the defintion of the benchmark containing:  
* "before" the function to run before each cycle
* "run" the function to run and measure each cycle
* "warmup" how many times this should be run for warming up the jitter.
* "loops" how many times this should be run to measure the average.
