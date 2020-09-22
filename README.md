# Esoglot

Esoglot is an [esolang](esolangs.org) cross-compiler and executor.

The primary goal of Esoglot is to be an experiment, a playground, a place for practice and fun, for me and for anyone else who would like to join me.

After this, Esoglot's ultimate aspiration is to allow any esolang to be compiled into any other esolang, bar differences in computational class or other insurmountable barriers.

## Usage

Esoglot is written in [Nim](https://nim-lang.org/), so make sure you have that installed first. Then:

```nim
# Compile esoglot
nim c ./esoglot.nim

# Execute some code as a language
bf_hello_world="+[+++<+<<->>>[+>]>+<<++]>>>>--.>.>>>..+++.>>++.<<<.>>--.<.+++.------.<<<-.<<."
./esoglot e --lang:brainfuck --verbose --source:"$bf_hello_world"

# Or cross-compile it into a different language
./esoglot c --from:ook --to:brainfuck --verbose --source:"..."
```

## Languages Supported

[comment]: <> (Do not edit this section directly; run the readme-updating script)

[comment]: <> (BEGIN LANG LIST)

- [**brainfuck**](http://esolangs.org/wiki/brainfuck)
  - Executable
- [**infinifuck**](https://esolangs.org/wiki/Infinifuck)
  - Executable
- [**triad**](https://esolangs.org/wiki/Triad)
  - Executable
- [**Ook!**](http://esolangs.org/wiki/Ook)
  - Convertable to brainfuck

[comment]: <> (END LANG LIST)

## Project Structure

- `src/langs.toml`: metadata about languages supported by esoglot.
- `src/conv/`: Contains all the esoglot converters (cross-compilers). Each is in a folder with the format `{FROM-LANG}_to_{TO-LANG}`, which includes:
  - `_build.sh`: a script that builds the converter, which may be written in any programming language
  - `_run.sh`: a script that runs the converter. It should take the original source code as the only argument and output the converted code to stdout.
- `src/exec/`: Contains all the esoglot executors (interpreters). Each is in a folder with the name of the language code, which includes:
  - `_build.sh`: a script that builds the executor, which may be written in any programming language
  - `_run.sh`: a script that runs the executor. It should take the source code as the only argument and run it.
- `src/prog/`: Contains sample programs. Includes folders which represent behaviour and house implementations of said behaviour. For instance, `src/prog/hello_world/` contains Hello World programs, and `src/prog/hello_world/brainfuck.impl` is a brainfuck implementation of Hello World. Each folder also contains a `_cases.toml` file, which includes test cases.

## Contributing

If you would like to contribute, please do! I have very few rules:

- If you would like to add a new converter (cross-compiler) or executor (interpreter), you're basically free to do as you please.
  - Just create `src/exec/{LANG}` or `src/conv/{FROM-LANG}_to_{TO-LANG}` with `_build.sh` and `_run.sh` and send me a pull request.
    - Feel free to use whatever language you'd like. We're about having fun here.
  - Also, make sure the relevant language(s) are in `src/langs.toml`, and add them if they aren't.
  - Oh, and it'd be super cool if you added some sample programs to `src/prog/`.
- If you would like to editing an existing converter (cross-compiler) or executor (interpreter) that *isn't* yours, go ahead, just be respectful.
- If you would like to edit Esoglot itself, I will be more strict, but help is still appricated. It would be great if you ran planned changes by me ahead-of-time, either by opening a Github issue or contacting me on Twitter ([@Quelklef](https://twitter.com/quelklef)) or Discord (@Quelklef#8261).

