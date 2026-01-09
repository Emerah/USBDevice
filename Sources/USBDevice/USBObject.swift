// Package: USBDevice
// File: USBObject.swift
// Path: Sources/USBDevice/USBObject.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost


/// Common USB handle surface shared by device, interface types.
public protocol USBObject {
    associatedtype USBHandle: IOUSBHostObject
    /// Underlying IOUSBHost handle for the object instance.
    var handle: USBHandle { get }
}


// MARK: - Session management / creation
/// Session lifecycle helpers that forward to the underlying IOUSBHostObject.
extension USBObject {
    /// IOKit service backing the USB object.
    public var ioService: io_service_t {
        handle.ioService
    }
    
    /// Dispatch queue used for asynchronous USB operations.
    public var queue: DispatchQueue {
        handle.queue
    }
    
    /// Destroys the underlying IOUSBHost object using default options.
    public func destroy() {
        handle.destroy()
    }
    
    /// Destroys the underlying IOUSBHost object using the specified options.
    /// - Parameter options: The destroy options applied to the IOUSBHost object.
    public func destroy(options: IOUSBHostObjectDestroyOptions) {
        handle.destroy(options: options)
    }
}

// MARK: - Synchronous control requests
/// Blocking control requests issued directly on the USB device.
extension USBObject {
    
    /// Sends a synchronous control request to the device.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    /// - Returns: The number of bytes transferred.
    /// - Throws: `USBHostError` if the request fails.
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
    
    /// Sends a synchronous control request without a data payload.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - timeout: The completion timeout in seconds.
    /// - Throws: `USBHostError` if the request fails.
    public func sendDeviceRequest(_ request: IOUSBDeviceRequest, timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout) throws(USBHostError) {
        do {
            try handle.__send(request, data: nil, bytesTransferred: nil, completionTimeout: timeout)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Asynchronous control requests
/// Non-blocking control request helpers with callback or async/await support.
extension USBObject {
    
    /// Enqueues an asynchronous control request and invokes the completion on finish.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    ///   - completion: Completion handler receiving the IOReturn status and bytes transferred.
    /// - Throws: `USBHostError` if the request cannot be enqueued.
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
    
    /// Enqueues an asynchronous control request and returns bytes transferred.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    /// - Returns: The number of bytes transferred.
    /// - Throws: `USBHostError` if enqueueing or completion fails.
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
    
    /// Aborts queued device requests with the specified option.
    /// - Parameter option: Abort option to apply to queued requests.
    /// - Throws: `USBHostError` if the abort operation fails.
    public func abortDeviceRequests(option: IOUSBHostAbortOption = .synchronous) throws(USBHostError) {
        do {
            try handle.__abortDeviceRequests(with: option)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Descriptor helpers
/// Descriptor accessors for device, configuration, capability, and string data.
extension USBObject {
    
    /// Fetches a descriptor pointer for the specified descriptor request.
    /// - Parameters:
    ///   - type: The descriptor type to request.
    ///   - maxLength: On input, the maximum length to read; on output, the actual length.
    ///   - index: The descriptor index.
    ///   - languageID: The language ID for string descriptors.
    ///   - requestType: The USB request type value.
    ///   - requestRecipient: The USB request recipient value.
    /// - Returns: A pointer to the descriptor, if available.
    /// - Throws: `USBHostError` if the request fails.
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
    
    /// Pointer to the device descriptor, if available.
    public var deviceDescriptor: UnsafePointer<IOUSBDeviceDescriptor>? {
        handle.deviceDescriptor
    }
    
    /// Pointer to the BOS capability descriptors, if available.
    public var capabilityDescriptors: UnsafePointer<IOUSBBOSDescriptor>? {
        handle.capabilityDescriptors
    }
    
    /// Returns the configuration descriptor for the given configuration value.
    /// - Parameter configurationValue: The configuration value to request.
    /// - Returns: The configuration descriptor.
    /// - Throws: `USBHostError` if the request fails.
    public func configurationDescriptor(configurationValue: Int) throws(USBHostError) -> UnsafePointer<IOUSBConfigurationDescriptor> {
        do {
            return try handle.configurationDescriptor(withConfigurationValue: configurationValue)
        } catch {
            throw USBHostError.translated(error)
        }
    }
    
    /// Returns a string descriptor for the given index and language ID.
    /// - Parameters:
    ///   - index: The string descriptor index.
    ///   - languageID: The language ID for the descriptor.
    /// - Returns: The string descriptor value.
    /// - Throws: `USBHostError` if the request fails.
    public func stringDescriptor(index: Int, languageID: Int = Int(kIOUSBLanguageIDEnglishUS.rawValue)) throws(USBHostError) -> String {
        do {
            return try handle.__string(with: Int(index), languageID: languageID)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Misc
/// Miscellaneous helpers that expose common device state and IOData creation.
extension USBObject {
    /// Current USB device address assigned by the host.
    public var deviceAddress: Int {
        handle.deviceAddress
    }
    
    /// Current USB frame number using default timing.
    public var currentFrameNumber: UInt64 {
        handle.__frameNumber(withTime: nil)
    }
    
    /// Returns the USB frame number while also providing the host time.
    /// - Parameter time: On output, the host time associated with the frame number.
    /// - Returns: The current USB frame number.
    public func frameNumber(with time: inout IOUSBHostTime) -> UInt64 {
        withUnsafeMutablePointer(to: &time) { ptr in
            handle.__frameNumber(withTime: ptr)
        }
    }
    
    /// Allocates IOData with the requested capacity using the underlying handle.
    /// - Parameter capacity: The requested allocation capacity in bytes.
    /// - Returns: A mutable data buffer backed by IOData.
    /// - Throws: `USBHostError` if allocation fails.
    internal func makeIOData(capacity: Int) throws(USBHostError) -> NSMutableData {
        do {
            return try handle.ioData(withCapacity: capacity)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}
