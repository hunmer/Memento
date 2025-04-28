# Event

[![Pub Package](https://img.shields.io/pub/v/event.svg?style=flat-square)](https://pub.dev/packages/event)

> IMPORTANT: This version includes breaking changes. See CHANGELOG.md for details

This package supports the creation of lightweight custom Dart Events, that allow interested subscribers to be notified that something has happened. It provides a notification mechanism across independent packages/layers/modules.

It is inspired by the `C#` language's implementation of `Events` and `Delegates`.


Contents
* Usage
  * Arguments
  * Broadcast to a Stream
  * Diagnostics
* What's New
* Features and bugs
* Dependencies
* What's it For?
* Examples
  * 1 - A simple Event with no argument
  * 2 - An Event with a custom event argument

---

## Usage

```dart
// dart code file
import 'package:event/event.dart';
```

Declare an `Event`. Subscribe a handler function (subscriber) to run when the Event occurs. Indicate that the `Event` has occured by calling the `broadcast` method.

```dart
var e = Event();
e.subscribe((args) => "event occurred"));
e.broadcast();
```

An Event is lightweight. It maintains a list of subscribers, but that list is only instantiated the first time it is subscribed to. Broadcasting an Event does nothing if there are no subscribers. With no overhead, or impact on performance, feel free to declare and publish large numbers of Events.


### Arguments

> IMPORTANT: In the common case, one will typically not pass custom data (arguments) representing what has changed to subscribers. Instead, subscriber code will query the state of the object containing the Event to determine changed values.
> 
> In other words, consider the MVC pattern. When the model changes, interested parties are notified. They then query the model if necessary to determine changed values.
> 
> See the Counter class in the example folder. Rather than pass the new counter value to the subscriber, the subscriber gets the current value from the Counter class.

Arguments that can be provided to a subscriber must be either the `EventArgs` class or a derived custom type.

> Note: Two helper derived classes (Value and Values) are included. See the `Helper Argument Classes` section below for further information.


Specify the argument type as a generic type on an Event. Provide an instance of this generic type as an argument to the `broadcast` method. Instance properties are then available in subscribed code.

```dart
  var e = Event<Value<double>>();
  // Value is a class derived from EventArgs

  e.broadcast(Value(3.14159));
  // provide an instance of the Event generic type

  e.subscribe((args) => print(args.value));
  // value is a property of the Value class
  
  // outputs 3.14159 to the console
```

#### EventArgs as Default

If no generic type is specified, then under the hood the Event will be of generic type `EventArgs`. Thus, the following two Event declations are equal ...

```dart
  var e = Event();
    // is equivalent to...
  var e = Event<EventArgs>();
```

Likewise, an instance of EventArgs will be automatically provided even if not specified as an argument to `broadcast`. The following two `broadcast` calls are equivalent...

```dart
  // var e = Event();

  e.broadcast();
    // equivalent to...
  e.broadcast(EventArgs());
```

#### EventArgs Properties

EventArgs (and derived types) has two properties that can be accessed by a subscriber:- `eventName` and `whenOccured`.

By default, the `eventName` is a blank string. To specify it, provide the name when creating an Event.

```dart
  var e = Event("MyEvent");
  // equivalent to Event<EventArgs>("MyEvent");

  e.subscribe((args) => print(args.eventName));
  // outputs "MyEvent" to the console
```

An eventName might be useful if a client subscribes to multiple Events. One could query the eventName to determine what occurred from within client code. It is also useful when using the built in diagnostics library for identifying the Event in a log statement.

#### Simplified Custom EventArgs Example

```dart
// An example custom 'argument' class
class Wind extends EventArgs {
  String direction;
  int strength
  Wind(this.direction, this.strength);
}

// Example in use
var windChanged = Event<Wind>();
windChanged.broadcast(Wind('ENE', 27));

// Wind's direction and strength, is passed to all subscribers

windChanged.subscribe((args) => print('${args.direction}:${args.strength}'));
// prints ENE:27
```

### Helper Argument Classes

Two prebuilt helper `EventArgs` derived classes (`Value` and `Values`) are included to cover the common cases of wanting to provide subscribers with:-

  1. A single value
  2. Any two values

Providing these, means that for these common cases you do not need to create your own custom EventArgs derived argument classes. These two classes are respectively:-

  1. `Value<T>`, providing a `value` property
  2. `Values<T1, T2>`, providing `value1` and `value2` properties

Consider the following examples of them in use:-

#### ==Value==

``` dart
// value (explicit)
var myValueEvent = Event<Value<int>>();
myValueEvent.broadcast(Value(27)));
myValueEvent.subscribe((args) => {print('${args.value}'}); 
// prints 27
```

Note that in the Value type can be of type `dynamic` and does not therefore need to be explicitly stated. This means that the first line of the above could instead be written as:-

``` dart
// value (dynamic)
var myValueEvent = Event<Value>();  // no <int> type specified
```
#### ==Values==

``` dart
// values (explicit)
var weatherEvent = Event<Values<String, int>>();
weatherEvent.broadcast(Values('ENE', 18)));
weatherEvent.subscribe((args) {
  print('${args.value1}:${args.value2}'));
}); // prints ENE:18
```

As with `Value`, one could omit the Values types and have them be of type dynamic. This means that the first line of the above could instead be written as:-

```dart
// values (dynamic)
var weatherEvent = Event<Values>(); // no <String, int>
```

### Broadcast to a Stream

Dart streams enable a sequence of events to be filtered and transformed. One can subscribe an `Event` to a stream using the `subscribeStream` method.
The rich range of mechanisms to filter and manipulate Streams become available.

Remember that the supplied `StreamSink` should be closed when no longer needed.

```dart
// Example
var e = Event();
var sc = StreamController();

e.subscribeStream(sc.sink);
e.broadcast();

sc.stream.listen((e) => print('boom'));
sc.close();   // remember to close
```

### Diagnostics

> New in 3.1.0

Diagnostics logging is available via the built-in diagnostics library. Output a message via the `Log` method, that will be displayed in the IO destination set in the `showLog` method.

If no `showLog` method is included, then `log` statements are ignored.

```dart
// start of application
showLog(stdout, Severity.info.value);

// sometime later...
log("my diagnostic message", source: "mypackage", level: Severity.info);
```

Both `source` and `level` log arguments have default values and can be omitted. The defaults are "Log" and "Severity.info" respectively.

Severity levels include `debug`, `info`, `warning` and `error`. `Severity.all` includes all of these, while `Severity.allExceptDebug` is as named.

#### Broadcast and Subscribe Logging

The Event `broadcast` and `subscribe` methods both include a diagnostic `log` method. Example output is shown below:-

```
// Example diagnostics logging output
Event (debug): 2024-09-10 11:37:49.665124Z Subscribed to Event "countChanged:Event<EventArgs>"
Event (debug): 2024-09-10 11:37:49.675925Z Broadcast Event "countChanged:Event<EventArgs>"
```

Note that the Severity level in the ShowLog method must include Severity.debug to see these messages, i.e.

```dart
showLog(stdout, Severity.debug.value);
// or
showLog(stdout, Severity.all);
```

## What's New

See the [Changelog][changelog] for details on changes in each version.

## Requesting Features and Reporting Bugs

Please add feature requests and report bugs at the [issue tracker][tracker].

## Dependencies

None. This Dart package has no non-development dependencies on other packages.

## What's it For?

As developers, we understand that dividing independent functionality into separate modules (packages) is something to which we should aspire. It can be ideal to model our problem domain independently of user interface, other systems, and technical plumbing.

Equally, independent pieces of infrastructure benefit from being in separate modules (packages). Doing so has the same attraction as the decomposition of functionality into separate subroutines, albeit at a larger scale. Let's divide a large problem into smaller pieces, that can be reasoned about and worked on independently, and then re-combined to represent a solution to the problem.

> To make something _independent_, it should should know nothing of the things that might depend on it.

#### An elevator example

Consider for example, that an independent model of the operation of a single elevator needs know nothing of the user interfaces (UI) or system interfaces (SI) dependent on it. There might be a diagnostics UI written in `Flutter`, a console (CUI) interface, as well as as a module that only exposes a programmatic interface (API) that external programs might consume to control the elevator.

![](https://drive.google.com/uc?export=view&id=1kKIBEYcPkZVEzZmCEb_RX_RnlbfXMw92)

There might be other 'consumers' of the domain model, but the model need not care as it knows nothing of them.

Or does it need to?

How do these 'consumers' know when something has happened in the model? In the case of the elevator, the model might be connected to a real physical elevator through a manufacturer supplied control library, which in turn talks to the elevator's programmable logic controller (PLC).

How can the physical elevator report that something happened through the control library to the model, and in turn to each of the three (or more) consumers? The model knows nothing of its consumers. Likewise, an independent manufacturers control library knows nothing of your elevator domain model.

> How can something that is independent and in a separate module (package), notify a consumer it doesn't know, that something has happened?

##### The solution

The answer provided in this package, is to model an Event that can be published by an independent module (package), and subscribed to by a consumer elsewhere. An Event represents that something has happened. It can be created and broadcast (triggered) without the publisher having any connection to those that might be consuming it.

In the case of the elevator, the manufacturer's control library can indicate that something in the real elevator happened (via the PLC) by publishing an Event. The domain model can subscribe to those Events where applicable, and cause some change in the model if required - perhaps updating the floor the current elevator is on.

Likewise, the domain model can publish Events which the three consumers of the model can choose to subscribe to.

Note that the three consumers of the model, as well as the model in relation to the elevator control library, remain _independent_.



// TODO: show example of "Named Event Pattern".


## Examples

Two examples are shown below. The first shows a Counter example where incrementing the counter is broadcast without any argument provided to handlers (subscribers). The second shows the same, but with the incremented Counter value being provided as a custom argument to subscribers.

#### Example 1: A simple increment Event with no argument

```dart
import 'package:event/event.dart';

void main() {
  /// The counter class is defined further below.
  var c = Counter();

  // Subscribe to the custom event
  c.valueChangedEvent.subscribe((args) => print(c.count));

  c.increment();
  c.increment();
  c.reset();

  // outputs...
  // 1
  // 2
  // 0
}

//-----------------

/// Represents a number counter that can be incremented.
/// Notifies [Event] handlers (subscribers) when incremented.
class Counter {
  /// The current [Counter] value.
  int count = 0;

  /// A custom [Event]
  final valueChangedEvent = Event();

  /// Increment the [Counter] [value] by 1.
  void increment() {
    count++;
    valueChangedEvent.broadcast(); // Broadcast the change
  }

  /// Reset the [Counter] value to 0.
  void reset() {
    count = 0;
    valueChangedEvent.broadcast(); // Broadcast the change
  }
}
```

#### Example 2: A simple increment Event with a custom event argument

```dart
import 'package:event/event.dart';

void main() {
   /// An incrementing counter.
  var c = Counter();

  // Subscribe to the custom event
  c.countChangedEvent.subscribe((args) => print('now ${args.value}'));

  c.increment();
  c.increment();
  c.reset();

  // outputs...
  // now 1
  // now 2
  // now 0
}

//-----------------

/// Represents a number counter that can be incremented.
/// Notifies [Event] handlers (subscribers) when incremented.
/// The broadcast notification includes the changed [value] as an argument
/// See the [Incremented] class that follows.
class Counter {
  /// The current [Counter] count.
  int count = 0;

  /// A custom [Event] with custom argument [MyArgs]
  /// See [MyArgs] class below.
  final countChangedEvent = Event<MyArgs>();

  /// Increment the [Counter] [count] by 1.
  void increment() {
    count++;
    countChangedEvent.broadcast(MyArgs(count)); // Broadcast including the incremented value

  }

  /// Reset the [Counter] [value] to 0.
  void reset() {
    value = 0;
    countChangedEvent.broadcast(MyArgs(count)); // Broadcast the reset value
  }
}

//-----------------

/// Represents the arguments provided to handlers
/// when an [Event] occurs.
class MyArgs extends EventArgs {
  int value;
  MyArgs(this.value);
}
```

Note: the example above uses a custom `EventArgs` class `MyArgs` representing an `int` value. One could have instead used the provided `Value<T>` argument helper instead.

.END.

[eventsubscriber]: https://pub.dev/packages/eventsubscriber
[tracker]: https://github.com/aryehof/dart-event/issues
[changelog]: https://pub.dev/packages/event/changelog
