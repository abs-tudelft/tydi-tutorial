# Tydi tutorial

This repository contains a project with development container that you can open in VS Code. With this set-up, you can easily write and edit code, and execute the tools of the Tydi ecosystem on those files. Once you clone the project and open the folder in VS Code, it will detect the dev container, and ask if you want to reopen the folder in the dev container. If you do this, the files will live in the container, and the terminal will execute commands within the container, meaning that all CLI tools are available.

### Choosing a container flavour

Two flavours of the container are provided, and VS Code will let you pick one when you reopen the folder in a container (`Dev Containers: Reopen in Container`). To switch flavours later, run `Dev Containers: Reopen in Container` again and select the other one.

- **Tydi-Tools (VNC desktop)** – [`.devcontainer/vnc`](.devcontainer/vnc/devcontainer.json). Recommended for beginners and macOS users. In addition to the CLI tools, it runs a lightweight XFCE desktop environment, exposed as a browser-based noVNC interface on http://localhost:6080/vnc.html. This may be more intuitive for some users. The resolution of this virtual desktop may be changed with the `DESKTOP_RESOLUTION` variable in its `devcontainer.json`.
- **Tydi-Tools (CLI only)** – [`.devcontainer/cli`](.devcontainer/cli/devcontainer.json). The same CLI tools, without the desktop and noVNC server. GUI apps may still work when launched from the terminal. It works well on Linux, acceptable but a bit less smoothly on Windows, macOS needs an X11 server.

> [!NOTE]
> On Windows, starting the dev container may fail if WSL integration is not enabled in the Docker desktop settings (see Resources tab). An alternate solution may be turning off "Mount Wayland Socket" in VS Code's settings.

Documenation on the container may be found on its [Docker Hub page](https://hub.docker.com/r/hdltypetech/tydi-tools), or its [GitHub repository](https://github.com/abs-tudelft/Tydi-tools).

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
