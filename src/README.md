# Esoglot

Esoglot is an [esolang](esolangs.org) cross-compiler and interpreter.

The ultimate goal of esoglot is to allow for compilation from just about any esolang to just about any other (bar differences in computational class or other insurmountable barriers).

# Usage

Esoglot is written in [Nim](https://nim-lang.org/), so you will need to have Nim installed in order to use it.

With nim installed, you can
```nim
nim c ./esoglot.nim
```
to compile Esoglot, and then

```nim
./esoglot OPTIONS
```
to execute it.

The Esoglot binary recognizes two usages.

The first is conversion from one language to another.
The languages are provided as arguments, but the source code is given via stdin.
The compiled result will be printed to stdout.
```sh
esoglot c -f:<from-lang> -t:<to-lang> [--verbose]
```

The second usage is for execution of a language.
The language is given as an argument and the source code is given via stdin.
```sh
esoglot e -l:<the-lang>
```
If Esoglot doesn't know how to execute the given language, it will try to convert it to a language that it does know how to execute.

# Languages Supported

- Ook!
- Brainfuck

# Contributing

TODO
