# idris-cil [![Build Status](https://travis-ci.org/bamboo/idris-cil.png?branch=master)](https://travis-ci.org/bamboo/idris-cil)

A Common Intermediate Language backend for [Idris](http://www.idris-lang.org/).

## Why

Because programmers targeting the CLR deserve a modern pure functional language with dependent types.

## Usage

Given a `Main.idr` file:

```idris
module Main

main : IO ()
main = putStrLn "Hello, Idris!"
```

Compile it to cil and execute it with [.NET Core](https://www.microsoft.com/net/core):

```
idris --codegen cil Main.idr -o HelloWorld.exe \
  && dotnet HelloWorld.exe
```

The resulting assemblies can also be used with Mono or Unity.

## Installing

It's important that the version of the Idris executable matches the version used to build idris-cil:

	git clone git@github.com:bamboo/idris-cil
	cd idris-cil
	stack install idris
	stack install

## Contributing

Issue reports and PRs are welcome.

Brought to you by @bamboo, @sangamon and [contributors](https://github.com/bamboo/idris-cil/graphs/contributors).

## License

[![BSD3](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](LICENSE)
