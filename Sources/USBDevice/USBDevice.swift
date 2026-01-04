// Package: USBDevice
// File: USBDevice.swift
// Path: Sources/USBDevice/USBDevice.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost





public final class USBDevice: USBObject {
    
    public typealias USBHandle = IOUSBHostDevice
    
    public let handle: IOUSBHostDevice
    private let metadata: MetaData
    
    public init(handle: IOUSBHostDevice) {
        self.handle = handle
        let metadata = Self.retrieveDeviceMetadata(from: handle)
        self.metadata = metadata
    }
}


extension USBDevice {
    
    public static func matchingDictionary(
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


extension USBDevice {
    
    public func configure(value: Int, matchInterfaces: Bool) throws(USBHostError) {
        do {
            try handle.__configure(withValue: value, matchInterfaces: matchInterfaces)
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    public func configure(value: Int) throws(USBHostError) {
        try configure(value: value, matchInterfaces: true)
    }
}

extension USBDevice {
    
    public var currentConfigurationDescriptor: UnsafePointer<IOUSBConfigurationDescriptor>? {
        handle.configurationDescriptor
    }
    
    public func reset() throws(USBHostError) {
        do {
            try handle.reset()
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


extension USBDevice {
    public var vendorID: UInt16 {
        metadata.vendorID
    }
    
    public var productID: UInt16 {
        metadata.productID
    }
    
    public var name: String {
        metadata.name
    }
    
    public var manufacturer: String {
        metadata.manufacturer
    }
    
    public var serialNumber: String {
        metadata.serialNumber
    }
    
    public var interfaceCount: UInt8 {
        metadata.interfaceCount
    }
    
    public var configurationCount: UInt8 {
        metadata.configurationCount
    }
    
    public var currentConfigurationValue: UInt8 {
        metadata.currentConfigurationValue
    }
}


extension USBDevice {
    
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
