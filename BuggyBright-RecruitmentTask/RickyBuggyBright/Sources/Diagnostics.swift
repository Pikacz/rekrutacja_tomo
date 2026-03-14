//
//  Diagnostics.swift
//  RickyBuggyBright
//
//  Created by Paweł Czerwinski on 14/03/2026.
//

import Foundation

func diagnosticsAddBreadcrumb(
    message: String,
    parameters: [String: Any] = [:]
) {
    // Sentry.addBreadcrumb
    print("Breadcrumb: \(message)")
    if !parameters.isEmpty {
        print(parameters)
    }
}

func diagnosticsNonFatalError(
    message: String,
    parameters: [String: Any] = [:],
    crashOnDebug: Bool = true
) {
    #if DEBUG
    if crashOnDebug {
        fatalError("\(message) \(parameters)")
    }
    #endif
    // Sentry.nonFatalError
    print("Non fatal: \(message)")
    if !parameters.isEmpty {
        print(parameters)
    }
}

func diagnosticsCheapToUseTime() -> UInt64 {
    return mach_absolute_time()
}

private let cpuTimeBase = {
    var timebase = mach_timebase_info_data_t()
    mach_timebase_info(&timebase)
    return timebase
}()

func diagnosticsTimeToMiliseconds(_ elapsedTime: UInt64) -> Double {
    let nanos = elapsedTime * UInt64(cpuTimeBase.numer) / UInt64(cpuTimeBase.denom)
    return Double(nanos) / 1_000_000.0
}
