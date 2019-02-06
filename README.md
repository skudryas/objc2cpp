OBJC2CPP
=======
About
-----

This tool is intended for automatically rewrite Objective-C code into C++

Usage
-----

Use `./objc2cpp.sh path/to/sources`, tune config in `objc2cpp.sh` for your need.

Restrictions
------------

In fact, this script just replaces Objective-C classes and functions definitions and implementations into C++ syntax.
I.e.:

test.h:
    #import <Header.h>
    
    @interface Foo: Bar
    - (int)someMethod:(char*)a withParam:(int)b;
    @end

test.m:
    #import <Foo.h>
    
    @implementation Foo
    - (int)someMethod:(char*)a withParam:(int)b
    {
      // some code here
    }

will be transformed to:

test.hpp:
    #pragma once
    #include <Header.h>
    
    class Foo: public Bar
    {
      int someMethod_withParam(char* a, int b);
    };

test.cpp:
    #include <Foo.h>
    
    int Foo::someMethod_withParam(char* a, int b)
    {
      // some code here
    }
