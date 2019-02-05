//
//  ConnectionNode.swift
//  swifty_proteins
//
//  Created by Nyameko RARANE on 2019/01/30.
//  Copyright © 2019 Nyameko RARANE. All rights reserved.
//

import SceneKit

class ConnectionNode: SCNNode {
    var cylinder:SCNCylinder!
    init (node1: Node, node2: Node)
    {
        super.init()
        let primaryNode = SCNNode()
        let height = distance(node1, node2) + 0.25
        
        
        self.position = SCNVector3(x: node1.x_pos, y: node1.y_pos, z: node1.z_pos)
        
        let secondaryNode = SCNNode()
        secondaryNode.position = SCNVector3(x: node2.x_pos, y: node2.y_pos, z: node2.z_pos)
        primaryNode.addChildNode(secondaryNode)
        
        let alignNode = SCNNode()
        alignNode.eulerAngles.x = Float(Double.pi / 2)
        
        cylinder = SCNCylinder(radius: 0.1, height: CGFloat(height))
        cylinder.firstMaterial?.diffuse.contents = UIColor(red: 80/255, green: 80/255, blue: 80/255, alpha: 1)
        
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position.y = -height / 2
        alignNode.addChildNode(cylinderNode)
        
        self.addChildNode(alignNode)
        self.constraints = [SCNLookAtConstraint(target: secondaryNode)]
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func distance (_ node1: Node, _ node2: Node) -> Float
    {
        var tempHeight = abs(node1.x_pos - node2.x_pos) * abs(node1.x_pos - node2.x_pos)
        tempHeight += abs(node1.y_pos - node2.y_pos) * abs(node1.y_pos - node2.y_pos)
        tempHeight += abs(node1.z_pos - node2.z_pos) * abs(node1.z_pos - node2.z_pos)
        let height = Float(sqrt(tempHeight))
        return (height)
    }
}
