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
    public final class USBInterface: USBObject {
        
        public typealias USBHandle = IOUSBHostInterface
        
        public let handle: IOUSBHostInterface
        private let metadata: MetaData

        public init(handle: IOUSBHostInterface) {
            self.handle = handle
            let metadata = Self.retrieveInterfaceMetadata(from: handle)
            self.metadata = metadata
        }
    }
}


// MARK: - Create matching dictionary
extension USBDevice.USBInterface {
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
extension USBDevice.USBInterface {
    
    public var idleTimeout: TimeInterval {
        handle.idleTimeout
    }
    
    public func setIdleTimeout(_ timeout: TimeInterval) throws(USBHostError) {
        do {
            try handle.setIdleTimeout(timeout)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Descriptors
extension USBDevice.USBInterface {
    
    public var configurationDescriptor: UnsafePointer<IOUSBConfigurationDescriptor> {
        handle.configurationDescriptor
    }
    
    public var interfaceDescriptor: UnsafePointer<IOUSBInterfaceDescriptor> {
        handle.interfaceDescriptor
    }
}


// MARK: - Alternate settings & pipes
extension USBDevice.USBInterface {
    
    public func selectAlternateSetting(_ alternateSetting: Int) throws(USBHostError) {
        do {
            try handle.selectAlternateSetting(alternateSetting)
        } catch {
            throw USBHostError.translated(error)
        }
    }

    public func copyPipe(address: UInt8) throws(USBHostError) -> IOUSBHostPipe {
        do {
            let pipe = try handle.copyPipe(withAddress: Int(address))
            return pipe
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


extension USBDevice.USBInterface {
    public var name: String {
        metadata.name
    }

    public var endpointCount: UInt8 {
        metadata.endpointCount
    }

    public var interfaceNumber: UInt8 {
        metadata.interfaceNumber
    }

    public var alternateSetting: UInt8 {
        metadata.alternateSetting
    }
}
extension USBDevice.USBInterface {
    fileprivate struct MetaData {
        fileprivate let name: String
        fileprivate let endpointCount: UInt8
        fileprivate let interfaceNumber: UInt8
        fileprivate let alternateSetting: UInt8
    }

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
