<p align="center">
    <img src="stampkit-icon.svg" width="256" align="middle" alt=“StampKit”/>
</p>

# StampKit
Communicate with Stamp servers from remote devices.

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
