# USBDevice

A focused Swift wrapper around Apple’s `IOUSBHost` framework that makes USB device access on macOS simpler and safer. It provides lightweight types for devices, interfaces, and endpoints, plus helpers for control requests, descriptor access, and pipe-based data exchange, while translating raw `IOReturn` failures into a typed `USBHostError`.

Use this package when you need to:

- Discover or match USB devices and interfaces using the package’s matching dictionary helpers.
- Inspect device/interface/endpoint metadata (IDs, names, configuration info).
- Issue control transfers or access descriptors without repeating boilerplate error handling.
- Perform data exchange through endpoint pipes exposed by the package’s endpoint wrapper.

It is most appropriate for macOS utilities, diagnostics tools, or hardware-facing apps that already rely on `IOUSBHost` and want a cleaner Swift surface for device, interface, and endpoint access.

## Package Types

### `USBDevice`

Represents a USB device handle and caches core device metadata (vendor/product IDs, strings, configuration counts). It also exposes configuration, reset, and descriptor helpers through shared APIs.

### `USBDevice.USBInterface`

Represents a device interface and caches interface metadata (name, interface number, alternate setting, endpoint count). It also provides helpers for alternate settings and pipe access.

### `USBDevice.USBInterface.USBEndpoint`

Represents an endpoint pipe for data exchange. It exposes endpoint metadata (direction, transfer type, packet size) and wraps control/bulk/interrupt operations used internally by the package.

### `USBObject`

Shared protocol for common behaviors across device and interface types, including lifecycle management, descriptors, and control requests.

### `USBHostError`

Typed error wrapper for `IOReturn` values, enabling predictable error handling in Swift.

## Installation

Add the package to your `Package.swift` dependencies using its Git URL:

```swift
dependencies: [
    .package(url: "https://github.com/Emerah/USBDevice.git", branch: "main")
]
```

Then include `USBDevice` in your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["USBDevice"]
    )
]
```

## Usage

The package wraps USB device and interface handles you already obtain from your discovery flow, then provides a cleaner Swift surface for metadata, control requests, and pipe access.

If you need discovery and hot-plug handling, see `USBConnection` at `https://github.com/Emerah/USBConnection.git`, which provides a service to obtain device `io_service_t` handles.

At a high level, the flow is:

1. Discover a device or interface using `IOUSBHost` or IOKit.
2. Create a `USBDevice` or `USBDevice.USBInterface` from the handle.
3. Use the wrapper APIs for metadata, control requests, or pipes.

Example using an `io_service_t` obtained from your IOKit discovery:

```swift
// Assume `service` is an io_service_t for a USB device.
let deviceHandle = try IOUSBHostDevice(__ioService: service, options: [], queue: DispatchQueue.main, interestHandler: nil)
let device = USBDevice(handle: deviceHandle)

let interface = try device.interface(0, alternateSetting: 0)
let endpoint = try interface.copyPipe(address: 0x81)
,,,

## Public API overview

### USBDevice

- `handle`
- `init(handle:)`
- `matchingDictionary(vendorID:productID:bcdDevice:deviceClass:deviceSubclass:deviceProtocol:speed:productIDs:)`
- `configure(value:matchInterfaces:)`
- `configure(value:)`
- `currentConfigurationDescriptor`
- `reset()`
- `vendorID`
- `productID`
- `name`
- `manufacturer`
- `serialNumber`
- `interfaceCount`
- `configurationCount`
- `currentConfigurationValue`
- `interface(_:alternateSetting:)`

### USBDevice.USBInterface

- `handle`
- `createMatchingDictionary(vendorID:productID:bcdDevice:interfaceNumber:configurationValue:interfaceClass:interfaceSubClass:interfaceProtocol:speed:productIDArray:)`
- `idleTimeout`
- `setIdleTimeout(_:)`
- `configurationDescriptor`
- `interfaceDescriptor`
- `selectAlternateSetting(_:)`
- `copyPipe(address:)`
- `name`
- `endpointCount`
- `interfaceNumber`
- `alternateSetting`

### USBDevice.USBInterface.USBEndpoint

- `originalDescriptors`
- `descriptors`
- `hostInterface`
- `adjust(descriptors:)`
- `idleTimeout`
- `setIdleTimeout(_:)`
- `clearStall()`
- `abort(option:)`
- `sendControlRequest(_:data:timeout:)`
- `enqueueControlRequest(_:data:timeout:completion:)`
- `enqueueControlRequest(_:data:timeout:)`
- `sendIORequest(data:timeout:)`
- `enqueueIORequest(data:timeout:completionHandler:)`
- `enqueueIORequest(data:timeout:)`
- `enableStreams()`
- `disableStreams()`
- `copyStream(streamID:)`
- `endpointAddress`
- `maxPacketSize`
- `direction`
- `transferType`
- `pollInterval`
- `USBEndpointDirection`
- `USBEndpointTransferType`


