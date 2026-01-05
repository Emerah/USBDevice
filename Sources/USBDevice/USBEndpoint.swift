// Package: USBDevice
// File: USBEndpoint.swift
// Path: Sources/USBDevice/USBEndpoint.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import Foundation
import IOUSBHost

extension USBDevice.USBInterface {
    /// USB endpoint wrapper around `IOUSBHostPipe`.
    public final class USBEndpoint {
        
        /// Concrete USB host handle type for this object.
        internal typealias USBHandle = IOUSBHostPipe
        
        /// Underlying IOUSBHost pipe handle.
        internal let handle: IOUSBHostPipe
        private let metadata: MetaData
        
        /// Creates an endpoint wrapper and captures immutable metadata from the handle.
        /// - Parameter handle: The underlying `IOUSBHostPipe`.
        internal init(handle: IOUSBHostPipe) {
            self.handle = handle
            let metadata = Self.retrieveEndpointMetadata(from: handle)
            self.metadata = metadata
        }
    }
}

// MARK: - Descriptors & policy
/// Descriptor and policy accessors for the endpoint pipe.
extension USBDevice.USBInterface.USBEndpoint {

    /// Original descriptors as reported by the device.
    public var originalDescriptors: UnsafePointer<IOUSBHostIOSourceDescriptors>? {
        handle.originalDescriptors
    }

    /// Current descriptors for the pipe.
    public var descriptors: UnsafePointer<IOUSBHostIOSourceDescriptors>? {
        handle.descriptors
    }

    /// Host interface that owns this endpoint.
    public var hostInterface: IOUSBHostInterface {
        handle.hostInterface
    }

    /// Adjusts the endpoint descriptors for this pipe.
    /// - Parameter descriptors: The descriptors to apply.
    /// - Throws: `USBHostError` if the descriptors cannot be applied.
    public func adjust(descriptors: UnsafePointer<IOUSBHostIOSourceDescriptors>) throws(USBHostError) {
        do {
            try handle.adjust(with:descriptors)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Idle timeout & halt
/// Idle timeout and halt control for the endpoint pipe.
extension USBDevice.USBInterface.USBEndpoint {
    /// Idle timeout value for the pipe.
    public var idleTimeout: TimeInterval {
        handle.idleTimeout
    }

    /// Sets the pipe idle timeout.
    /// - Parameter timeout: The idle timeout in seconds.
    /// - Throws: `USBHostError` if the timeout cannot be set.
    public func setIdleTimeout(_ timeout: TimeInterval) throws(USBHostError) {
        do {
            try handle.setIdleTimeout(timeout)
        } catch {
            throw USBHostError.translated(error)
        }
    }

    /// Clears a stalled (halted) endpoint.
    /// - Throws: `USBHostError` if the clear-stall request fails.
    public func clearStall() throws(USBHostError) {
        do {
            try handle.clearStall()
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Abort
/// Abort helpers for pending endpoint requests.
extension USBDevice.USBInterface.USBEndpoint {
    /// Aborts queued requests for the pipe.
    /// - Parameter option: Abort option to apply to queued requests.
    /// - Throws: `USBHostError` if the abort operation fails.
    public func abort(option: IOUSBHostAbortOption = .synchronous) throws(USBHostError) {
        do {
            try handle.__abort(with: option)
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Control transfers
/// Control transfer helpers for endpoint-level requests.
extension USBDevice.USBInterface.USBEndpoint {
    /// Sends a synchronous control request on the endpoint.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    /// - Returns: The number of bytes transferred.
    /// - Throws: `USBHostError` if the request fails.
    public func sendControlRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout
    ) throws(USBHostError) -> Int {
        var bytes: Int = 0
        do {
            try handle.__sendControlRequest(
                request,
                data: data,
                bytesTransferred: &bytes,
                completionTimeout: timeout
            )
        } catch {
            throw USBHostError.translated(error)
        }
        return bytes
    }

    /// Enqueues an asynchronous control request on the endpoint.
    /// - Parameters:
    ///   - request: The control request to send.
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    ///   - completion: Optional completion handler with status and bytes transferred.
    /// - Throws: `USBHostError` if the request cannot be enqueued.
    public func enqueueControlRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout,
        completion: (@Sendable (IOReturn, Int) -> Void)? = nil
    ) throws(USBHostError) {
        do {
            try handle.__enqueueControlRequest(
                request,
                data: data,
                completionTimeout: timeout,
                completionHandler: completion
            )
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
    public func enqueueControlRequest(
        _ request: IOUSBDeviceRequest,
        data: NSMutableData? = nil,
        timeout: TimeInterval = IOUSBHostDefaultControlCompletionTimeout
    ) async throws(USBHostError) -> Int {
        do {
            let (status, bytesTransferred) = try await handle.__enqueueControlRequest(
                request,
                data: data,
                completionTimeout: timeout
            )
            if status == kIOReturnSuccess {
                return bytesTransferred
            } else {
                throw USBHostError.translated(status: status)
            }
        } catch {
            throw USBHostError.translated(error)
        }
    }
}

// MARK: - Bulk / interrupt IO
/// Bulk and interrupt I/O helpers for the endpoint.
extension USBDevice.USBInterface.USBEndpoint {
    /// Sends a synchronous I/O request on the endpoint.
    /// - Parameters:
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    /// - Returns: The number of bytes transferred.
    /// - Throws: `USBHostError` if the request fails.
    public func sendIORequest(data: NSMutableData?, timeout: TimeInterval) throws(USBHostError) -> Int {
        var bytes: Int = 0
        do {
            try handle.__sendIORequest(with: data, bytesTransferred: &bytes, completionTimeout: timeout)
        } catch {
            throw USBHostError.translated(error)
        }
        return bytes
    }

    /// Enqueues an asynchronous I/O request on the endpoint.
    /// - Parameters:
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    ///   - completionHandler: Optional completion handler with status and bytes transferred.
    /// - Throws: `USBHostError` if the request cannot be enqueued.
    public func enqueueIORequest(
        data: NSMutableData?,
        timeout: TimeInterval,
        completionHandler: (@Sendable (IOReturn, Int) -> Void)? = nil
    ) throws(USBHostError) {
        do {
            try handle.enqueueIORequest(with: data, completionTimeout: timeout, completionHandler: completionHandler)
        } catch {
            throw USBHostError.translated(error)
        }
    }

    /// Enqueues an asynchronous I/O request and returns bytes transferred.
    /// - Parameters:
    ///   - data: Optional mutable data buffer for the transfer.
    ///   - timeout: The completion timeout in seconds.
    /// - Returns: The number of bytes transferred.
    /// - Throws: `USBHostError` if enqueueing or completion fails.
    public func enqueueIORequest(data: NSMutableData?, timeout: TimeInterval) async throws(USBHostError) -> Int {
        do {
            let (status, bytesTransferred) = try await handle.enqueueIORequest(with: data, completionTimeout: timeout)
            if status == kIOReturnSuccess {
                return bytesTransferred
            } else {
                throw USBHostError.translated(status: status)
            }
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Streams
/// Stream management helpers for stream-capable endpoints.
extension USBDevice.USBInterface.USBEndpoint {
    /// Enables streams for the endpoint.
    /// - Throws: `USBHostError` if streams cannot be enabled.
    public func enableStreams() throws(USBHostError) {
        do {
            try handle.enableStreams()
        } catch {
            throw USBHostError.translated(error)
        }
    }

    /// Disables streams for the endpoint.
    /// - Throws: `USBHostError` if streams cannot be disabled.
    public func disableStreams() throws(USBHostError) {
        do {
            try handle.disableStreams()
        } catch {
            throw USBHostError.translated(error)
        }
    }

    /// Copies a stream by stream ID.
    /// - Parameter streamID: The stream identifier to copy.
    /// - Returns: The copied `IOUSBHostStream` instance.
    /// - Throws: `USBHostError` if the stream cannot be copied.
    public func copyStream(streamID: Int) throws(USBHostError) -> IOUSBHostStream {
        do {
            let stream = try handle.copyStream(withStreamID: streamID)
            return stream
        } catch {
            throw USBHostError.translated(error)
        }
    }
}


// MARK: - Metadata
/// Read-only metadata captured from the endpoint at initialization.
extension USBDevice.USBInterface.USBEndpoint {
    /// Endpoint address from the descriptor.
    public var endpointAddress: UInt8 {
        metadata.endpointAddress
    }

    /// Maximum packet size for the endpoint.
    public var maxPacketSize: UInt16 {
        metadata.maxPacketSize
    }

    /// Endpoint direction derived from the address.
    public var direction: USBEndpointDirection {
        metadata.direction
    }

    /// Transfer type derived from the endpoint attributes.
    public var transferType: USBEndpointTransferType {
        metadata.transferType
    }

    /// Polling interval for interrupt/isochronous endpoints.
    public var pollInterval: UInt8 {
        metadata.pollInterval
    }
}


// MARK: - Metadata types
/// Endpoint metadata types used for parsed descriptor values.
extension USBDevice.USBInterface.USBEndpoint {
    
    /// Data flow direction derived from the endpoint address.
    public enum USBEndpointDirection: Sendable {
        case hostToDevice // out
        case deviceToHost // in
        
        /// Initializes the direction based on the endpoint address.
        /// - Parameter endpointAddress: The endpoint address to inspect.
        internal init(endpointAddress: UInt8) {
            if (endpointAddress & 0x80) != 0 {
                self = .deviceToHost
            } else {
                self = .hostToDevice
            }
        }
    }

    /// Transfer type derived from the endpoint attributes.
    public enum USBEndpointTransferType: Sendable {
        case control
        case interrupt
        case bulk
        case isochronous
        case unknown

        /// Initializes the transfer type based on the endpoint attributes.
        /// - Parameter bmAtrributes: The endpoint attributes field.
        internal init(bmAtrributes: UInt8) {
            let transferType = (bmAtrributes & 0x03)
            switch transferType {
                case 0x00: self = .control
                case 0x01: self = .interrupt
                case 0x02: self = .bulk
                case 0x03: self = .isochronous
                default: self = .unknown
            }
        }
    }
}


extension USBDevice.USBInterface.USBEndpoint {

    /// Immutable metadata extracted from the endpoint descriptor.
    fileprivate struct MetaData {
        fileprivate let endpointAddress: UInt8
        fileprivate let maxPacketSize: UInt16
        fileprivate let pollInterval: UInt8
        fileprivate let direction: USBEndpointDirection
        fileprivate let transferType: USBEndpointTransferType
    }

    /// Retrieves endpoint metadata from the provided handle.
    /// - Parameter handle: The `IOUSBHostPipe` handle to inspect.
    /// - Returns: Captured endpoint metadata.
    private static func retrieveEndpointMetadata(from handle: IOUSBHostPipe) -> MetaData {
        let descriptor = handle.descriptors.pointee.descriptor
        let endpointAddress = descriptor.bEndpointAddress
        let maxPacketSize = descriptor.wMaxPacketSize
        let pollInterval = descriptor.bInterval
        let direction = USBEndpointDirection(endpointAddress: endpointAddress)
        let transferType = USBEndpointTransferType(bmAtrributes: descriptor.bmAttributes)
        return MetaData(endpointAddress: endpointAddress, maxPacketSize: maxPacketSize, pollInterval: pollInterval, direction: direction, transferType: transferType)
    }
}
