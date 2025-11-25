<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

<h1 align="center">Floating Bottom Bar</h1>

<p align="center">A flutter package which allows to show a floating widget which can be used as a tab bar, bottom navigation bar or anything one can think of. The widget reacts to scrolling events too.</p><br>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter"
      alt="Platform" />
  </a>
  <a href="https://pub.dartlang.org/packages/flutter_floating_bottom_bar">
    <img src="https://img.shields.io/pub/v/flutter-floating-bottom-bar.svg"
      alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/codenameakshay/flutter-floating-bottom-bar?color=red"
      alt="License: MIT" />
  </a>
  <a href="https://www.paypal.me/codenameakshay">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal"
      alt="Donate" />
  </a>
</p><br>

| ![A floating tab bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/1.gif) | ![A floating search bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/2.gif) | ![A basic example](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/3.gif) |
| -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **A floating tab bar**                                                                                                     | **A floating search bar**                                                                                                     | **A basic example**                                                                                                     |

| ![image](https://user-images.githubusercontent.com/60510869/183573165-28e6b896-6559-4d86-897a-3bc8b0adb927.png) |
| --------------------------------------------------------------------------------------------------------------- |
| **A floating tab bar with a FAB**                                                                               |

## Features

The package allows you to create a floating widget like a bottom navigation bar that reacts to scrolling events.

- It can be used as a tab bar, bottom navigation bar or anything one can think of.
- It reacts to scrolling events too.
- It can be used in a full screen app or in a smaller screen.

## Installing

### 1. Depend on it

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_floating_bottom_bar: ^1.3.0
```

### 2. Install it

You can install packages from the command line:

with `pub`:

```
pub get
```

with `Flutter`:

```
flutter pub get
```

### 3. Import it

Now in your `Dart` code, you can use:

```dart
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
```

# Usage

`BottomBar` is a _Widget_ that can be wrapped over any child to convert it into a bottom bar.
Below is the most simple use:

```dart
    BottomBar(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "This is the floating widget",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: (context, controller) =>
              InfiniteListPage(controller: controller, color: Colors.blue,),
    )
```

It needs two required arguments -

- `child` – This is the child inside the `BottomBar` (widget which is floating)
- `body` – The widget displayed below the `BottomBar` (like your main app)

# Detailed Usage

Below is the detailed usage of the package, including all properties defined.

```dart
BottomBar(
          child: TabBar(), # A floating tab bar
          fit: StackFit.expand,
          icon: (width, height) => Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: unselectedColor,
                size: width,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(500),
          duration: Duration(seconds: 1),
          curve: Curves.decelerate,
          showIcon: true,
          width: MediaQuery.of(context).size.width * 0.8,
          barColor: colors[currentPage].computeLuminance() > 0.5 ? Colors.black : Colors.white,
          start: 2,
          end: 0,
          offset: 10,
          barAlignment: Alignment.bottomCenter,
          iconHeight: 35,
          iconWidth: 35,
          reverse: false,
          barDecoration: BoxDecoration(
            color: colors[currentPage],
            borderRadius: BorderRadius.circular(500),
          ),
          iconDecoration: BoxDecoration(
            color: colors[currentPage],
            borderRadius: BorderRadius.circular(500),
          ),
          hideOnScroll: true,
          scrollOpposite: false,
          onBottomBarHidden: () {},
          onBottomBarShown: () {},
          body: (context, controller) => TabBarView(
            controller: tabController,
            dragStartBehavior: DragStartBehavior.down,
            physics: const BouncingScrollPhysics(),
            children: [] # Add children here
          ),
        )
```

## icon

```dart
    icon: Center(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: null,
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: unselectedColor,
              ),
            ),
          ),
```

This is the scroll to top button. It will be hidden when the `BottomBar` is scrolled up. It will be shown when the `BottomBar` is scrolled down. Clicking it will scroll the bar on top.

You can hide this by using the `showIcon` property.

## iconWidth

```dart
    iconWidth: 35,
```

The width of the scroll to top button.

## iconHeight

```dart
    iconHeight: 35,
```

The height of the scroll to top button.

## barColor

```dart
     barColor: Colors.white,
```

The color of the `BottomBar`.

## end

```dart
     end: 0,
```

The end position in `y-axis` of the SlideTransition of the `BottomBar`.

## start

```dart
     start: 2,
```

The start position in `y-axis` of the SlideTransition of the `BottomBar`.

## offset

```dart
     offset: 10,
```

The padding/offset from all sides of the bar in double.

## duration

```dart
     duration: Duration(seconds: 1),
```

The duration of the `SlideTransition` of the `BottomBar`.

## curve

```dart
     curve: Curves.decelerate,
```

The curve of the `SlideTransition` of the `BottomBar`.

## width

```dart
     width: MediaQuery.of(context).size.width * 0.8,
```

The width of the `BottomBar`.

## borderRadius

```dart
     borderRadius: BorderRadius.circular(500),
```

The border radius of the `BottomBar`.

## showIcon

```dart
     showIcon: true,
```

If you don't want the scroll to top button to be visible, set this to `false`.

## barAlignment

```dart
     barAlignment: Alignment.bottomCenter,
```

The alignment of the Bar and the icon in the Stack in which the `BottomBar` is placed.

## onBottomBarShown

```dart
     onBottomBarShown: () {},
```

The callback when the `BottomBar` is shown i.e. on response to scroll events.

## onBottomBarHidden

```dart
     onBottomBarHidden: () {},
```

The callback when the `BottomBar` is hidden i.e. on response to scroll events.

## reverse

```dart
     reverse: true,
```

To reverse the direction in which the scroll reacts, i.e. if you want to make the bar visible when you scroll down and hide it when you scroll up, set this to `true`.

## scrollOpposite

```dart
     scrollOpposite: true,
```

To reverse the direction in which the scroll to top button scrolls, i.e. if you want to scroll to bottom, set this to `true`.

## hideOnScroll

```dart
     hideOnScroll: false,
```

If you don't want the bar to be hidden ever, set this to `false`.

## fit

```dart
     fit: StackFit.expand,
```

The fit property of the `Stack` in which the `BottomBar` is placed.

## clip

```dart
     clip: Clip.none,
```

The clipBehaviour property of the `Stack` in which the `BottomBar` is placed.

## respectSafeArea

```dart
     respectSafeArea: false,
```

Whether the BottomBar should respect the SafeArea. If set to false, the BottomBar will extend into the system UI areas (like the bottom navigation area on iOS). This gives you more layout flexibility when you need the BottomBar to overlap with system UI elements.

## barDecoration

```dart
     barDecoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(500),
          ),
```

The BoxDecoration for the `BottomBar`.

## iconDecoration

```dart
     iconDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(500),
          ),
```

The BoxDecoration for the scroll to top icon shown when `BottomBar` is hidden.

> Note - You can find more detailed examples in the `example` directory.

# Bugs or Requests

If you encounter any problems feel free to open an [issue](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/new?template=bug_report.md). If you feel the library is missing a feature, please raise a [ticket](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/new?template=feature_request.md) on GitHub and I'll look into it. Pull request are also welcome.

See [Contributing.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/master/CONTRIBUTING.md).
