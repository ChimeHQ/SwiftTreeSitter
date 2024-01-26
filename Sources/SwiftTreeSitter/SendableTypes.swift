struct SendableOpaquePointer: @unchecked Sendable {
	let pointer: OpaquePointer

	init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
}

struct SendableUnsafePointer<T>: @unchecked Sendable {
	let pointer: UnsafePointer<T>

	init(_ pointer: UnsafePointer<T>) {
		self.pointer = pointer
	}
}

extension SendableUnsafePointer: Equatable {}
extension SendableUnsafePointer: Hashable {}
