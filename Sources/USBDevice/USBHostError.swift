// Package: USBDevice
// File: USBHostError.swift
// Path: Sources/USBDevice/USBHostError.swift
// Date: 2025-11-23
// Author: Ahmed Emerah
// Email: ahmed.emerah@icloud.com
// Github: https://github.com/Emerah


import IOUSBHost


public enum USBHostError: Error, LocalizedError, Equatable {
    case error
    case noMemory
    case noResources
    case ipcError
    case noDevice
    case notPrivileged
    case badArgument
    case lockedRead // irrelevant??
    case lockedWrite // irrelevant??
    case exclusiveAccess
    case badMessageID
    case unsupported
    case vmError // irrelevant??
    case internalError
    case ioError
    case cannotLock // irrelevant??
    case notOpen
    case notReadable // irrelevant??
    case notWritable // irrelevant??
    case notAligned // irrelevant??
    case badMedia // irrelevant??
    case stillOpen // irrelevant??
    case rldError // irrelevant??
    case dmaError // irrelevant??
    case busy
    case timeout
    case offline
    case notReady
    case notAttached
    case noChannels // irrelevant??
    case noSpace
    case portExists
    case cannotWire // irrelevant??
    case noInterrupt // irrelevant??
    case noFrames // irrelevant??
    case messageTooLarge
    case notPermitted
    case noPower
    case noMedia // irrelevant??
    case unformattedMedia // irrelevant??
    case unsupportedMode // irrelevant??
    case underrun
    case overrun
    case deviceError
    case noCompletion
    case aborted
    case noBandwidth
    case notResponding
    case isoTooOld
    case isoTooNew
    case notFound
    case invalid
    
    case unknown(code: IOReturn)
}



extension USBHostError {
    
    
    /// Translate any Error coming from IOUSBHostErrorDomain into USBHostError.
    public static func translated(_ error: Error) -> USBHostError {
        if let hostError = error as? USBHostError {
            return hostError
        }
        
        if let hostError = USBHostError(error: error) {
            return hostError
        }
        
        let nsError = error as NSError
        return USBHostError(status: IOReturn(nsError.code)) ?? USBHostError.unknown(code: IOReturn(nsError.code))
    }
    
    /// Translate an IOReturn into a concrete USBHostError, defaulting to .unknown.
    public static func translated(status: IOReturn) -> USBHostError {
        USBHostError(status: status) ?? USBHostError.unknown(code: status)
    }
    
    /// Create from an arbitrary Error if it is in IOUSBHostErrorDomain.
    public init?(error: Error) {
        let nsError = error as NSError
        guard nsError.domain == IOUSBHostErrorDomain else { return nil }
        self.init(status: IOReturn(nsError.code))
    }
    
    /// Create a typed error from an IOReturn.
    /// Returns `nil` for `kIOReturnSuccess`.
    public init?(status: IOReturn) {
        guard status != kIOReturnSuccess else { return nil }
        
        switch status {
        case kIOReturnError:              self = .error
        case kIOReturnNoMemory:           self = .noMemory
        case kIOReturnNoResources:        self = .noResources
        case kIOReturnIPCError:           self = .ipcError
        case kIOReturnNoDevice:           self = .noDevice
        case kIOReturnNotPrivileged:      self = .notPrivileged
        case kIOReturnBadArgument:        self = .badArgument
        case kIOReturnLockedRead:         self = .lockedRead
        case kIOReturnLockedWrite:        self = .lockedWrite
        case kIOReturnExclusiveAccess:    self = .exclusiveAccess
        case kIOReturnBadMessageID:       self = .badMessageID
        case kIOReturnUnsupported:        self = .unsupported
        case kIOReturnVMError:            self = .vmError
        case kIOReturnInternalError:      self = .internalError
        case kIOReturnIOError:            self = .ioError
        case kIOReturnCannotLock:         self = .cannotLock
        case kIOReturnNotOpen:            self = .notOpen
        case kIOReturnNotReadable:        self = .notReadable
        case kIOReturnNotWritable:        self = .notWritable
        case kIOReturnNotAligned:         self = .notAligned
        case kIOReturnBadMedia:           self = .badMedia
        case kIOReturnStillOpen:          self = .stillOpen
        case kIOReturnRLDError:           self = .rldError
        case kIOReturnDMAError:           self = .dmaError
        case kIOReturnBusy:               self = .busy
        case kIOReturnTimeout:            self = .timeout
        case kIOReturnOffline:            self = .offline
        case kIOReturnNotReady:           self = .notReady
        case kIOReturnNotAttached:        self = .notAttached
        case kIOReturnNoChannels:         self = .noChannels
        case kIOReturnNoSpace:            self = .noSpace
        case kIOReturnPortExists:         self = .portExists
        case kIOReturnCannotWire:         self = .cannotWire
        case kIOReturnNoInterrupt:        self = .noInterrupt
        case kIOReturnNoFrames:           self = .noFrames
        case kIOReturnMessageTooLarge:    self = .messageTooLarge
        case kIOReturnNotPermitted:       self = .notPermitted
        case kIOReturnNoPower:            self = .noPower
        case kIOReturnNoMedia:            self = .noMedia
        case kIOReturnUnformattedMedia:   self = .unformattedMedia
        case kIOReturnUnsupportedMode:    self = .unsupportedMode
        case kIOReturnUnderrun:           self = .underrun
        case kIOReturnOverrun:            self = .overrun
        case kIOReturnDeviceError:        self = .deviceError
        case kIOReturnNoCompletion:       self = .noCompletion
        case kIOReturnAborted:            self = .aborted
        case kIOReturnNoBandwidth:        self = .noBandwidth
        case kIOReturnNotResponding:      self = .notResponding
        case kIOReturnIsoTooOld:          self = .isoTooOld
        case kIOReturnIsoTooNew:          self = .isoTooNew
        case kIOReturnNotFound:           self = .notFound
        case kIOReturnInvalid:            self = .invalid
            
        default:
            self = .unknown(code: status)
        }
    }
    
    /// Back to the raw IOReturn, if you need to pass it through.
    public var ioReturnValue: IOReturn {
        switch self {
        case .error:              return kIOReturnError
        case .noMemory:           return kIOReturnNoMemory
        case .noResources:        return kIOReturnNoResources
        case .ipcError:           return kIOReturnIPCError
        case .noDevice:           return kIOReturnNoDevice
        case .notPrivileged:      return kIOReturnNotPrivileged
        case .badArgument:        return kIOReturnBadArgument
        case .lockedRead:         return kIOReturnLockedRead
        case .lockedWrite:        return kIOReturnLockedWrite
        case .exclusiveAccess:    return kIOReturnExclusiveAccess
        case .badMessageID:       return kIOReturnBadMessageID
        case .unsupported:        return kIOReturnUnsupported
        case .vmError:            return kIOReturnVMError
        case .internalError:      return kIOReturnInternalError
        case .ioError:            return kIOReturnIOError
        case .cannotLock:         return kIOReturnCannotLock
        case .notOpen:            return kIOReturnNotOpen
        case .notReadable:        return kIOReturnNotReadable
        case .notWritable:        return kIOReturnNotWritable
        case .notAligned:         return kIOReturnNotAligned
        case .badMedia:           return kIOReturnBadMedia
        case .stillOpen:          return kIOReturnStillOpen
        case .rldError:           return kIOReturnRLDError
        case .dmaError:           return kIOReturnDMAError
        case .busy:               return kIOReturnBusy
        case .timeout:            return kIOReturnTimeout
        case .offline:            return kIOReturnOffline
        case .notReady:           return kIOReturnNotReady
        case .notAttached:        return kIOReturnNotAttached
        case .noChannels:         return kIOReturnNoChannels
        case .noSpace:            return kIOReturnNoSpace
        case .portExists:         return kIOReturnPortExists
        case .cannotWire:         return kIOReturnCannotWire
        case .noInterrupt:        return kIOReturnNoInterrupt
        case .noFrames:           return kIOReturnNoFrames
        case .messageTooLarge:    return kIOReturnMessageTooLarge
        case .notPermitted:       return kIOReturnNotPermitted
        case .noPower:            return kIOReturnNoPower
        case .noMedia:            return kIOReturnNoMedia
        case .unformattedMedia:   return kIOReturnUnformattedMedia
        case .unsupportedMode:    return kIOReturnUnsupportedMode
        case .underrun:           return kIOReturnUnderrun
        case .overrun:            return kIOReturnOverrun
        case .deviceError:        return kIOReturnDeviceError
        case .noCompletion:       return kIOReturnNoCompletion
        case .aborted:            return kIOReturnAborted
        case .noBandwidth:        return kIOReturnNoBandwidth
        case .notResponding:      return kIOReturnNotResponding
        case .isoTooOld:          return kIOReturnIsoTooOld
        case .isoTooNew:          return kIOReturnIsoTooNew
        case .notFound:           return kIOReturnNotFound
        case .invalid:            return kIOReturnInvalid
            
        case .unknown(let code):  return code
        }
    }
    
    /// Surface human-readable descriptions from the underlying NSError.
    public var errorDescription: String? {
        let nsError = NSError(domain: IOUSBHostErrorDomain, code: Int(ioReturnValue))
        return nsError.localizedDescription
    }
}
