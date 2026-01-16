// Package: USBDevice
// File: USBDevice.swift
// Path: Sources/USBDevice/USBDevice.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost


// TODO: - ADD IOMessage translation to handle interest notifications

/// USB device wrapper around `IOUSBHostDevice`.
public final class USBDevice: USBObject {
    
    /// Concrete USB host handle type for this object.
    public typealias USBHandle = IOUSBHostDevice
    
    /// Underlying IOUSBHost device handle.
    public let handle: IOUSBHostDevice
    private let metadata: MetaData
    private let interfaceCacheQueue = DispatchQueue(label: "usbdevice.interfacesCache")
    private var interfaces: [InterfaceSelection: USBInterface] = [:]
    
    /// Creates a device wrapper and captures immutable metadata from the handle.
    /// - Parameter handle: The underlying `IOUSBHostDevice`.
    public init(handle: IOUSBHostDevice) {
        self.handle = handle
        let metadata = Self.retrieveDeviceMetadata(from: handle)
        self.metadata = metadata
    }
    
    public convenience init(
        service: io_service_t,
        options: IOUSBHostObjectInitOptions,
        queue: DispatchQueue?,
        interestHandler: IOUSBHostInterestHandler?
    ) throws(USBHostError) {
        do {
            let handle = try IOUSBHostDevice(__ioService: service, options: options, queue: queue, interestHandler: interestHandler)
            self.init(handle: handle)
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    public func destroy() {
        clearInterfaceCache()
        handle.destroy()
    }
}


// MARK: - Matching dictionary
/// Matching dictionary helpers for device discovery.
extension USBDevice {
    
    /// Creates a matching dictionary used to discover USB devices.
    /// - Parameters:
    ///   - vendorID: Optional vendor ID filter.
    ///   - productID: Optional product ID filter.
    ///   - bcdDevice: Optional BCD device version filter.
    ///   - deviceClass: Optional device class filter.
    ///   - deviceSubclass: Optional device subclass filter.
    ///   - deviceProtocol: Optional device protocol filter.
    ///   - speed: Optional device speed filter.
    ///   - productIDs: Optional list of product IDs to match.
    /// - Returns: A Core Foundation mutable dictionary for IOKit matching.
    public static func createMatchingDictionary(
        vendorID: Int? = nil,
        productID: Int? = nil,
        bcdDevice: Int? = nil,
        deviceClass: Int? = nil,
        deviceSubclass: Int? = nil,
        deviceProtocol: Int? = nil,
        speed: Int? = nil,
        productIDs: [Int]? = nil
    ) -> CFMutableDictionary {
        let vendorNum   = vendorID.map(NSNumber.init(value:))
        let productNum  = productID.map(NSNumber.init(value:))
        let bcdNum      = bcdDevice.map(NSNumber.init(value:))
        let classNum    = deviceClass.map(NSNumber.init(value:))
        let subclassNum = deviceSubclass.map(NSNumber.init(value:))
        let protoNum    = deviceProtocol.map(NSNumber.init(value:))
        let speedNum    = speed.map(NSNumber.init(value:))
        let productArray: [NSNumber]? = productIDs?.map(NSNumber.init(value:))
        
        let dict = IOUSBHostDevice.__createMatchingDictionary(
            withVendorID: vendorNum,
            productID: productNum,
            bcdDevice: bcdNum,
            deviceClass: classNum,
            deviceSubclass: subclassNum,
            deviceProtocol: protoNum,
            speed: speedNum,
            productIDArray: productArray
        )
        
        return dict.takeRetainedValue()
    }
}


// MARK: - Configuration
/// Configuration helpers for selecting the active device configuration.
extension USBDevice {
    
    /// Configures the device with the specified configuration value.
    /// - Parameters:
    ///   - value: The configuration value to select.
    ///   - matchInterfaces: Whether to match and open interfaces after configuring.
    /// - Throws: `USBHostError` if configuration fails.
    public func configure(value: Int, matchInterfaces: Bool) throws(USBHostError) {
        do {
            try handle.__configure(withValue: value, matchInterfaces: matchInterfaces)
        } catch {
            throw USBHostError.translated(error)
        }
        
        clearInterfaceCache()
    }
    
    /// Configures the device with the specified configuration value.
    /// - Parameter value: The configuration value to select.
    /// - Throws: `USBHostError` if configuration fails.
    public func configure(value: Int) throws(USBHostError) {
        try configure(value: value, matchInterfaces: true)
    }
}

// MARK: - Device state
/// Device descriptor access and reset helpers.
extension USBDevice {
    
    /// Current configuration descriptor for the active configuration, if available.
    public var currentConfigurationDescriptor: UnsafePointer<IOUSBConfigurationDescriptor>? {
        handle.configurationDescriptor
    }
    
    /// Resets the device.
    /// - Throws: `USBHostError` if the reset fails.
    public func reset() throws(USBHostError) {
        do {
            try handle.reset()
        } catch {
            throw USBHostError.translated(error)
        }
        
        clearInterfaceCache()
    }
}


// MARK: - Metadata
/// Read-only metadata captured from the device at initialization.
extension USBDevice {
    /// Vendor ID from the device descriptor.
    public var vendorID: UInt16 {
        metadata.vendorID
    }
    
    /// Product ID from the device descriptor.
    public var productID: UInt16 {
        metadata.productID
    }
    
    /// Product name string, if available.
    public var name: String {
        metadata.name
    }
    
    /// Manufacturer string, if available.
    public var manufacturer: String {
        metadata.manufacturer
    }
    
    /// Serial number string, if available.
    public var serialNumber: String {
        metadata.serialNumber
    }
    
    /// Number of interfaces in the current configuration.
    public var interfaceCount: UInt8 {
        metadata.interfaceCount
    }
    
    /// Number of configurations supported by the device.
    public var configurationCount: UInt8 {
        metadata.configurationCount
    }
    
    /// Current configuration value.
    public var currentConfigurationValue: UInt8 {
        metadata.currentConfigurationValue
    }
}


// MARK: - Metadata support
/// Internal metadata capture from the device descriptors.
extension USBDevice {
    
    /// Immutable metadata extracted from the device and configuration descriptors.
    fileprivate struct MetaData {
        fileprivate let vendorID: UInt16
        fileprivate let productID: UInt16
        fileprivate let name: String
        fileprivate let manufacturer: String
        fileprivate let serialNumber: String
        fileprivate let configurationCount: UInt8
        fileprivate let interfaceCount: UInt8
        fileprivate let currentConfigurationValue: UInt8
        
        fileprivate static let `default` = MetaData(
            vendorID: 0,
            productID: 0,
            name: "",
            manufacturer: "",
            serialNumber: "",
            configurationCount: 0,
            interfaceCount: 0,
            currentConfigurationValue: 0
        )
    }
    
    /// Retrieves device metadata from the provided handle.
    /// - Parameter handle: The `IOUSBHostDevice` handle to inspect.
    /// - Returns: Captured device metadata, or default values on failure.
    private static func retrieveDeviceMetadata(from handle: IOUSBHostDevice) -> MetaData {
        guard
            let deviceDescriptor = handle.deviceDescriptor,
            let configurationDescriptor = handle.configurationDescriptor
        else {
            return .default
        }
        
        let vendorID = deviceDescriptor.pointee.idVendor
        let productID = deviceDescriptor.pointee.idProduct
        var name: String
        var manufacturer: String
        var serialNumber: String
        let languageID = Int(kIOUSBLanguageIDEnglishUS.rawValue)
        
        do {
            name = try handle.__string(with: Int(deviceDescriptor.pointee.iProduct), languageID: languageID)
            manufacturer = try handle.__string(with: Int(deviceDescriptor.pointee.iManufacturer), languageID: languageID)
            serialNumber = try handle.__string(with: Int(deviceDescriptor.pointee.iSerialNumber), languageID: languageID)
        } catch {
            name = "Undefined"
            manufacturer = "Undefined"
            serialNumber = "Undefined"
        }
        
        let configurationCount = deviceDescriptor.pointee.bNumConfigurations
        let interfaceCount = configurationDescriptor.pointee.bNumInterfaces
        let currentConfigurationValue = configurationDescriptor.pointee.bConfigurationValue
        
        return MetaData(
            vendorID: vendorID,
            productID: productID,
            name: name,
            manufacturer: manufacturer,
            serialNumber: serialNumber,
            configurationCount: configurationCount,
            interfaceCount: interfaceCount,
            currentConfigurationValue: currentConfigurationValue
        )
    }
}


// MARK: - Request interface
/// Interface discovery and caching helpers for this device.
extension USBDevice {
    
    /// Cache key identifying a specific interface/alternate-setting pair.
    private struct InterfaceSelection: Hashable, Sendable {
        private let interfaceNumber: UInt8
        private let alternateSetting: UInt8
        fileprivate init(interfaceNumber: UInt8, alternateSetting: UInt8) {
            self.interfaceNumber = interfaceNumber
            self.alternateSetting = alternateSetting
        }
    }
    
    /// Returns the IOKit service for the specified interface number.
    /// - Parameter number: The interface number to locate.
    /// - Returns: A retained `io_service_t` for the interface.
    /// - Throws: `USBHostError` if no matching interface is found.
    private func serviceForInterface(number: UInt8) throws -> io_service_t {
        var iterator = io_iterator_t()
        let status = IORegistryEntryGetChildIterator(ioService, kIOServicePlane, &iterator)
        guard status == KERN_SUCCESS, iterator != IO_OBJECT_NULL else {
            throw USBHostError.translated(status: status)
        }
        
        defer { IOObjectRelease(iterator) }
        
        while case let service = IOIteratorNext(iterator), service != IO_OBJECT_NULL {
            if IOObjectConformsTo(service, kIOUSBHostInterfaceClassName) != 0,
               isValidInterface(service, interfaceNumber: number) {
                return service
            }
            
            IOObjectRelease(service)
        }
        
        throw USBHostError.invalid
    }
    
    /// Validates that an interface service matches the requested number and configuration.
    /// - Parameters:
    ///   - service: The `io_service_t` to inspect.
    ///   - interfaceNumber: The interface number to match.
    /// - Returns: `true` if the service matches the current configuration and interface number.
    private func isValidInterface(_ service: io_service_t, interfaceNumber: UInt8) -> Bool {
        guard
            let number = propertyNumber(IOUSBHostMatchingPropertyKey.interfaceNumber.rawValue, service: service),
            let configuration = propertyNumber(IOUSBHostMatchingPropertyKey.configurationValue.rawValue, service: service)
        else {
            return false
        }
        return number == interfaceNumber && configuration == metadata.currentConfigurationValue
    }
    
    /// Returns a USB interface for the specified number and alternate setting.
    /// - Parameters:
    ///   - number: The interface number to open.
    ///   - alternateSetting: The alternate setting to select after opening.
    /// - Returns: The opened `USBInterface`.
    /// - Throws: `USBHostError` if the interface cannot be opened or configured.
    public func interface(_ number: UInt8, alternateSetting: UInt8 = 0) throws -> USBInterface {
        let selection = InterfaceSelection(interfaceNumber: number, alternateSetting: alternateSetting)
        
        return try interfaceCacheQueue.sync {
            if let cached = interfaces[selection] { return cached }
            
            let service = try serviceForInterface(number: number)
            defer { IOObjectRelease(service) }
            
            let interfaceHandle = try IOUSBHostInterface(
                __ioService: service,
                options: [.deviceSeize],
                queue: queue,
                interestHandler: nil
            )
            
            let usbInterface = USBInterface(handle: interfaceHandle)
            do {
                if alternateSetting != 0 {
                    try usbInterface.selectAlternateSetting(Int(alternateSetting))
                }
            } catch {
                usbInterface.destroy()
                throw USBHostError.translated(error)
            }
            
            interfaces[selection] = usbInterface
            return usbInterface
        }
    }
    
    /// Reads a numeric property from an IOKit service.
    /// - Parameters:
    ///   - key: The IOKit registry property key.
    ///   - service: The `io_service_t` to read from.
    /// - Returns: The numeric value as `UInt8`, if available.
    private func propertyNumber(_ key: String, service: io_service_t) -> UInt8? {
        guard let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        else { return nil }
        
        guard let number = value as? NSNumber
        else { return nil }
        
        return number.uint8Value
    }
    
    /// Returns a cached interface for the specified selection, if available.
    private func cachedInterface(for key: InterfaceSelection) -> USBInterface? {
        interfaceCacheQueue.sync {
            interfaces[key]
        }
    }
        
    /// Stores an interface in the cache for the specified selection.
    private func store(interface: USBInterface, for key: InterfaceSelection) {
        interfaceCacheQueue.sync {
            interfaces[key] = interface
        }
    }
    
    /// closes open interfaces and clears interface cache.
    private func clearInterfaceCache() {
      interfaceCacheQueue.sync {
          interfaces.values.forEach { $0.destroy() }
          interfaces.removeAll()
      }
  }
    
}
