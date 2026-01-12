// Package: USBDevice
// File: USBInterface.swift
// Path: Sources/USBDevice/USBInterface.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost

extension USBDevice {
    /// USB interface wrapper around `IOUSBHostInterface`.
    public final class USBInterface: USBObject {
        
        /// Concrete USB host handle type for this object.
        public typealias USBHandle = IOUSBHostInterface
        
        /// Underlying IOUSBHost interface handle.
        public let handle: IOUSBHostInterface
        private let metadata: MetaData

        /// Creates an interface wrapper and captures immutable metadata from the handle.
        /// - Parameter handle: The underlying `IOUSBHostInterface`.
        internal init(handle: IOUSBHostInterface) {
            self.handle = handle
            let metadata = Self.retrieveInterfaceMetadata(from: handle)
            self.metadata = metadata
        }
        
        internal convenience init(
            service: io_service_t,
            options: IOUSBHostObjectInitOptions,
            queue: DispatchQueue?,
            interestHandler: IOUSBHostInterestHandler?
        ) throws(USBHostError) {
            do {
                let handle = try IOUSBHostInterface(__ioService: service, options: options, queue: queue, interestHandler: interestHandler)
                self.init(handle: handle)
            } catch {
                throw USBHostError.translated(error)
            }
        }
    }
}


// MARK: - Create matching dictionary
/// Matching dictionary helpers for interface discovery.
extension USBDevice.USBInterface {
    /// Creates a matching dictionary used to discover USB interfaces.
    /// - Parameters:
    ///   - vendorID: Optional vendor ID filter.
    ///   - productID: Optional product ID filter.
    ///   - bcdDevice: Optional BCD device version filter.
    ///   - interfaceNumber: Optional interface number filter.
    ///   - configurationValue: Optional configuration value filter.
    ///   - interfaceClass: Optional interface class filter.
    ///   - interfaceSubClass: Optional interface subclass filter.
    ///   - interfaceProtocol: Optional interface protocol filter.
    ///   - speed: Optional interface speed filter.
    ///   - productIDArray: Optional list of product IDs to match.
    /// - Returns: A Core Foundation mutable dictionary for IOKit matching.
    public static func createMatchingDictionary(
        vendorID: NSNumber? = nil,
        productID: NSNumber? = nil,
        bcdDevice: NSNumber? = nil,
        interfaceNumber: NSNumber? = nil,
        configurationValue: NSNumber? = nil,
        interfaceClass: NSNumber? = nil,
        interfaceSubClass: NSNumber? = nil,
        interfaceProtocol: NSNumber? = nil,
        speed: NSNumber? = nil,
        productIDArray: [NSNumber]? = nil
    ) -> CFMutableDictionary {
        let dict = IOUSBHostInterface.__createMatchingDictionary(
            withVendorID: vendorID,
            productID: productID,
            bcdDevice: bcdDevice,
            interfaceNumber: interfaceNumber,
            configurationValue: configurationValue,
            interfaceClass: interfaceClass,
            interfaceSubclass: interfaceSubClass,
            interfaceProtocol: interfaceProtocol,
            speed: speed,
            productIDArray: productIDArray
        )
        
        return dict.takeRetainedValue()
    }
}


// MARK: - Power management
/// Power management helpers for interface idle behavior.
extension USBDevice.USBInterface {
    
    /// Idle timeout value for the interface.
    public var idleTimeout: TimeInterval {
        handle.idleTimeout
    }
    
    /// Sets the interface idle timeout.
    /// - Parameter timeout: The idle timeout in seconds.
    /// - Throws: `USBHostError` if the timeout cannot be set.
    public func setIdleTimeout(_ timeout: TimeInterval) throws(USBHostError) {
        do {
            try handle.setIdleTimeout(timeout)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Descriptors
/// Descriptor accessors for the interface and configuration.
extension USBDevice.USBInterface {
    
    /// Configuration descriptor associated with this interface.
    public var configurationDescriptor: UnsafePointer<IOUSBConfigurationDescriptor> {
        handle.configurationDescriptor
    }
    
    /// Interface descriptor for this interface.
    public var interfaceDescriptor: UnsafePointer<IOUSBInterfaceDescriptor> {
        handle.interfaceDescriptor
    }
}


// MARK: - Alternate settings & pipes
/// Alternate setting selection and pipe accessors.
extension USBDevice.USBInterface {
    
    /// Selects the specified alternate setting.
    /// - Parameter alternateSetting: The alternate setting to select.
    /// - Throws: `USBHostError` if selection fails.
    public func selectAlternateSetting(_ alternateSetting: Int) throws(USBHostError) {
        do {
            try handle.selectAlternateSetting(alternateSetting)
        } catch {
            throw USBHostError.translated(error)
        }
    }

    /// Copies a pipe with the specified endpoint address.
    /// - Parameter address: The endpoint address to copy.
    /// - Returns: `USBEndpoint` wrapping the copied `IOUSBHostPipe` instance .
    /// - Throws: `USBHostError` if the pipe cannot be copied.
    public func copyEndpoint(address: UInt8) throws(USBHostError) -> USBEndpoint {
        do {
            let pipe = try handle.copyPipe(withAddress: Int(address))
            return USBEndpoint(handle: pipe)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Metadata
/// Read-only metadata captured from the interface at initialization.
extension USBDevice.USBInterface {
    /// Interface name string, if available.
    public var name: String {
        metadata.name
    }

    /// Number of endpoints in the interface.
    public var endpointCount: UInt8 {
        metadata.endpointCount
    }

    /// Interface number from the descriptor.
    public var interfaceNumber: UInt8 {
        metadata.interfaceNumber
    }

    /// Alternate setting number from the descriptor.
    public var alternateSetting: UInt8 {
        metadata.alternateSetting
    }
}
// MARK: - Metadata support
/// Internal metadata capture from the interface descriptors.
extension USBDevice.USBInterface {
    /// Immutable metadata extracted from the interface descriptor.
    fileprivate struct MetaData {
        fileprivate let name: String
        fileprivate let endpointCount: UInt8
        fileprivate let interfaceNumber: UInt8
        fileprivate let alternateSetting: UInt8
    }

    /// Retrieves interface metadata from the provided handle.
    /// - Parameter handle: The `IOUSBHostInterface` handle to inspect.
    /// - Returns: Captured interface metadata.
    private static func retrieveInterfaceMetadata(from handle: IOUSBHostInterface) -> MetaData {
        let descriptor = handle.interfaceDescriptor.pointee
        let endpointCount = descriptor.bNumEndpoints
        let interfaceNumber = descriptor.bInterfaceNumber
        let alternateSetting = descriptor.bAlternateSetting
        let languageID = Int(kIOUSBLanguageIDEnglishUS.rawValue)
        var name: String
        do {
            name = try handle.__string(with: Int(descriptor.iInterface), languageID: languageID)
        } catch {
            name = "Undefined"
        }

        return MetaData(name: name, endpointCount: endpointCount, interfaceNumber: interfaceNumber, alternateSetting: alternateSetting)
    }
}
