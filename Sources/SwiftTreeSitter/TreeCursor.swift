import Foundation
import TreeSitter

public class TreeCursor {
    private var internalCursor: TSTreeCursor
	private let internalTree: Tree

	init(internalCursor: TSTreeCursor, internalTree: Tree) {
        self.internalCursor = internalCursor
		self.internalTree = internalTree
    }

    deinit {
        ts_tree_cursor_delete(&internalCursor)
    }
}

extension TreeCursor {
    public func gotoParent() -> Bool {
        return ts_tree_cursor_goto_parent(&internalCursor)
    }
    
    public func gotoNextSibling() -> Bool {
        return ts_tree_cursor_goto_next_sibling(&internalCursor)
    }
    
    public func goToFirstChild() -> Bool {
        return ts_tree_cursor_goto_first_child(&internalCursor)
    }

    public func goToFirstChild(for startByte: UInt32) -> Bool {
        return ts_tree_cursor_goto_first_child_for_byte(&internalCursor, startByte) != -1
    }
}

extension TreeCursor {
    public var currentNode: Node? {
		return Node(internalNode: ts_tree_cursor_current_node(&internalCursor), internalTree: internalTree)
    }
    
    public var currentFieldName: String? {
        guard let str = ts_tree_cursor_current_field_name(&internalCursor) else {
            return nil
        }
        
        return String(cString: str)
    }
    
    public var currentFieldId: Int {
        return Int(ts_tree_cursor_current_field_id(&internalCursor))
    }
}

extension TreeCursor {
    public func enumerateCurrentAndDescendents(block: (Node) throws -> Void) rethrows {
        if let node = currentNode {
            try block(node)
        }

        if goToFirstChild() == false {
            return
        }

        try enumerateCurrentAndDescendents(block: block)
        
        while gotoNextSibling() {
            try enumerateCurrentAndDescendents(block: block)
        }

        let success = gotoParent()

        assert(success)
    }
}
