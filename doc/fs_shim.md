# fs_shim

A portable file system library to allow working on io, browser (though idb_shim) and memory (through idb_shim).

[![Build Status](https://travis-ci.org/tekartik/fs_shim.dart.svg?branch=master)](https://travis-ci.org/tekartik/fs_shim.dart)

## API supported

It contains a subset of the io `File/Directory` API. Basically all sync methods are removed since
on the web indexedDB cannot be accessed in a synchronous way.

Classes

- File (create, openWrite, openRead, writeAsBytes, writeAsString, copy)
- Link (create, target)
- Directory (create, list)
- FileSystem (file, link, directory, type, isFile, isDirectory, isLink)
- FileSystemEntity (path, exists, delete, rename, absolute, isAbsolute, state, parent)
- FileStat
- FileSystemEntityType,
- FileSystemException,

Static method

- Directory.current
- FileSystemEntity.isFile
- FileSystemEntity.isDirectory
- FileSystemEntity.isLink

Static and File/Directory/Link constructor uses `fileSystemDefault` which is platform dependent (web or io).

## Usage

### In memory

A simple usage example:

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';

Future main() async {
  final fs = fileSystemMemory;

  // Create a top level directory
  final dir = fs.directory('/dir');

  // and a file in it
  final file = fs.file(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    final link = fs.link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: ${await fs.file(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
```

### Using IO API

#### Using fs_shim.dart

You can simply replace in the above example:

```dart
final fs = fileSystemMemory;
```

by

```dart
final fs = fileSystemIo;
```

If you only target io, you can still be able to use `File` and `Directory` constructor, replace

```dart
import 'dart:io'
    hide
    Directory,
    File,
    Link,
    FileSystemEntity,
    FileMode,
    FileStat,
    OSError,
    FileSystemException,
    FileSystemEntityType;

import 'package:fs_shim/fs_shim.dart';
```

by

```dart
import 'package:fs_shim/fs_io.dart';
```

Then a reduced set of the IO API can be used, same source code that might requires some cleanup if you import from
existing code

Simple example

````
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';

Future main() async {
  await exampleInit();
  final fs = fileSystemDefault;
  // safe place when running from package root
  final dirPath = join(Directory.current.path, 'test_out', 'example', 'dir');

  // Create a top level directory
  final dir = Directory(dirPath);
  print('dir: $dir');
  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  final file = File(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    var link = Link(join(dir.path, 'link'));

    await link.create(basename(file.path));
    var linkFile = File(link.path);
    print('link: ${await linkFile.readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
````

### Browser usage

You can simply replace in the in memory example:

```dart
final fs = fileSystemMemory;
```

by

```dart
final fs = fileSystemWeb;
```

Default implementation on browser uses fileSystemWeb

### Random access support.

Random access is supported since version 2.1.0. Default web implementation is not optimized for random access support (it might change in the future).

You can specify a paging parameter (initial testing is good in some scenario with a 16Kb page, you might tune it for your needs).

```dart
import 'package:fs_shim/fs_browser.dart';

// Use default paging 16Kb
final fs =
  fileSystemWeb.withIdbOptions(options: FileSystemIdbOptions.pageDefault);
```

Storage remains compatible if the options is changed.

### Utilities

* Lightweight glob support (`**`, `*` and `?` in a posix style path)
* Copy utilities (copy files, directories recursively)

## Testing

### Dev dependencies

Stable

    fs_shim: any

Bleeding age

    fs_shim:
        git: https://github.com/tekartik/fs_shim.dart

## Features and bugs

* On windows file links are not supported (fs.supportsFileLink returns false)
* On windows directory link target are absolutes
* On the web, the size of the file system is limited by the limit size of indexedDB databases (browser dependent)

