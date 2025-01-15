//
//  WalkersAlgorithm.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 12/23/24.
//

/*
 https://www.cs.unc.edu/techreports/89-034.pdf
 */

import Foundation

class CommitTree: Equatable {
    private static let MINIMUM_SUBTREE_SEPARATION: CGFloat = 0.0000001
    var nodes: [Node]

    static func == (lhs: CommitTree, rhs: CommitTree) -> Bool {
        lhs.root == rhs.root
        && lhs.nodes == rhs.nodes
    }

    let root: Node

    init(data: any NodeData) {
        self.root = Node(data)
        self.root.leftSibling = nil
        self.nodes = [root]
        self.root.tree = self
    }

    func addNode(_ node: Node) -> Node {
        root.addNode(node)
    }
    
    func addChild(data: any NodeData) -> Node {
        root.addChild(data: data)
    }
    
    func removeChild(_ node: Node) {
        root.removeChild(node)
    }
    
    func positionTree(distance: CGFloat = 1.0) {
        _firstWalk(root, distance: distance)
        _secondWalk(root, distance: 0)
    }
    
    @discardableResult
    fileprivate func _add(_ node: Node) -> Node {
        if nodes.first(where: { $0 === node }) == nil {
            nodes.append(node)
        }
        return node
    }
    
    private var calculatedNodes: Set<Node> = []
    
    private func _firstWalk(_ node: Node, distance: CGFloat) {
        if calculatedNodes.contains(node) {
            return
        }
        calculatedNodes.insert(node)

        if node.children.isNotEmpty {
            let defaultAncestor = node.children.first!
            for child in node.children {
                _firstWalk(child, distance: distance)
                _apportion(child, ancestor: defaultAncestor, distance: distance)
            }
            Self._executeShifts(node)
            let midPoint = 0.5 * (node.children.first!.layout.prelim + node.children.last!.layout.prelim)
            if let leftSibling = Self._leftSibling(node) {
                node.layout.prelim = leftSibling.layout.prelim + distance
                node.layout.mod = node.layout.prelim - midPoint
            } else {
                node.layout.prelim = midPoint
            }
        } else {
            if let leftSibling = Self._leftSibling(node) {
                node.layout.prelim = leftSibling.layout.prelim + distance
            }
        }
    }
    
    private func _secondWalk(_ node: Node, distance: CGFloat) {
        node.layout.x(node.layout.prelim + distance)
        for child in node.children {
            _secondWalk(child, distance: distance + node.layout.mod)
        }
    }
    
    @discardableResult
    private func _apportion(_ node: Node, ancestor: Node, distance: CGFloat) -> Node {
        var defaultAncestor = ancestor
        if let leftSibling = Self._leftSibling(node) {
            /*
             First letter (v/s):

             v stands for vertex/node position
             s stands for shift/modifier value


             Middle letter (p/m):

             p means plus (right) thread
             m means minus (left) thread


             Last letter (i/o):

             i means inner
             o means outer
             
             Let's say we have this tree:
             
                         Root
                       /      \
                      A        B
                    /  \     /  \
                   C    D   E    F
                  /    /   /    / \
                 G    H   I    J   K
                /    /   /        /
               L    M   N        O
              /
             P
             
             When processing node B and comparing with A's subtree, here's how the threading variables work:
             v_p_i (inner right) = B → E → I → N   (threads down left contour of right subtree)
             v_p_o (outer right) = B → F → K → O   (threads down right contour of right subtree)
             v_m_i (inner left)  = A → D → H → M   (threads down right contour of left subtree)
             v_m_o (outer left)  = A -> C → G → L → P   (threads down left contour of left subtree)
             
             
             As the algorithm threads through levels:
             Level 1:
               v_p_i = E (left contour of right)
               v_p_o = F (rightmost under B)
               v_m_i = D (right contour of left)
               v_m_o = C (leftmost under A)

             Level 2:
               v_p_i = I (continuing left contour)
               v_p_o = K (rightmost under F)
               v_m_i = H (continuing right contour)
               v_m_o = G (leftmost under C)

             Level 3:
               v_p_i = N (bottom of left contour)
               v_p_o = O (rightmost under K)
               v_m_i = M (bottom of right contour)
               v_m_o = L (leftmost under G)
             */
            
            var v_p_i: Node = node // v_p_i: The inner right vertex position
            var v_p_o: Node? = node // v_p_o: The outer right vertex position
            var v_m_i: Node = leftSibling // v_m_i: The inner left vertex position (left sibling)
            var v_m_o: Node? = v_p_i.parent?.children.first // v_m_o: The outer left vertex position (leftmost child of the parent)
            var s_p_i: CGFloat = v_p_i.layout.mod // s_p_i: The modifier value for the inner right thread
            var s_p_o: CGFloat = v_p_o?.layout.mod ?? 0 // s_p_o: The modifier value for the outer right thread
            var s_m_i: CGFloat = v_m_i.layout.mod // s_m_i: The modifier value for the inner left thread
            var s_m_o: CGFloat = v_m_o?.layout.mod ?? 0 // s_m_o: The modifier value for the outer left thread
            
            var level = 0
            while v_m_i.nextRight != nil, v_p_i.nextLeft != nil {
                level += 1
                v_p_i = v_p_i.nextLeft!
                v_m_i = v_m_i.nextRight!
                v_p_o = v_p_o?.nextRight
                v_m_o = v_m_o?.nextLeft
                v_p_o?.layout.ancestor = node
                let shift = v_m_i.layout.prelim + s_m_i - (v_p_i.layout.prelim + s_p_i) + distance
                
                /*
                We are processing B, level: 1, v_p_i is E, v_p_o is F, v_m_i is D, v_m_o is C,
                v_m_i.layout.prelim is 1.0, s_m_i is 0.0, v_p_i.layout.prelim is 0.0,
                s_p_i is 0.75, distance is 1.0
                shift = 1 + 0 - (0 + 0.75) + 1 = 1.25
                This means we need to move v_p_i's subtree 1.25 units right to maintain proper spacing
                 */
                if shift > 0 {
                    /*
                     Self._ancestor returns A.
                     So we pass A as the left node, and B as the right node to moveSubtree function.
                     */
                    Self._moveSubtree(leftNode: Self._ancestor(v_m_i: v_m_i, v: node, defaultAncestor: defaultAncestor), rightNode: node, shift: shift)
                    s_p_i = s_p_i + shift
                    s_p_o = s_p_o + shift
                }
                s_m_i = s_m_i + v_m_i.layout.mod
                s_p_i = s_p_i + v_p_i.layout.mod
                s_m_o = s_m_o + (v_m_o?.layout.mod ?? 0)
                s_p_o = s_p_o + (v_p_o?.layout.mod ?? 0)
                if v_m_i.nextRight != nil, v_p_o?.nextRight == nil {
                    v_p_o?.layout.thread = v_m_i.nextRight!
                    v_p_o?.layout.mod = (v_p_o?.layout.mod ?? 0) + s_m_i - s_p_o
                }
                if v_p_i.nextLeft != nil, v_m_o?.nextLeft == nil {
                    v_m_o?.layout.thread = v_p_i.nextLeft!
                    v_m_o?.layout.mod = (v_m_o?.layout.mod ?? 0) + s_p_i - s_m_o
                    defaultAncestor = node
                }
            }
        }
        return defaultAncestor
    }
    
    private static func _executeShifts(_ v: Node) {
        var shift: CGFloat = 0
        var change: CGFloat = 0
        
        for child in v.children.reversed() {
            child.layout.prelim += shift
            child.layout.mod += shift
            change += child.layout.change
            shift += child.layout.shift + change
        }
    }

    private static func _moveSubtree(leftNode: Node, rightNode: Node, shift: CGFloat) {
        var subtrees = CGFloat(rightNode.number() - leftNode.number())
        if subtrees == 0 { subtrees = Self.MINIMUM_SUBTREE_SEPARATION }
        /*
         MoveSubtree: rightNode B number: 1, leftNode A number: 0, shift: 1.25 subtrees: 1
         */
        // Distribute the shift across the siblings
        let portionPerSibling = shift / subtrees
        
        /*
         shift represents immediate shifts needed for the current node
         change represents gradual changes that accumulate across siblings during the second walk
         Together they help ensure even spacing between subtrees
         */
        rightNode.layout.change = rightNode.layout.change - portionPerSibling
        rightNode.layout.shift = rightNode.layout.shift + shift
        leftNode.layout.change = leftNode.layout.change + portionPerSibling
        rightNode.layout.prelim = rightNode.layout.prelim + shift
        rightNode.layout.mod = rightNode.layout.mod + shift
    }
        
    private static func _ancestor(v_m_i: Node, v: Node, defaultAncestor: Node) -> Node {
        /*
         When processing B,
         v_m_i is D, v_m_i.layout.ancestor is D, parent of v_m_i.layout.ancestor is A, v is B,
         parent of V is R, defaultAncestor A,
         parent of v_m_i.layout.ancestor (A) is not equal to parent of V (R),
         so returning defaultAncestor A
         */
        if let ancestor = v_m_i.layout.ancestor, let ancestorParent = ancestor.parent, ancestorParent === v.parent {
            return ancestor
        }
        return defaultAncestor
    }
    
    private static func _leftSibling(_ v: Node) -> Node? {
        if let leftSibling = v.leftSibling {
            return leftSibling
        } else {
            guard let parent = v.parent, parent.children.isNotEmpty else {
                return nil
            }
            
            var last: Node? = nil
            for w in parent.children {
                if w === v {
                    return last
                }
                last = w
            }
            return nil
        }
    }
}

class Node {
    class Layout: Equatable {
        weak var node: Node!
        var ancestor: Node!
        var thread: Node?

        var mod: CGFloat = 0.0
        var prelim: CGFloat = 0.0
        var shift: CGFloat = 0.0
        var change: CGFloat = 0.0
        var xPosition: CGFloat?
        var yPosition: CGFloat?
        var number: Int = -1
        
        init() {}
        
        @discardableResult
        func x(_ value: CGFloat? = nil) -> CGFloat? {
            if let value {
                xPosition = value
                return value
            }
            return xPosition
        }
        
        @discardableResult
        func y(_ value: CGFloat? = nil) -> CGFloat? {
            if let value {
                yPosition = value
                return value
            }
            return yPosition
        }

        static func == (lhs: Node.Layout, rhs: Node.Layout) -> Bool {
            lhs.xPosition == rhs.xPosition && lhs.yPosition == rhs.yPosition
        }
    }
    
    weak var tree: CommitTree?
    var leftSibling: Node?
    var children: [Node] = []
    var parent: Node?
    let layout: Layout
    var nodeData: any NodeData

    init(_ nodeData: any NodeData) {
        self.nodeData = nodeData
        self.layout = Layout()
        self.layout.node = self
        self.layout.ancestor = self
    }

    @discardableResult
    func addNode(_ node: Node) -> Node {
        if children.isNotEmpty {
            node.leftSibling = children.last!
            node.layout.number = node.leftSibling!.layout.number + 1
        } else {
            node.leftSibling = nil
            node.layout.number = 0
        }
        
        node.parent = self
        children.append(node)
        
        var i = 0
        var root = node
        while let parent = root.parent {
            root = parent
            i += 1
        }
        
        root.tree!._add(node)
        node.tree = root.tree
        node.layout.yPosition = -CGFloat(i)
        return node
    }
    
    @discardableResult
    func addChild(data: any NodeData) -> Node {
        addNode(Node(data))
    }

    func removeChild(_ node: Node) {
        var j = -1
        for i in children.indices {
            if children[i] === node {
                children.remove(at: i)
                j = i
                break
            }
        }
        
        for i in tree!.nodes.indices {
            if tree!.nodes[i] === node {
                tree!.nodes.remove(at: i)
                break
            }
        }
        
        // update the left sibling
        if j == 0 {
            children[0].leftSibling = nil
        } else if j > 0 {
            children[j].leftSibling = children[j - 1]
        } else {
            return
        }
        
        // update numbers
        for i in j..<children.count {
            children[i].layout.number = i
        }
        
        // Remove children of the deleted node
        var i = 0
        while i < node.children.count {
            if node.children.firstIndex(where: { $0 === tree!.nodes[i] }) != nil {
                tree!.nodes.remove(at: i)
            } else {
                i += 1
            }
        }
        node.children = []
    }
    
    var nextLeft: Node? {
        if children.isNotEmpty {
            children.first!
        } else {
            layout.thread
        }
    }
    
    var nextRight: Node? {
        if children.isNotEmpty {
            children.last!
        } else {
            layout.thread
        }
    }
    
    var level: Int {
        if let y = layout.yPosition {
            return Int(y)
        }
        
        var n = parent
        var i = 0
        while n != nil {
            n = n!.parent
            i += 1
        }
        return i
    }
    
    func positionAsInt(origin: (Int, Int) = (0, 0), scaleX: CGFloat = 1.0, scaleY: CGFloat? = nil) -> (Int, Int) {
        let scaleY = scaleY ?? scaleX
        return (
            origin.0 + Int(ceil((layout.x() ?? 0.0) * scaleX)),
            origin.1 + Int(ceil((layout.y() ?? 0.0) * scaleY))
        )
    }
    
    func positionAsFloat(origin: (CGFloat, CGFloat) = (0, 0), scaleX: CGFloat = 1.0, scaleY: CGFloat? = nil) -> (CGFloat, CGFloat) {
        let scaleY = scaleY ?? scaleX
        let position = (
            origin.0 + ceil((layout.x() ?? 0.0) * scaleX),
            origin.1 + ceil((layout.y() ?? 0.0) * scaleY)
        )
        return position
    }
    
    func number() -> Int {
        if layout.number != -1 {
            return layout.number
        }
        if let parent {
            var i = 0
            for node in parent.children {
                if node === self {
                    return i
                }
                i += 1
            }
            fatalError("Error finding number of node in parent's children array")
        } else {
            return 0
        }
    }
}

extension Node: Equatable, Hashable {
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.layout == rhs.layout && lhs.nodeData.id == rhs.nodeData.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension Node: CustomStringConvertible {
    public var description: String {
        "node with node data id \(nodeData.id)"
    }
}
