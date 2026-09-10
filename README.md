# Tydi tutorial
This repository contains all the tools and educational ematerial and code to learn about and get started with the Tydi tools and ecosystem.

> [!TIP]
> We recommend starting the download of the Docker image already. Check the [Choosing a container flavour section](#choosing-a-container-flavour). Use either
> ```sh
> docker pull hdltypetech/tydi-tools:cli-latest
> ```
> or
> ```sh
> docker pull hdltypetech/tydi-tools:vnc-latest
> ```
> The `vnc` image is built on top of the `cli` image, so also the download is incremental.  
> Apart from that, check the [prerequisites](#prerequisites).

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
### Prerequisites
In order to follow this tutorial, you will need the following
1. [**Visual Studio Code**](https://code.visualstudio.com/)
   * A different IDE may also work, but we will assume VS Code for this tutorial.
   * As a most barebone experience, you might use `docker run -it --rm -v "$(pwd)":/root/workspace -w /root/workspace hdltypetech/tydi-tools:cli-latest bash` and edit files locally using your favourite tools.
2. **A Container Engine:**
   * [Docker Desktop](https://www.docker.com/products/docker-desktop/) *(Recommended for Windows/macOS)*
   * **Or** an alternative like [OrbStack](https://orbstack.dev/) (macOS), [Rancher Desktop](https://rancherdesktop.io/), or [Podman](https://podman.io/). This is untested though, and may require changing the `Dev Containers: Docker Path` setting.
3. **VS Code Dev Containers extension** ([`ms-vscode-remote.remote-containers`](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers))

> [!IMPORTANT]
> When using Windows, it is recommended to have [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) set up to act as Docker's back-end.

### Instructions
Get started by cloning the repo. Then, open the project in VS Code.
```sh
# Clone repo
git clone --recurse-submodules https://github.com/abs-tudelft/tydi-tutorial.git
# Open in VS Code
cd tydi-tutorial
code .
```

This repository contains a project with **development container** that you can be used in VS Code. With this set-up, you can easily write and edit code, and execute the tools of the Tydi ecosystem on those files. Once you cloned the project and opened the folder in VS Code, there are a few ways to activate it

1. If the the [Dev Container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) is already installed, the `.devcontainer` configs will be detected and a notification will ask if you want to reopen the folder in the dev container.
2. You can trigger it as action by pressing <kbd>F1</kbd> and selecting `> Dev Containers: Open Folder in Container`
3. If it does not show the notification, the extension may not be installed yet. The following button will trigger opening the folder in a dev container and ask if you want to instal the extension if you don't have it yet. [![Open folder in Dev Container](https://img.shields.io/badge/Dev%20Containers-Open%20Folder-blue?logo=visualstudiocode)](vscode://ms-vscode-remote.remote-containers/openFolder?url=file:///${workspaceFolder})

Once you activate opening the folder in the dev container, a pop-up will ask you *which* container you want, see the details below to make a choice. When the project is opened in the dev container, the files will live in the container, and the terminal will execute commands within the container, meaning that all CLI tools are available.

### Choosing a container flavour

Three flavours of the container are provided, and VS Code will let you pick one when you reopen the folder in a container (`Dev Containers: Reopen in Container`). To switch flavours later, run `Dev Containers: Reopen in Container` again and select another one.

- **Tydi-Tools (VNC desktop)** – [`.devcontainer/vnc`](.devcontainer/vnc/devcontainer.json). Recommended for beginners and macOS users. In addition to the CLI tools, it runs a lightweight XFCE desktop environment, exposed as a browser-based noVNC interface on http://localhost:6080/vnc.html. This may be more intuitive for some users. The resolution of this virtual desktop may be changed with the `DESKTOP_RESOLUTION` variable in its `devcontainer.json`.
- **Tydi-Tools (CLI only)** – [`.devcontainer/cli`](.devcontainer/cli/devcontainer.json). The same CLI tools, without the desktop and noVNC server. GUI apps may still work when launched from the terminal. It works well on Linux with the native Docker Engine, acceptable but a bit less smoothly on Windows, macOS needs an X11 server. On Linux with Docker Desktop, see the note below.
- **Tydi-Tools (CLI, X11 over TCP)** – [`.devcontainer/cli-x11`](.devcontainer/cli-x11/devcontainer.json). Only for Linux hosts running **Docker Desktop**, where GUI apps cannot reach your screen from the "CLI only" flavour (see below). Everything else is identical to that flavour. Do not pick this one on macOS or Windows, or on Linux with the native Docker Engine: there GUI forwarding already works, and this flavour's hardcoded `DISPLAY` would only get in the way.

> [!NOTE]
> On Windows, starting the dev container may fail if WSL integration is not enabled in the Docker desktop settings (see Resources tab). An alternate solution may be turning off "Mount Wayland Socket" in VS Code's settings. This is Windows-specific advice: on Linux that setting is what makes GUI apps work in the first place, so leave it on there.

#### GUI apps on Linux with Docker Desktop

If GUI apps such as Surfer refuse to open from the terminal in the "CLI only" flavour, and you are on Linux, see the info below

<details>
Check which Docker you are talking to:

```sh
docker context ls   # an active "desktop-linux" context means Docker Desktop
```

Docker Desktop on Linux runs your containers inside a **virtual machine**, even though the host is already Linux. Its file sharing only covers `/home`, so the X11 socket (`/tmp/.X11-unix`) and the Wayland socket (`$XDG_RUNTIME_DIR/wayland-0`) cannot be bind-mounted into the container:

```
docker: mounts denied: The path /tmp/.X11-unix is not shared from the host
```

Adding those paths to File Sharing does not help either. A Unix domain socket is a kernel object, so connecting to one requires the listener to live in the same kernel, which it does not across the VM boundary. Socket forwarding is exactly the mechanism the Dev Containers extension uses to make GUI apps work, so on Docker Desktop that mechanism cannot work at all. There are two ways out:

1. **Use the native Docker Engine** (recommended, and the permanent fix). Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/), then `docker context use default`. Bind mounts are then real bind mounts on your own kernel, the Dev Containers extension forwards your display again, and the plain "CLI only" flavour works out of the box. Make sure "Mount Wayland Socket" is enabled in VS Code's settings.
2. **Use the "CLI, X11 over TCP" flavour.** It keeps Docker Desktop and reaches your X server over a loopback TCP port instead of a socket. Its `initializeCommand` runs [`.devcontainer/host-x11-bridge.sh`](.devcontainer/host-x11-bridge.sh) on your host, which copies the X cookie to `~/.tydi-xauth` and starts a `socat` bridge from `127.0.0.1:6000` to your X server. This needs `socat` and `xauth` on the host (`sudo apt install socat x11-xserver-utils`). It works under both Xorg and Wayland, since the container talks to Xwayland, and it is bound to loopback on purpose: never expose an X server to your network. The flavour also forces software OpenGL rendering, because direct rendering is not available over a TCP X connection; without that, Surfer loads its waveform and then hangs before opening a window.

> [!NOTE]
> The macOS build of Docker Desktop uses a VM for the same reason, which is why macOS users are pointed at the VNC flavour. The VNC flavour sidesteps all of this, on every platform, by running its own X server inside the container.

Documenation on the container may be found on its [Docker Hub page](https://hub.docker.com/r/hdltypetech/tydi-tools), or its [GitHub repository](https://github.com/abs-tudelft/Tydi-tools).
</details>

## Instructions

### Tydi

See the [Tydi info document](./docs/tydi-info.md) for the material about the Tydi protocol, formalism, and generator tooling.

### Debugging tools

See the [debugging tools document](./docs/debugging-tools.md) for the material about source level debugging and signal tracing.

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
