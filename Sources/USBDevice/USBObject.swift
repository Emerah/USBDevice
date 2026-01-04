// Package: USBDevice
// File: USBObject.swift
// Path: Sources/USBDevice/USBObject.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost


public protocol USBObject {
    associatedtype USBHandle: IOUSBHostObject
    var handle: USBHandle { get }
}


// MARK: - Session management / creation
extension USBObject {
    public var ioService: io_service_t {
        handle.ioService
    }
    
    public var queue: DispatchQueue {
        handle.queue
    }
    
    public func destroy() {
        handle.destroy()
    }
    
    public func destroy(options: IOUSBHostObjectDestroyOptions) {
        handle.destroy(options: options)
    }
}

// MARK: - Synchronous control requests
extension USBObject {
    
    public func sendDeviceRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout
    ) throws(USBHostError) -> Int {
        var bytesTransferred: Int = 0
        do {
            try handle.__send(request, data: data, bytesTransferred: &bytesTransferred, completionTimeout: timeout)
        } catch {
            throw USBHostError.translated(error)
        }
        return bytesTransferred
    }
    
    public func sendDeviceRequest(_ request: IOUSBDeviceRequest, timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout) throws(USBHostError) {
        do {
            try handle.__send(request, data: nil, bytesTransferred: nil, completionTimeout: timeout)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Asynchronous control requests
extension USBObject {
    
    public func enqueueDeviceRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout,
        completion: @Sendable @escaping (IOReturn, Int) -> Void
    ) throws(USBHostError) {
        do {
            try handle.__enqueue(request, data: data, completionTimeout: timeout, completionHandler: completion)
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    public func enqueueDeviceRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout
    ) async throws(USBHostError) -> Int {
        do {
            let (status, bytesTransferred) = try await handle.__enqueue(request, data: data, completionTimeout: timeout)
            if status == kIOReturnSuccess {
                return Int(bytesTransferred)
            } else {
                throw USBHostError.translated(status: status)
            }
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    public func abortDeviceRequests(option: IOUSBHostAbortOption = .synchronous) throws(USBHostError) {
        do {
            try handle.__abortDeviceRequests(with: option)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Descriptor helpers
extension USBObject {
    
    public func descriptor(
        type: tIOUSBDescriptorType,
        maxLength: inout Int,
        index: Int,
        languageID: Int,
        requestType: tIOUSBDeviceRequestTypeValue,
        requestRecipient: tIOUSBDeviceRequestRecipientValue
    ) throws(USBHostError) -> UnsafePointer<IOUSBDescriptor>? {
        var lengthStorage = maxLength
        let ptr: UnsafePointer<IOUSBDescriptor>?
        do {
            ptr = try handle.__descriptor(
                with: type,
                length: &lengthStorage,
                index: index,
                languageID: languageID,
                requestType: requestType,
                requestRecipient: requestRecipient
            )
        } catch {
            throw USBHostError.translated(error)
        }
        
        maxLength = lengthStorage
        return ptr
    }
    
    public var deviceDescriptorPtr: UnsafePointer<IOUSBDeviceDescriptor>? {
        handle.deviceDescriptor
    }
    
    public var capabilityDescriptorsPtr: UnsafePointer<IOUSBBOSDescriptor>? {
        handle.capabilityDescriptors
    }
    
    public func configurationDescriptor(configurationValue: Int) throws(USBHostError) -> UnsafePointer<IOUSBConfigurationDescriptor>? {
        do {
            return try handle.configurationDescriptor(withConfigurationValue: configurationValue)
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    public func stringDescriptor(index: Int, languageID: Int = Int(kIOUSBLanguageIDEnglishUS.rawValue)) throws(USBHostError) -> String? {
        do {
            return try handle.__string(with: Int(index), languageID: languageID)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Misc
extension USBObject {
    public var deviceAddress: Int {
        handle.deviceAddress
    }
    
    public var currentFrameNumber: UInt64 {
        handle.__frameNumber(withTime: nil)
    }
    
    public func frameNumber(with time: inout IOUSBHostTime) -> UInt64 {
        withUnsafeMutablePointer(to: &time) { ptr in
            handle.__frameNumber(withTime: ptr)
        }
    }
    
    internal func makeIOData(capacity: Int) throws(USBHostError) -> NSMutableData {
        do {
            return try handle.ioData(withCapacity: capacity)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}
