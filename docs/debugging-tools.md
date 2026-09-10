# High level Chisel debugging

## The problem with debugging of high level HDLs

When you want to test if a circuit functions as intended, you run simulations of the circuit. You apply values to the inputs, wait for the required time (in cycles), and then check if the output signals contain the expected values. Apart from testing the values in code, the waveform viewer is usually your best friend as a hardware designer. The Surfer waveform viewer is a modern, cross platform application that we will use in our experiments.

When you add your signals to the viewport and inspect them, you will notice that the variable names are not exactly the same as in your source code, that the signal hierarchy is gone (apart from the `_` characters in the names), and that the waveform viewer renders all multi-bit signals as hexadecimal. This is because the simulation does not simulate your source code, it simulates the Verilog or VHDL that it generates *from* your source code. Since this low level code does not have the same expressive power as the source language and several optimizations are applied during compilation.

This results in that the inspection and debugging experience not only does not live up to what you would expect from a higher level language, but also is far inferior to even "normal" Verilog/VHDL simulation with commercial tools. For this purpose, we built tooling to lift the experience to source level debugging.

## Tywaves & ChiselTrace example circuits

The repository contains various example circuits in the `sample-circuits`, taken from the `examples` folder of the [Tywaves-Chisel](https://github.com/jarlb/tywaves-chisel) repository. These example circuits are meant to showcase features and advantages of source level debugging.

## Simulation a Chisel circuit
You can run the examples with `scala-cli` like so:

```sh
scala-cli test sample-circuits/circuit_name.scala
```

> [!TIP]
> You can safely ignore any errors about unused imports and warnings/hints about packages that can be updated.

In the source code of the examples, three different simulator classes are used:
- The built-in Chisel `ParametricSimulator`, will simulate the circuit and save a `vcd` file without launching Surfer or using the type metadata.
- Tywaves' `TywavesSimulator`, will, after simulation, launch Surfer with tywaves enabled.
- The `ChiselTraceDebugger`. In the basis the same as the `TywavesSimulator`, but with the added functionality that when a signal's value does not match the one specified in the `.expect()` call, the simulation process will prompt you whether you want to start a dependency trace from that signal.

Some circuits will have the one simulator class, and some the other. Feel free to exchange the class.

When simulating circuits with Chisel and ChiselTrace, the waveform file is dumped in `test_run_dir/<ComponentName>/<Simulator>/<test_name>/trace.vcd`, where `ComponentName` will be the name of the top level component that you are simulating, `Simulator` one of the three mentioned simulators, and `test_name` the description of the unit test.

The *first step* will be to open the waveform in Surfer, without special Tywaves handling. In the `vcd` file, the component (called `dut`) is wrapped in the scopes `TOP` and `svsimTestbench`. The top level component does not retain its name here, it gets set to `dut` (after device under test), but any nested components do. By selecting this component or its nested components, you can add the signals (called variables in Surfer) to the waveform by clicking on them.

In the bare `vcd` display, by default, any signal that contains more than 1 bit gets displayed in hexadecimal format. You can select the signals in the waveform panel, right click, and set the format to unsigned, signed, binary, etc. Compound signals such as bundles or vectors get split up in different signals for each leaf during compilation. They are recognisable by the `_` characters in the signal name.


## Running Tywaves
With [Tywaves](https://github.com/rameloni/tywaves-chisel) enabled, the additional metadata generated during compilation is used to improve the situation. The signal display type gets set automatically. Compound signals get reconstructed and can be added to the waveform in one go, displayed as collapsible tree structures, instead of needing to add all leaf signals individually.

Tywaves will automatically be launched when the `TywavesSimulator` or `ChiselTraceDebugger` is used. In some cases, Surfer gets launched *before* the entire `vcd` file has been flushed, and the displayed waveform is incomplete. The window must then be closed and Surfer launched manually. Launching Surfer and just openeing the `vcd` file will not automatically augment the data with Tywaves, because the program does not know where the debug info is located. The full command to achieve this is a bit complicated due to the paths, so a helper script has been provided to set the correct paths automatically. Therefore, Surfer with Tywaves can be ran with a convenience script
```bash
./invoke-surfer <Component name>
```
Where the component name is the one specified in the source code as the device under test, e.g. `GCD`.

The full command to run Surfer with Tywaves for GCD's test is
```bash
surfer-tywaves ./test_run_dir/GCD/ChiselTraceDebugger/runs_GCD_correctly_launch_tywaves/trace.vcd --hgldd-dir test_run_dir/tmpModule/ChiselTraceDebugger/hgldd/debug --extra-scopes TOP svsimTestbench dut --top-module GCD
```

As explained before, the VCD path depends on the top module and the name of the test. The convenience script selects the most recent test in the folder. Note that this means that your argument should match the most recent executed test!

> [!NOTE]
> If Surfer prints its startup log but never opens a window, and you are on Linux with Docker Desktop, the container cannot reach your screen. See [GUI apps on Linux with Docker Desktop](../README.md#gui-apps-on-linux-with-docker-desktop) in the README, or switch to the VNC container flavour.

## ChiselTrace / SigTrail
If, in the development of the circuit, a problem is detected, either manually or by a failed assertion, [ChiselTrace](https://github.com/jarlb/chiseltrace) can be used to find out where an erroneous value comes from. The front-end has been renamed to SigTrail to support different languages as well, such as SpinalHDL. The compilation pass and debugger class are still called ChiselTrace. ChiselTrace uses the same metadata as Tywaves, in combination with extra metadata about which signals are used in assignments and conditionals. When the ChiselTrace application launches, you are presented with a graph that starts from the criterion node that was specified (in the command, or automatically by the ChiselTrace debugger at an assertion error). The graph flows from left (end of simulation) to right (`t=0`). A line from a node/vertice `A` to another node/vertice `B` indicates that signal `A` depends on signal `B`.

> [!TIP]
> The window can be scrolled sideways. If scrolling does not work for some reason, try holding the `shift` button while scrolling.

Different parts of the graph are styled differently to convey what they indicate. The legend is as follows:

- Blue elliptical node/vertice: a normal signal, e.g. `val mySignal = Wire(Uint(8.W))`
- Green rectangular node/vertice: an IO input signal, e.g. `val myInput = IO(Input(Uint(8.W)))`
- Blue line/edge: a standard dependency, e.g. `mySignal := myInput`
- Purple line/edge: an indexing dependency, e.g. `myOutput := someMemory(readAddress)`
- Red diamond node/vertice and line/edge: a conditional/control flow dependency and its expression, e.g. `when(myInput) { ... }`

When a node is hovered, it shows the related line in the Chisel source code of the circuit and the incoming and outgoing dependency edges. Nodes can be dragged around to improve the overview of the relationships. You can right click a node to make that node the new criterion and hide any dependent nodes after it. This can be reset by right clicking the background and selecting “Reset graph”.

> Note that the button “Show in VS Code” does not work, as VS Code is not installed within the container.

### Running ChiselTrace
ChiselTrace can be launched from the simulation if a failing `.expect()` call is encountered. The terminal will ask what to do after encoutering the failed assertion. To start ChiselTrace, type `dt` (for **d**ynamic **t**race) when prompted. For a succesful simulation, it will not offer this. You can still launch ChiselTrace using the command line. Again, the full command to do this is a bit complicated due to the paths, so a helper script has been provided to set the correct paths automatically. Simply run
```bash
# Script             <TOP_MODULE> <SLICE_CRITERION> [--log] [extra_arguments...]
./invoke-chiseltrace GCD signal:io.result
```

The full command to run ChiselTrace is like:
```bash
chiseltrace --slice-criterion signal:io.result --pdg-path ./pdg.json --vcd-path ./test_run_dir/GCD/ChiselTraceDebugger/runs_GCD_correctly_launch_tywaves/trace.vcd --hgldd-path ./test_run_dir/tmpModule/ChiselTraceDebugger/hgldd/debug --top-module GCD --extra-scopes TOP svsimTestbench dut --max-timesteps 16
```

The `vcd-path` depends on the top module and the name of the test. The convenience script selects the most recent test in the folder. The slice critereon can be a signal or statement. You likely want to have some `signal:io.result` or `signal:io.out`, or whatever you want to look at, based on the circuit that you are simulating.

## Chiselwatt

The docker container image contains a prepared clone of our group’s fork of the Chiselwatt open source POWER ISA processor ([see repository](https://github.com/jarlb/chiselwatt/)). This clone, and thus the code, lives in `/usr/src/chiselwatt` within the container. In that directory you can run the following command to execute the simulation of the Chiselwatt core with a simple program. Execution, after downloading dependencies and compiling scala code, is around a minute.

```bash
cd /usr/src/chiselwatt
sbt "testOnly *CoreTest"
```

The Scala unit test code corresponding to this test is the file `/usr/src/chiselwatt/src/test/scala/Core.scala`. The fault in the code will result in an assertion error getting triggered: `Assertion failed. Context: Expectation failed: observed value 9 != 8` through the line `c.io.adderOut.expect(8.U)`. Because of this the CLI prompts you asking to launch ChiselTrace to find the fault. You may need to scroll up to see it, as the logging from the Surfer waveform viewer starting after the simulation occludes it.

Once you confirm starting the dependency tracing analysis by typing `dt` (for “dynamic trace”), you will be presented with the waveform and the ChiselTrace program. The signal node that forms the start of the trace is `connect_io.adderOut`, connecting with value `9` to `connect_io.out`.

From this point, try to find where the fault originates from. You can right click on nodes to make them the new head. This will hide all dependency paths before that node. This can be undone with right clicking and selecting *reset graph*.

> Note that the button “Show in VS Code” does not work, as VS Code is not installed within the container.
> 

The code that gets executed on the core is as follows:

```nasm
.section ".text"
.global main

main:
    ; Set up test values
    li      3, 0b0101
    li      4, 0b0011

    ; THE FAULTY INSTRUCTION (should XOR but does OR)
    xor     5, 3, 4    ; Expected: 0b0110 (6)

    addi    6, 5, 2    ; Expected: 6+2=8

    ; Freeze state for inspection
    blr
```

Written in a more abstracted way, it does the following:

```nasm
R3 = 5
R4 = 3
R5 = R3 ^ R4 ; 5 ^ 3 = 0b0101 ^ 0b0011 = 0b0110 = 6
R6 = R5 + 2  ; 6 + 2 = 8 -> the expected value at c.io.adderOut
```

The system comprises of a lot of different software components. They are related like this:

```mermaid
graph LR
    %% Central Demo
    Chiselwatt["**Chiselwatt**<br>Demo"]

    %% First level dependencies from Demo
    ChiselTrace["**ChiselTrace**<br>Signal dependency GUI"]
    surfer["**surfer**<br>Waveform viewer"]
    tywaves-chisel["**tywaves-chisel**<br>Adds Tywaves simulator"]

    Chiselwatt --> ChiselTrace
    Chiselwatt --> surfer
    Chiselwatt --> tywaves-chisel

    %% Mid-level dependencies
    chiseltrace-rs["**chiseltrace-rs**<br>Signal dependency library"]
    tywaves-rs["**tywaves-rs**<br>Signal value translation library"]
    chisel["**chisel**<br>HDL library"]

    ChiselTrace --> chiseltrace-rs
    surfer --> tywaves-rs
    tywaves-chisel --> chisel

    %% Cross-connections
    chiseltrace-rs --> tywaves-rs

    %% Core tools & low-level dependencies
    wellen["**wellen**<br>VCD loader"]
    circt["**circt**<br>FIRRTL → Verilog compiler"]
    Verilator["**Verilator**<br>Verilog simulator"]

    tywaves-rs --> wellen
    chisel --> circt
    
    %% Bottom paths to Verilator
    chisel --> Verilator
    tywaves-chisel --> Verilator

    %% Styling to make it look clean
    classDef demo fill:#b3b3ff,stroke:#8c8cff,stroke-width:2px,color:#000;
    classDef component fill:#ffe57f,stroke:#ffd54f,stroke-width:2px,color:#000;
    
    class Chiselwatt demo;
    class ChiselTrace,surfer,tywaves-chisel,chiseltrace-rs,tywaves-rs,chisel,wellen,circt,Verilator component;
```