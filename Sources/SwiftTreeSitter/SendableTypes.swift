struct SendableOpaquePointer: @unchecked Sendable {
	let pointer: OpaquePointer

	init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
}

extension SendableOpaquePointer: Equatable {}
extension SendableOpaquePointer: Hashable {}
