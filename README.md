<p align="center">
    <img src="stampkit-icon.svg" width="256" align="middle" alt=“StampKit”/>
</p>

# StampKit
Communicate with [Stamp](https://stamp.xyz) servers from remote devices.

## Overview
The StampKit package provides the classes needed for your apps to communicate with Stamp.

**NOTE:** This package and the underlying [OSC](http://opensoundcontrol.org/introduction-osc) API is under active development and may change at any time...

## Installation

#### Xcode 11+
[Add the package dependency](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) to your Xcode project using the following repository URL: 
``` 
https://github.com/artifice-industries/StampKit
```
#### Swift Package Manager

Add the package dependency to your Package.swift and depend on "StampKit" in the necessary targets:

```  swift
dependencies: [
    .package(url: "https://github.com/artifice-industries/StampKit", .branch("master"))
]
```

## Usage

Import into your project files using Swift:

``` swift
import StampKit
```

### First Steps

Obtain a `SKTimeline` to use in your app.

#### Automatic

Using `SKBrowser` and providing it a delegate that implements the `SKBrowserDelegate` protocol, instances of Stamp servers can be automatically discovered. The browser has a `servers` property that is a set of `SKServerFacade` objects. Each `SKServerFacade` has a `timelines` property that holds a set of `SKTimeline` objects discovered on the network.

Create the `SKBrowser`:

``` swift
let browser = SKBrowser()
browser.delegate = self
browser.start()

// Optionally refresh the discovered servers.
browser.refresh(every: 3)
```

Conform to the `SKBrowserDelegate` protocol:

``` swift
func browser(_: SKBrowser, didUpdateTimelinesForServer server: SKServerFacade) {
    print(server.timelines)
}

func browser(_: SKBrowser, didUpdateServers servers: Set<SKServerFacade>) {
    print(server)
}
```

## Authors

**Sam Smallman** - [SammyTheHand](https://github.com/sammythehand)

See also the list of [contributors](https://github.com/artifice-industries/StampKit/graphs/contributors) who participated in this project.

## Acknowledgments

* Socket library dependency [CocoaSyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
* OSC library dependency [OSCKit](https://github.com/SammyTheHand/OSCKit)
