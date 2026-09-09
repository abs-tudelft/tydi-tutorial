# Tydi

In this tutorial you will learn about Tydi step by step through examples. For a top-down read-trough of what Tydi is and how types are built up, see the [Understanding Tydi page](https://abs-tudelft.github.io/docs/tydi/what-is-tydi/) of the documentation.

## A simple stream

For our first stream, we will take a look at a data stream as one could receive from a minimal weather station with temperature and humidity sensor. Its data might look like:

```json
[
  {
    "timestamp": 1773068058000,
    "temperature": 21.5,
    "humidity": 45.2
  },
  {
    "timestamp": 1773068118000,
    "temperature": 21.8,
    "humidity": 44.8
  },
  {
    "timestamp": 1773068178000,
    "temperature": 22.1,
    "humidity": 44.5
  }
]
```

We will convert this data type to a Tydi structure to understand the mapping process and get an idea of what a stream is. For this, [open the example in the Tydi Stream Visualizer](http://localhost:5173/tydi-stream-vis/#input=%5B%0A%20%20%7B%0A%20%20%20%20%22timestamp%22%3A%201773068058000%2C%0A%20%20%20%20%22temperature%22%3A%2021.5%2C%0A%20%20%20%20%22humidity%22%3A%2045.2%0A%20%20%7D%2C%0A%20%20%7B%0A%20%20%20%20%22timestamp%22%3A%201773068118000%2C%0A%20%20%20%20%22temperature%22%3A%2021.8%2C%0A%20%20%20%20%22humidity%22%3A%2044.8%0A%20%20%7D%2C%0A%20%20%7B%0A%20%20%20%20%22timestamp%22%3A%201773068178000%2C%0A%20%20%20%20%22temperature%22%3A%2022.1%2C%0A%20%20%20%20%22humidity%22%3A%2044.5%0A%20%20%7D%0A%5D). The JSON code from above is pre-filled as data input.

In the **Tydi structure builder** panel, you will see something like this

![Temperature and humidity sensor example](./figures/temp-hum-sensor-example.svg)

Clearly, a `Group` is being created (analog to an object), with several fields (analog to the properties), each of which is a base number, and so emitted as `Bit` types. You can customize the bit-widths of the fields. For example, the float values for temperature and humidity might be a `single` (instead of `double`), and thus be `32` bits.

In the **stream visualizer** panel, our stream of 3 elements can be inspected. If you click one of the packets, the data in the source JSON (data import panel) will be highlighted and the **packet inspector** panel will automatically open. There the layout of the packet can be inspected together with its index and dimensionality information. If you click the last element (in purple), you will see that the dimensionality information indicates `1`, as it is the last element of the stream.

## TinyTydi: generating interface implementations

[TinyTydi](https://gitlab.com/hstruik/tinytydi) is included as a submodule in
`tinytydi/`. 
This set of tools is centred around an executable version of the semantics, simulating an interface, illustrating how for a given type it iteratively map elements onto transfers.
By supplying an intialized json object, the tool can derive the tydi-type equivalent, normalize it and subsequently apply the simulation of the interface to the elements. 
This way you can visualize how the formalism would transmit your json object over the wire. 
Furthermore, since a set of input streams has a strict 1to1 correspondence of the output stream, the simulated trace can be used to verify the hardware implementation. 
by invoking the export funcitonality, the toolset can export implementation tables, which can be interpredted by our chisel implementation, to generate the actual HDL that implements an interface of the provided type and behavior. 
It is worth noting that this integration is intended for the tutorial illustration purposes, whereas a fully fledged generator tooling would generate the chisel directly from the formal implementation. The tutorial implementation results in quite a few additional signals and debug probes that would be undesirable in an actual implementation. . 

Clone with submodules, or fetch them afterwards:

```sh
git clone --recurse-submodules https://github.com/abs-tudelft/tydi-tutorial.git
# or, in an existing clone:
git submodule update --init tinytydi
```

The dev container runs `.devcontainer/bootstrap.sh` on creation, which checks
the submodule out and builds the stimulus bundles the Chisel tests read. 

```sh
bash .devcontainer/bootstrap.sh
```

Start with the chat message example from the paper and the presentation. 

```sh
cd tinytydi
./main.py example
```

It steps the semantics one Enter at a time, redrawing the input registers, the
parse tree, the lane buffers and the transfers so far after every step, with the
rule that fired named above them. Characters appear as letters rather than
bytes, with the dimension they close in brackets. The 13 characters of the
message take roughly forty steps.

This repository's own `tydi-material/chat-messages/chat-messages.json` is a slight expansion of the worked example, adding user id and message id. 

```sh
python3 ./main.py json tydi-material/chat-messages/chat-messages.json --type-only
```

This json is mapped to the tydi type `Dim(Group(Bits(64), Dim(Group(Bits(32), Bits(16), Bits(16), Dim(Dim(Bits(8)))))))`
and normalises to three physical streams: the chat id, a 64-bit payload packing
`timestamp`, `message_id` and `user_id` together, and the message characters at
dimension 4. Per stream it also prints the width, the dimension, which json
fields feed it and how many elements it carries. Without `--type-only` the
document's own data is run through the semantics as well, which prints the
dashboard described below and a transfer count for the whole document.

Of note, the simulator currently does not support Unions. This means nullable fields and variant types in json schema cannot be translated to their tydi equivalent. 
`tydi-material/student-example/student.json` is an example and deliberately *not* accepted:
its `"study_end": null` is an optional, which is a `Union` of the value and nothing.

> [!NOTE]
> `tinytydi/hdl/invoke-surfer` is not the `invoke-surfer` in this repository's
> root. The root script drives the ChiselTrace sample circuits; the TinyTydi one
> takes a bundle name and reports whether Tywaves type information was found.

### From json to a waveform

```
# 1. derive the tydi type of the document: three physical streams, with the
#    message text as 8-bit elements at dimension 4.
python3 ./main.py json tydi-material/chat-messages/chat-messages.json --type-only

# 2. turn it into a stimulus bundle: the parameters the circuit is elaborated
#    from, the elements themselves, and the cycle-by-cycle trace to check against
python3 ./main.py export --json tydi-material/chat-messages/chat-messages.json \
                                --lanes 1,2,4 --out tinytydi/hdl/bundles/chatmsgs

# 3. elaborate the interface for that type and simulate it (about 20 s warm).
cd /hdl
scala-cli test .

# 4. open the waveform with the characters already on it
./invoke-surfer chatmsgs --chars
```

Step 4 prints `Tywaves: on (typed hgldd: ...)` before it opens anything. On
anything else the waveform still opens, but without type information, and the
line states which of the two reasons applies.

The character rows are loaded, but as numbers. Right-click a `value` row and set
Format to Tywaves ASCII to read them as characters. This cannot be preselected from the
command line.

Expand `outStream_2` to see the four character lanes fill up. `strb` and `endi`
mark how many lanes carry data in a transfer, and `last(i)` closes dimensions,
one bit per dimension: a lane that ends a word sets bit 0, a lane that ends a
message sets bits 0 and 1, and so on outwards. `in_2` above it shows the element
side, one character per cycle. `_state_output` below it is the parse FSM, one
bit per node of the normalised type, all of them set on the cycle `fullMap`
fires.

The same works for any accepted document. Run `python3 tinytydi/main.py export
--json yours.json --lanes 1,2,4 --out tinytydi/hdl/bundles/yours` from the root,
after which `scala-cli test .` in `tinytydi/hdl` picks the new bundle up on its
own, because every directory under `bundles/` is a test case.

`tinytydi/hdl/README.md` further describes the method for generating the hardware. 

### Other subcommands

`./main.py` without arguments lists them. Besides `example`, `json` and
`export`:

- `simulate` is the same machinery with every choice open. Without options it
  prompts for type, lanes, ruleset and mode, and `?` at a prompt explains that
  choice. `--mode all` enumerates every admissible order in which the internal
  streams can terminate and runs each of them, `--mode random` runs a single
  instance and is the one to combine with `--interactive`. `--ruleset core`
  swaps P_C3 for P_core, which terminates transfer buffers on the outermost
  dimension only.
- `fsm` derives the control loop of the interface from the type directly,
  without simulating. A state is the set of terminated parse tree nodes at a
  cycle boundary, an edge is one cycle. It prints the states and transitions as
  a table, and `--out` writes a Graphviz and a Mermaid version. The size of the
  machine indicates what the type hierarchy and the property set cost you in
  control logic.
- `normalise` prints the reduction from the surface type to the normalized type
  one rewrite at a time. It is also the quickest way to count the physical
  streams of a type, which is how many values `--lanes` expects.

---

## Original material

Material for experimenting with Tydi is given in this markdown file and in the tydi-material folder.

## Visualizer application

Access the Tydi visualizer application at [https://abs-tudelft.github.io/tydi-stream-vis/](https://abs-tudelft.github.io/tydi-stream-vis/).

It is meant to be used in the following way:

1. Insert `json` data containing an example of what you want to transfer in your hardware design
2. The data's data schema is extracted
3. A Tydi structure is created in the [Blockly](https://www.blockly.com/) canvas based on this data schema
    - Each element is given a path mapping to the original data
    - Nullable elements are converted to `Union`s
4. Each stream in the schema (corresponding to a sequence) is split into a separate *physical stream* and data packets are constructed based on the input data
5. Stream transfers are visualized using these data packets

To facilitate this, the app has several tabs:

- Data import: paste JSON content here
- Code generator: shows code for Tydi-lang, Chisel, and Clash to create the actual hardware design for the Tydi structure
- Tydi structure builder: the Blockly canvas that visually shows, and allows editing, the Tydi structure
- Stream visualizer: shows all physical streams of the Tydi hierarchy, together with a table of the transfers and their elements based on the JSON input data
- Packet inspector: when a packet is clicked in the stream visualizer, this panel shows more detailed information about the stream and the specific packet. This includes the dimensionality information, indexes in the source sequences, packet content, and the binary data packing.

## Pipeline example

This example comes from the original [Tydi-Chisel library](https://github.com/abs-tudelft/tydi-chisel) and the conference and journal publications. The idea is that we create a simple streaming pipeline that transforms some data. Specifically, we take in a *stream of numbers with timestamps attached*. This stream first gets filtered on $value\geq0$ and then reduced to statistics: min value, max value, sum of values, and average. The block schedule for this system is as follows:

![number-pipeline-simple.svg](figures/number-pipeline-simple.svg)

### **Tydi-lang**

The example starts with a description of the streams and streamlets in Tydi-lang.

```jsx
#### package pack0;
UInt_64_t = Bit(64); // UInt<64>
SInt_64_t = Bit(64); // SInt<64>

Group NumberGroup {
    value: SInt_64_t;
    time: UInt_64_t;
}

Group Stats {
    average: UInt_64_t;
    sum: UInt_64_t;
    max: UInt_64_t;
    min: UInt_64_t;
}

NumberGroup_stream = Stream(NumberGroup, t=1.0, d=1, c=1);
Stats_stream = Stream(Stats, t=1.0, d=1, c=1);

#### package pack1;
use pack0;

streamlet NumsFilter_interface {
    std_out : pack0.NumberGroup_stream out;
    std_in : pack0.NumberGroup_stream in;
}

impl NonNegativeFilter of NumsFilter_interface {}

streamlet NumsToStats_interface {
    std_out : pack0.Stats_stream out;
    std_in : pack0.NumberGroup_stream in;
}

impl Reducer of NumsToStats_interface {}

impl PipelineExample of NumsToStats_interface {
    instance filter(NonNegativeFilter);
    instance reducer(Reducer);
    filter.std_out => reducer.std_in;
    reducer.std_out => self.std_out;
    self.std_in => filter.std_in;
}
```

You can, from the `tydi-material/pipeline-example` folder, generate the Tydi-lang IR data with
```sh
tydi-lang-complier -c pipeline-example.toml
```

Then, you can generate Chisel code for this Tydi dataflow description with

```sh
tl2chisel output output/json_IR.json
```

This will generate three Chisel files in the `output` folder. The `main` file contains the definition of the top level component and all data types and interfaces (streamlet definitions in Tydi-lang jargon). The `components` file contains bare, stream routing only, implementations as defined in the Tydi-lang description. This is done in a separate file, so they can be swapped out with _real_ implementations easily from another file, without hazard of important code being overwritten. Finally, there is the `generation_sub`, which contains an `App` class that can be run to generate output Verilog code. 

Finally you can generate Verilog output with

```sh
scala-cli output/json_IR_generation_stub.scala output/json_IR_main.scala
```

The folder also contains handwritten versions in Chisel to show what an optimised code that uses library utilities looks like. There is a single-lane and multi-lane version.

### **Tydi type**

The Tydi type that corresponds to the number stream is as follows:

$Stream(t=Group(Bits(64), Bits(64)), d=1)$

Or, expressed in the syntax of the Tydi formalism: $Dim(Group(Bits(64), Bits(64)))$

### **Data**

Some example data can be generated with the following JavaScript method. Below this block is some pre-generated data.

```jsx
function generateDataWithStats(count = 20) {
  const input = [];
  
  // 1. Generate random input data
  for (let i = 1; i <= count; i++) {
    const randomValue = Math.floor(Math.random() * 101) - 50; 
    input.push({
      value: randomValue,
      time: i
    });
  }

  // 2. Filter for values >= 0
  const validValues = input
    .map(item => item.value)
    .filter(val => val >= 0);

  // 3. Calculate statistics with specific edge cases
  if (validValues.length === 0) {
    return {
      input,
      output: {
        average: 0,
        sum: 0,
        max: 0,
        min: Number.MAX_SAFE_INTEGER // 9007199254740991
      }
    };
  }

  const sum = validValues.reduce((acc, curr) => acc + curr, 0);
  
  return {
    input,
    output: {
      average: Math.floor(sum / validValues.length), // Integer division (floor)
      sum: sum,
      max: Math.max(...validValues),
      min: Math.min(...validValues)
    }
  };
}

console.log(JSON.stringify(generateDataWithStats(20)));
```

A few runs of this produces:

```jsx
{
  "input": [{"value":-22,"time":1},{"value":31,"time":2},{"value":-35,"time":3},{"value":-40,"time":4},{"value":23,"time":5},{"value":10,"time":6},{"value":-3,"time":7},{"value":39,"time":8},{"value":15,"time":9},{"value":40,"time":10},{"value":-44,"time":11},{"value":-15,"time":12},{"value":31,"time":13},{"value":-45,"time":14},{"value":-37,"time":15},{"value":-35,"time":16},{"value":-40,"time":17},{"value":38,"time":18},{"value":-32,"time":19},{"value":-31,"time":20}],
  "output": {"average":28,"sum":227,"max":40,"min":10}
}
{
  "input": [{"value":-8,"time":1},{"value":17,"time":2},{"value":-39,"time":3},{"value":-40,"time":4},{"value":6,"time":5},{"value":5,"time":6},{"value":-41,"time":7},{"value":-6,"time":8},{"value":37,"time":9},{"value":1,"time":10}],
  "output": {"average":13,"sum":66,"max":37,"min":1}
}
{
  "input": [{"value":20,"time":1},{"value":30,"time":2},{"value":40,"time":3},{"value":-36,"time":4},{"value":-37,"time":5},{"value":21,"time":6},{"value":44,"time":7},{"value":31,"time":8},{"value":27,"time":9},{"value":-34,"time":10},{"value":28,"time":11},{"value":30,"time":12},{"value":-1,"time":13},{"value":17,"time":14},{"value":-26,"time":15}],
  "output":{"average":28,"sum":288,"max":44,"min":17}
}
```

Transforming this into lists of intputs and outputs gives the following arrays:

**Inputs**

```js
[
  [{"value":-22,"time":1},{"value":31,"time":2},{"value":-35,"time":3},{"value":-40,"time":4},{"value":23,"time":5},{"value":10,"time":6},{"value":-3,"time":7},{"value":39,"time":8},{"value":15,"time":9},{"value":40,"time":10},{"value":-44,"time":11},{"value":-15,"time":12},{"value":31,"time":13},{"value":-45,"time":14},{"value":-37,"time":15},{"value":-35,"time":16},{"value":-40,"time":17},{"value":38,"time":18},{"value":-32,"time":19},{"value":-31,"time":20}],
  [{"value":-8,"time":1},{"value":17,"time":2},{"value":-39,"time":3},{"value":-40,"time":4},{"value":6,"time":5},{"value":5,"time":6},{"value":-41,"time":7},{"value":-6,"time":8},{"value":37,"time":9},{"value":1,"time":10}],
  [{"value":20,"time":1},{"value":30,"time":2},{"value":40,"time":3},{"value":-36,"time":4},{"value":-37,"time":5},{"value":21,"time":6},{"value":44,"time":7},{"value":31,"time":8},{"value":27,"time":9},{"value":-34,"time":10},{"value":28,"time":11},{"value":30,"time":12},{"value":-1,"time":13},{"value":17,"time":14},{"value":-26,"time":15}]
]
```

**Outputs**
```js
[
  {"average":28,"sum":227,"max":40,"min":10},
  {"average":13,"sum":66,"max":37,"min":1},
  {"average":28,"sum":288,"max":44,"min":17}
]
```

These can be inserted in separate instances of the visualizer. For the input, the number of lanes (`n`) should be a bit higher, so there is more overview.

#### Exercises

Insert the outputs and inputs into separate instances of the visualizer and analyse the structure and packets.

### **Chisel**

When the Tydi-lang code is transpiled to Chisel code, the following is obtained.

```scala
// Based on transpile output

/** Implementation, defined in pack1. */
class NonNegativeFilter extends NonNegativeFilter_interface {
	outStream := inStream
  outStream.strb := inStream.strb(0) && inStream.el.value >= 0.S
}

/** Implementation, defined in pack1. */
class PipelineExample extends PipelineExample_interface {
    // Modules
    val filter = Module(new NonNegativeFilter)
    val reducer = Module(new Reducer)

    // Connections
    reducer.in := filter.out
    out := reducer.out
    filter.in := in
}

```

A more compact version can be obtained when utility classes are used.

```scala
// Using utility classes

/** A module based on a stream-processing base with input and output streams of type `NumberGroup`.
  * Input and output streams are passthrough-connected by default so only meaningful signals are overridden.
  */
class NonNegativeFilter extends SubProcessorBase(new NumberGroup, new NumberGroup) {
  outStream.strb := inStream.strb(0) && inStream.el.value >= 0.S
}

/** Using the stream processing modules with chaining syntax.
  * SimpleProcessorBase is similar to SubProcessorBase but
  * does not expose the detailed Stream content signals. */
class PipelineExampleModule extends SimpleProcessorBase(new NumberGroup, new Stats) {
  out := in.processWith(new NonNegativeFilter).processWith(new Reducer())
}
```

## Student data analysis

A more advanced example is a dataset of students and their exam results. This example also comes from the original [Tydi-Chisel library](https://github.com/abs-tudelft/tydi-chisel) and the journal publication. A lot of streams are involved, because the data contains a lot of strings, and each string is a sequence of unknown runtime length.

### **JSON data**

The data looks like this

```json
[
  {
    "student_number": "S123456789",
    "name": "John Doe",
    "birthdate": "2000-05-15",
    "study_start": "2021-05-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "john.doe@example.com",
    "exams": [
      {
        "course_code": "CS101",
        "course_name": "Introduction to Computer Science",
        "exam_date": "2023-12-10",
        "grade": 80
      },
      {
        "course_code": "MATH201",
        "course_name": "Calculus",
        "exam_date": "2023-12-15",
        "grade": 60
      }
    ]
  },
  {
    "student_number": "S234567890",
    "name": "Jane Smith",
    "birthdate": "2002-08-20",
    "study_start": "2020-09-01",
    "study_end": null,
    "study": "Computer Science",
    "email": "jane.smith@example.com",
    "exams": [
      {
        "course_code": "CS302",
        "course_name": "Data Structures and Algorithms",
        "exam_date": "2024-02-22",
        "grade": 85
      },
      {
        "course_code": "ELEC301",
        "course_name": "Computer Networks",
        "exam_date": "2023-11-17",
        "grade": 75
      }
    ]
  },
  {
    "student_number": "S345678901",
    "name": "Bob Johnson",
    "birthdate": "1998-03-12",
    "study_start": "2019-01-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "bob.johnson@example.com",
    "exams": [
      {
        "course_code": "CS203",
        "course_name": "Operating Systems",
        "exam_date": "2023-05-19",
        "grade": 90
      },
      {
        "course_code": "INFO201",
        "course_name": "Database Management Systems",
        "exam_date": "2024-03-25",
        "grade": 80
      }
    ]
  },
  {
    "student_number": "S456789012",
    "name": "Emily Chen",
    "birthdate": "2005-10-28",
    "study_start": "2018-09-01",
    "study_end": null,
    "study": "Computer Science",
    "email": "emily.chen@example.com",
    "exams": [
      {
        "course_code": "CS404",
        "course_name": "Artificial Intelligence and Machine Learning",
        "exam_date": "2023-12-01",
        "grade": 95
      },
      {
        "course_code": "STAT301",
        "course_name": "Data Mining",
        "exam_date": "2024-02-15",
        "grade": 85
      }
    ]
  },
  {
    "student_number": "S567890123",
    "name": "Michael Lee",
    "birthdate": "1995-06-22",
    "study_start": "2017-01-16",
    "study_end": null,
    "study": "Computer Science",
    "email": "michael.lee@example.com",
    "exams": [
      {
        "course_code": "CS301",
        "course_name": "Programming Languages and Paradigms",
        "exam_date": "2023-04-14",
        "grade": 88
      },
      {
        "course_code": "GAME201",
        "course_name": "Game Development with Python",
        "exam_date": "2024-01-18",
        "grade": 92
      }
    ]
  },
  {
    "student_number": "S678901234",
    "name": "Sarah Kim",
    "birthdate": "2001-02-14",
    "study_start": "2016-09-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "sarah.kim@example.com",
    "exams": [
      {
        "course_code": "CS402",
        "course_name": "Web Development with JavaScript and HTML/CSS",
        "exam_date": "2023-11-10",
        "grade": 95
      },
      {
        "course_code": "INFO302",
        "course_name": "Human-Computer Interaction Design Principles",
        "exam_date": "2024-03-01",
        "grade": 90
      }
    ]
  },
  {
    "student_number": "S789012345",
    "name": "David Patel",
    "birthdate": "1992-04-18",
    "study_start": "2015-08-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "david.patel@example.com",
    "exams": [
      {
        "course_code": "CS501",
        "course_name": "Compilers and Interpreters",
        "exam_date": "2023-03-17",
        "grade": 92
      },
      {
        "course_code": "ELEC401",
        "course_name": "Computer Architecture",
        "exam_date": "2024-02-01",
        "grade": 88
      }
    ]
  },
  {
    "student_number": "S890123456",
    "name": "Olivia Brown",
    "birthdate": "2003-11-25",
    "study_start": "2019-09-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "olivia.brown@example.com",
    "exams": [
      {
        "course_code": "CS302",
        "course_name": "Data Structures and Algorithms",
        "exam_date": "2023-12-15",
        "grade": 85
      },
      {
        "course_code": "INFO201",
        "course_name": "Database Management Systems",
        "exam_date": "2024-03-22",
        "grade": 80
      }
    ]
  },
  {
    "student_number": "S901234567",
    "name": "Alexander White",
    "birthdate": "1990-01-05",
    "study_start": "2018-08-15",
    "study_end": null,
    "study": "Computer Science",
    "email": "alexander.white@example.com",
    "exams": [
      {
        "course_code": "CS401",
        "course_name": "Network Security and Cryptography",
        "exam_date": "2023-11-17",
        "grade": 95
      },
      {
        "course_code": "GAME302",
        "course_name": "Game Development with C++",
        "exam_date": "2024-02-15",
        "grade": 90
      }
    ]
  }
]
```

It should be noted that this example does not give the most interesting streaming type, as nesting depth is limited of both the groups and the streams. The most interesting data is probably the strings within the exams info, because they are 3rd dimension data, resulting in more complex relationships between an element and its role in the ending of sequences.

## Chats with messages example

An example that shows various interesting aspects of Tydi’s typing and protocol is a list of chats that each contain messages with some metadata and text that is split up in words. This means that the characters in the messages are 4-dimensional data elements (chats→messages→words→characters). The first and second dimension elements carry some metadata about respectively the chats and the messages.

### **JSON**

```json
[
  {
    "chat_id": 102938475612345678,
    "messages": [
      {
        "timestamp": 1712052000,
        "message_id": 9001,
        "user_id": 1001,
        "words": ["Shall", "we", "order", "pizza", "tonight?"]
      },
      {
        "timestamp": 1712052060,
        "message_id": 9002,
        "user_id": 1002,
        "words": ["Sure,", "I", "would", "love", "some", "Pepperoni."]
      },
      {
        "timestamp": 1712052120,
        "message_id": 9003,
        "user_id": 1001,
        "words": ["Great,", "I", "will", "place", "the", "order", "now."]
      },
      {
        "timestamp": 1712052180,
        "message_id": 9004,
        "user_id": 1002,
        "words": ["Don't", "forget", "the", "garlic", "dipping", "sauce!"]
      }
    ]
  },
  {
    "chat_id": 223344556677889900,
    "messages": [
      {
        "timestamp": 1712138400,
        "message_id": 12050,
        "user_id": 2005,
        "words": ["Did", "you", "see", "the", "latest", "rocket", "launch?"]
      },
      {
        "timestamp": 1712138520,
        "message_id": 12051,
        "user_id": 2006,
        "words": ["The", "booster", "landing", "was", "incredible."]
      },
      {
        "timestamp": 1712138600,
        "message_id": 12052,
        "user_id": 2005,
        "words": ["It", "still", "feels", "like", "science", "fiction."]
      },
      {
        "timestamp": 1712138700,
        "message_id": 12053,
        "user_id": 2006,
        "words": ["True,", "the", "reusability", "is", "a", "game", "changer."]
      }
    ]
  },
  {
    "chat_id": 556677889900112233,
    "messages": [
      {
        "timestamp": 1712224800,
        "message_id": 33001,
        "user_id": 3001,
        "words": ["Is", "the", "deployment", "to", "production", "finished?"]
      },
      {
        "timestamp": 1712224900,
        "message_id": 33002,
        "user_id": 3002,
        "words": ["Yes,", "all", "unit", "tests", "passed", "successfully."]
      },
      {
        "timestamp": 1712224950,
        "message_id": 33003,
        "user_id": 3001,
        "words": ["Great", "job", "team!"]
      },
      {
        "timestamp": 1712225000,
        "message_id": 33004,
        "user_id": 3003,
        "words": ["I", "am", "monitoring", "the", "logs", "now."]
      },
      {
        "timestamp": 1712225100,
        "message_id": 33005,
        "user_id": 3003,
        "words": ["Everything", "looks", "stable", "so", "far."]
      }
    ]
  },
  {
    "chat_id": 998877665544332211,
    "messages": [
      {
        "timestamp": 1712311200,
        "message_id": 55010,
        "user_id": 4001,
        "words": ["I", "started", "reading", "that", "new", "fantasy", "novel."]
      },
      {
        "timestamp": 1712311300,
        "message_id": 55011,
        "user_id": 4002,
        "words": ["The", "world-building", "is", "absolutely", "stunning."]
      },
      {
        "timestamp": 1712311400,
        "message_id": 55012,
        "user_id": 4001,
        "words": ["Wait", "until", "you", "get", "to", "chapter", "five."]
      },
      {
        "timestamp": 1712311500,
        "message_id": 55013,
        "user_id": 4002,
        "words": ["No", "spoilers", "please!", "I", "am", "only", "on", "page", "ten."]
      }
    ]
  }
]
```

### Exercises

- Click on various elements in the **Tydi structure builder** or **stream visualizer** tab. Check out which elements they correspond to in the other tabs, such as the input data, or the Tydi structure (when clicking in the visualizer).
- Inspect the data packing of the message data. Change the bit widths in the block editor.
- Change the number of lanes of some streams.
- Inspect the dimensionality (`last` flags) information of the message text. Different sequence endings have different colours.
