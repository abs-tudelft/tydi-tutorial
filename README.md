# Tydi tutorial
This repository contains all the tools and educational ematerial and code to learn about and get started with the Tydi tools and ecosystem.

## What is the Tydi ecosystem?
The Tydi ecosystem encompasses several software tools, a communication standard, and an ideology.

### Early history
Development on "Tydi" started out with the development of [Fletcher](https://github.com/abs-tudelft/fletcher), a framework to stream in-memory Apache Arrow data from host into FPGA and back. Fletcher, as an interface generator, had to support the various data-structures that could be used with Apache Arrow. This flexibility offers a lot of potential, but is hard to realize. The team became aware that a sufficiently powerful data streaming mechanism was missing on the FPGA side of things. This prompted the development of the Tydi protocol.

### Tydi protocol
The **Ty**ped **D**ataflow **I**nterface, or Tydi for short, is an inter-module data streaming interface specification that is designed to offer the same maturity for defining complex component interfaces, as modern HSL paradigms provide for building the components. Its multi-tiered specification is HDL agnostic. It provides
1. A Type system for defining complex, variable data structures
2. Formally verified data transmission methodology
3. Interface HDL generators for Chisel, VHDL, Verilog, etc
4. Engineering parameters to fine-tune that interface

### Debug tools
From the development of integrations of the Tydi protocol with its nested compound types in various host languages grew the need for better tools to view and interpret simulation results of developed RTL.
One issue with higher level HDLs is that they often compile down to Verilog or VHDL for simulation. This gives the problem that the values of the simulation output do not carry the exact same structure and naming as in your original design. For this reason **Tywaves** was developed. Tywaves allows reconstruction of the original higher level types from low level simulation data using type metadata. This gives better overview in the waveform viewer, but will not give any insights into where errors in the circuit's output originate from in your design on its own. For this purpose, a signal tracing methodology was developed. By creating a Control Flow Graph (CFG) from a circuit and gather all signal dependencies (static and dynamic from muxes and indexing), a Program Dependency Graph (PDG) can be constructed of the circuit. Combined with the simulation data, a Dynamic PDG (DPDG) kan be assembled, giving exact insight into *which branches were taken* and *which statements were activated* with *which values* in each clock cycle. This was first developed in Chisel with the name **ChiselTrace**. It is now being implemented in more host languages, prompting a rename of the front end to **SigTrail**.

### Idiology for open hardware
We believe that with open interface specifications and open source tooling, the hardware comunity can achieve more than the sum of the parts. A component with a clear specification of its interface in a protocol that is flexible enough to accomodate for most data types and behaviors will not require hacks and reverse engineering to integrate into your own design. A collection of parameterizable open source components with such interface descriptions will allow creating designs *by composition*. The debug tools help accomodate this flexibility by allow representation of it in the simulation results and find errors faster.

By creating open standards for communication and circuit debug metadata, building integrations in different HDLs and workflows will become much easier, and more people can enjoy the benefits. This open source effort will lower barier-to-entry, increase resilience, and create sovereignty.

## What will you learn?
In this tutorial, you will learn
- How the Tydi protocol works
    - How complex data structures are mapped to Tydi types
    - How to build a Tydi interface
    - What engineering parameters are available for customization
    - How data packets are processed and sent over the interface step by step according to the Tydi formalism
- Source level debugging for high level languages (focus on Chisel)
    - Understand the problem with the RTL source – Verilog divide for simulation
    - How extra signal type metadata kept through circuit compilation steps enables reconstruction of the source representation of compound signals and enums from the Verilog simulation data
    - How program slicing works and can enable tracing down faults in the RTL design
    - How to use Surfer-Tywaves and SigTrail to do this for a few example circuits
- Our vision for the future of hardware design

## Getting started
Get started by cloning the repo. Then, open the project in an IDE. For this tutorial we will assume [VS Code](https://code.visualstudio.com/).
```sh
# Clone repo
git clone --recurse-submodules https://github.com/abs-tudelft/tydi-tutorial.git
# Open in VS Code
cd tydi-tutorial
code .
```

This repository contains a project with development container that you can be used in VS Code. With this set-up, you can easily write and edit code, and execute the tools of the Tydi ecosystem on those files. Once you cloned the project and opened the folder in VS Code, the dev container will be detected and a notification will ask if you want to reopen the folder in the dev container. If you say yes, a pop-up will ask you *which* container you want, see details below to make a choice. When you open the project in the dev ctonainer, the files will live in the container, and the terminal will execute commands within the container, meaning that all CLI tools are available.

### Choosing a container flavour

Two flavours of the container are provided, and VS Code will let you pick one when you reopen the folder in a container (`Dev Containers: Reopen in Container`). To switch flavours later, run `Dev Containers: Reopen in Container` again and select the other one.

- **Tydi-Tools (VNC desktop)** – [`.devcontainer/vnc`](.devcontainer/vnc/devcontainer.json). Recommended for beginners and macOS users. In addition to the CLI tools, it runs a lightweight XFCE desktop environment, exposed as a browser-based noVNC interface on http://localhost:6080/vnc.html. This may be more intuitive for some users. The resolution of this virtual desktop may be changed with the `DESKTOP_RESOLUTION` variable in its `devcontainer.json`.
- **Tydi-Tools (CLI only)** – [`.devcontainer/cli`](.devcontainer/cli/devcontainer.json). The same CLI tools, without the desktop and noVNC server. GUI apps may still work when launched from the terminal. It works well on Linux, acceptable but a bit less smoothly on Windows, macOS needs an X11 server.

> [!NOTE]
> On Windows, starting the dev container may fail if WSL integration is not enabled in the Docker desktop settings (see Resources tab). An alternate solution may be turning off "Mount Wayland Socket" in VS Code's settings.

Documenation on the container may be found on its [Docker Hub page](https://hub.docker.com/r/hdltypetech/tydi-tools), or its [GitHub repository](https://github.com/abs-tudelft/Tydi-tools).

## Instructions
TODO: Put well-structured, easy to follow instructions here.

## Resources

Here are some resources you can check out to get more information about Tydi, Tydi development tools, and the debug tools.

- [Tydi and tools documentation](https://abs-tudelft.github.io/docs/)
- [Tydi stream visualizer web application](https://abs-tudelft.github.io/tydi-stream-vis/)
- [List of Tydi-related publications](https://hdltypetech.com/publications/)
- A mostly up to date list of tools and projects:
    - [Tydi stream visualizer](https://github.com/abs-tudelft/tydi-stream-vis) – Aforementioned web application to build Tydi structures from JSON input data and visualize the streams and packets
    - [TinyTydi](https://gitlab.com/hstruik/tinytydi) – A simulator of transfer building of Tydi streams using formal semantics
    - [Tydi-Chisel](https://github.com/abs-tudelft/Tydi-Chisel) – The Scala library for integrating Tydi concepts inside Chisel
    - [Tywaves](https://github.com/rameloni/tywaves-chisel) – Type-enabled waveform viewing for Chisel
    - [ChiselTrace](https://github.com/jarlb/chiseltrace) – Signal dependency tracing for Chisel designs
    - [Tydi-lang](https://github.com/twoentartian/tydi-lang-2) – Tydi-lang compiler
    - [Tydi-lang-2-Chisel](https://github.com/ccromjongh/tydi-lang-2-chisel) – A Tydi-lang-IR to Chisel transpiler
    - [TIL-JSON](https://github.com/jhaenen/JSON_hierachy) – A tool for automatically generating a JSON to Tydi streams parser  
    _Note: not actively maintained anymore_
    - [TIL](https://github.com/matthijsr/til-vhdl) – The Tydi Intermediate Representation to VHDL compiler  
    _Note: not actively maintained anymore_

## Tywaves & ChiselTrace example circuits

The `sample-circuits` folder contains example circuits taken from the examples folder of the [Tywaves-Chisel](https://github.com/jarlb/tywaves-chisel) repository. You can run the examples with `scala-cli` like so:

```sh
scala-cli test sample-circuits/circuit_name.scala
```

> [!TIP]
> You can safely ignore any errors about unused imports and warnings/hints about packages that can be updated.

Three different simulator classes are used:
- The built-in Chisel `ParametricSimulator`, will simulate the circuit and save a `vcd` file without launching Surfer or using the type metadata.
- Tywaves' `TywavesSimulator`, will, after simulation, launch Surfer with tywaves enabled.
- The `ChiselTraceDebugger`. When a signal's value does not match the one specified in the `.expect()` call, the simulation process will prompt you whether you want to start a dependency trace from that signal.

Some circuits will have the one simulator class, and some the other. Feel free to exchange the class.

### Running Tywaves
Tywaves will automatically be launched when the `TywavesSimulator` or `ChiselTraceDebugger` is used. Opening Surfer, it will not automatically augment the data with Tywaves, because the program does not know where the debug info is located.

The full command to do this is a bit complicated due to the paths, so a helper script has been provided to set the correct paths automatically. Therefore, it can be ran with a convenience script
```bash
./invoke-surfer GCD
```

The full command to run Surfer with Tywaves for a certain test is
```bash
surfer-tywaves ./test_run_dir/GCD/ChiselTraceDebugger/runs_GCD_correctly_launch_tywaves/trace.vcd --hgldd-dir test_run_dir/tmpModule/ChiselTraceDebugger/hgldd/debug --extra-scopes TOP svsimTestbench dut --top-module GCD
```

The VCD path depends on the top module and the name of the test. The convenience script selects the most recent test in the folder.

### Running ChiselTrace
ChiselTrace can be launched from the simulation if a failing `.expect()` call is encountered. For a succesful simulation, it will not offer this. You can still launch ChiselTrace using the command line. Again, the full command to do this is a bit complicated due to the paths, so a helper script has been provided to set the correct paths automatically. Simply run
```bash
# Script             <TOP_MODULE> <SLICE_CRITERION> [--log] [extra_arguments...]
./invoke-chiseltrace GCD signal:io.result
```

The full command to run ChiselTrace is like:
```bash
chiseltrace --slice-criterion signal:io.result --pdg-path ./pdg.json --vcd-path ./test_run_dir/GCD/ChiselTraceDebugger/runs_GCD_correctly_launch_tywaves/trace.vcd --hgldd-path ./test_run_dir/tmpModule/ChiselTraceDebugger/hgldd/debug --top-module GCD --extra-scopes TOP svsimTestbench dut --max-timesteps 16
```

The `vcd-path` depends on the top module and the name of the test. The convenience script selects the most recent test in the folder. The slice critereon can be a signal or statement. You likely want to have some `signal:io.result` or `signal:io.out`, or whatever you want to look at, based on the circuit that you are simulating.

## TinyTydi: from a JSON document to a Tydi interface

[TinyTydi](https://gitlab.com/hstruik/tinytydi) is included as a submodule in
`tinytydi/`. It runs the Tydi formalism as an executable semantics: it reads a
JSON document, infers the logical type it implies, normalises it, maps the
document's own data onto stream transfers, and elaborates a Chisel interface
that is checked cycle for cycle against that result.

Clone with submodules, or fetch them afterwards:

```sh
git clone --recurse-submodules git@github.com:abs-tudelft/tydi-tutorial.git
# or, in an existing clone:
git submodule update --init tinytydi
```

The dev container runs `.devcontainer/bootstrap.sh` on creation, which checks
the submodule out and builds the stimulus bundles the Chisel tests read. Those
bundles are generated, not committed, so run that script by hand if you skipped
the container.

This repository's own `tydi-material/chat-messages/chat-messages.json` is the
worked example:

```sh
python3 tinytydi/main.py json tydi-material/chat-messages/chat-messages.json --type-only
```

It maps to `Dim(Group(Bits(64), Dim(Group(Bits(32), Bits(16), Bits(16), Dim(Dim(Bits(8)))))))`
and normalises to three physical streams: the chat id, a 64-bit payload packing
`timestamp`, `message_id` and `user_id` together, and the message characters at
dimension 4. Then:

```sh
cd tinytydi/hdl
scala-cli test .          # elaborate per bundle, check against the semantics
./invoke-surfer chatmsgs  # open the waveform
```

`tydi-material/student-example/student.json` is deliberately *not* accepted:
its `"study_end": null` is an optional, which is a `Union` of the value and
nothing, and `Union` is outside the fragment TinyTydi implements. The error
names the path that caused it.

> [!NOTE]
> `tinytydi/hdl/invoke-surfer` is not the `invoke-surfer` in this repository's
> root. The root script drives the ChiselTrace sample circuits; the TinyTydi one
> takes a bundle name and reports whether Tywaves type information was found.

### From a JSON document to characters on a waveform

The whole path, on any document you like. Four commands, and the only one that
takes real time is the third.

```sh
cd tinytydi

# 1. what type does the document imply? Three physical streams, and the message
#    text ends up as 8-bit elements at dimension 4.
./main.py json ../tydi-material/chat-messages/chat-messages.json --type-only

# 2. turn it into a stimulus bundle: the parameters the circuit is elaborated
#    from, the elements themselves, and the cycle-by-cycle trace to check against
./main.py export --json ../tydi-material/chat-messages/chat-messages.json \
                 --lanes 1,2,4 --out hdl/bundles/chatmsgs

# 3. elaborate the interface for that type and simulate it (about 20 s warm)
cd hdl && scala-cli test .

# 4. open the waveform with the characters already on it
./invoke-surfer chatmsgs --chars
```

Step 4 prints `Tywaves: on (typed hgldd: ...)` before it opens anything. If it
says anything else, the waveform will still open but the types will not be
there, and the line says which of the two reasons applies.

**Then one click in the viewer.** The rows are loaded but they are numbers:
right-click a `value` row → Format → **ASCII** to read them as characters.
Nothing on the command line can preselect a format, so this step cannot be
automated away.

Expand `outStream_2` and you are looking at the thing the formalism describes:
four character lanes filling up, `strb` and `endi` marking how many of them
carry data in this transfer, and `last(i)` closing dimensions — one bit per
dimension, so a lane that ends a word sets bit 0, a lane that ends a message
sets bits 0 and 1, and so on outwards. `in_2` above it shows the element side
one character per cycle, and `_state_output` below is the parse FSM: one bit per
node of the normalised type, all of them set on the cycle `fullMap` fires.

The same works for any accepted document — `./main.py export --json yours.json
--lanes 1,2,4 --out hdl/bundles/yours`, then `scala-cli test .` picks the new
bundle up on its own, because every directory under `bundles/` is a test case.

`tinytydi/hdl/README.md` has the longer version: which signals to add and why,
and why a trace of an eight-node type contains 285 of them.
