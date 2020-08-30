# MSc Individual Project: Scalable Peer-to-Peer Value Store

An implementation of the Chord peer-to-peer protocol in Elixir. The code in this application is adapted
from the pseudocode and descriptions in the Chord
[paper](https://pdos.csail.mit.edu/papers/ton:chord/paper-ton.pdf).

## Installation

To run this program, first ensure that you have Elixir installed on your device.

Installation instructions for various Operating Systems can be found on the
[Elixir website](https://elixir-lang.org/install.html).

**N.B:** This project was developed using `v1.10` of Elixir. To avoid compatibility issues,
it is advisable to run the project with version `>=1.10` of Elixir.

## Downloading dependencies

Once you have confirmed that Elixir is installed, `cd` to the top level of the project directory
and run `mix deps.get` to download and install the necessary project dependencies.

## Running the test functions

The performance of this project's Chord implementation has been evaluated using two tests adapted from
test simulations carried out in the Chord paper. The tests adapted are measurements on load balancing
and path lengths of queries done in the network. Functions to run these tests can be found in
`lib/simulations/test_simulations.ex`. To run the tests, make sure you are in the root of the project
directory then run `iex -S mix` to enter the Elixir shell.

#### Load balance tests
To run this test, enter `TestSimulations.test_load_balance` in the Elixir shell. This will
run the load balance test as described in Section V.(B) of the Chord paper:
* A network of 10,000 nodes
* Test iterations with the total number of keys in the network varying in the range 100,000 to 1,000,000.
Increasing by 100,000 with each iteration.
* Each iteration is run 20 times.

The function can also be run with arguments to set a smaller key range as the default range takes
a significantly long time to run. The test duration to collect results for this project report for example
was 13 hours. For more details on the function arguments, enter `h TestSimulation.test_load_balance()` in
the Elixir shell. For example, enter `TestSimulation.test_load_balance(100000, 300000)` in the Elixir
shell to run iterations of the test in the range (100000-300000) with the increment staying as 100000.
Another example would be `TestSimulation.test_load_balance(100000, 200000, 10000)` which sets the range
to (100000-200000) incrementing iterations by 10000.

Test results will be saved to a file in the directory `lib/simulations/load_balance_results.txt`

#### Path length tests
To run this test, enter `TestSimulations.test_path_length` in the Elixir shell. This will
run the path length test as described in Section V.(C) of the Chord paper:
* A network of 2<sup>K</sup> nodes
* Test iterations with the total number of keys in the network being 100 X 2<sup>K</sup>.
* For each iteration, K is varied from 3 to 14. In the case of this project's test, the range is (3, 10)

The function can also be run with arguments to set a smaller K value.
For more details on the function arguments, enter `h TestSimulation.test_path_length` in
the Elixir shell. For example, enter `TestSimulation.test_path_length(3, 5)` in the Elixir
shell to run iterations of the test in the range 2<sup>3</sup> to 2<sup>5</sup>.

Test results will be saved to a file in the directory `lib/simulations/path_length_results.txt`

#### Running the tests outside iex
The functions can also be run without entering the Elixir shell for example: 
`elixir --detached -S mix run -e "TestSimulations.test_load_balance()"` (or with arguments passed in).
This will run the test in the background as it can take quite some time in the case of load balance tests
to complete. The `--detached` flag can be removed if you wish to run the tests in the foreground
although Log outputs were removed as they were too verbose during the long test runs.
