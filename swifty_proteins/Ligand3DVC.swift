//
//  Ligand3DVC.swift
//  swifty_proteins
//
//  Created by Nyameko RARANE on 2019/01/30.
//  Copyright © 2019 Nyameko RARANE. All rights reserved.
//

import UIKit
import SceneKit

class Ligand3DVC: UIViewController {

    var ligandToDraw: LigandModel!
    var ligandView: SCNView!
    var ligandScene: SCNScene!
    var ligandCamera: SCNNode!
    var ballStickList:[SCNNode] = []
    var spaceAtomList:[SCNNode] = []
    var shareButton:UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.title = "Ligand " + ligandToDraw.name
        shareButton = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(self.shareAction))
        self.navigationItem.rightBarButtonItem = shareButton
        initLigandView()
        initLigandScene()
        initLigandCamera()
        
        drawInitialLigandNodes()
        drawInitialConnections()
    }
    
    func initLigandView()
    {
        ligandView = self.view as! SCNView
        ligandView.allowsCameraControl = true
        
    }
    
    func initLigandScene()
    {
        ligandScene = SCNScene()
        ligandView.scene = ligandScene
        ligandView.isPlaying = true
        ligandScene.background.contents = UIImage(named: "universe-background")
    }
    
    func initLigandCamera()
    {
        ligandCamera = SCNNode()
        ligandCamera.camera = SCNCamera()
        ligandCamera.position = SCNVector3(x: 0, y: 0, z: 100)
    }
    
    func drawInitialLigandNodes()
    {
        for node in ligandToDraw.nodes!
        {
            let nodeItem:SCNGeometry = SCNSphere(radius: 0.5)
            nodeItem.materials.first?.diffuse.contents = node.node_color
            let nodeSphere = SCNNode(geometry: nodeItem)
            nodeSphere.position = SCNVector3(x: node.x_pos!, y: node.y_pos!, z: node.z_pos!)
            nodeSphere.name = node.atom.name + "\n" + node.atom.summary
            ligandScene.rootNode.addChildNode(nodeSphere)
            ballStickList.append(nodeSphere)
        }
    }
    
    func drawInitialConnections()
    {
        for link in ligandToDraw.connections!
        {
            let node = ConnectionNode(node1: link.node1, node2: link.node2)
            ligandScene.rootNode.addChildNode(node)
        }
    }
    
    @objc func shareAction()
    {
        let image = ligandView.snapshot()
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    override var shouldAutorotate: Bool
    {
        return (true)
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return (true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        if UIDevice.current.userInterfaceIdiom == .phone
        {
            return (.allButUpsideDown)
        }
        else
        {
            return (.all)
        }
    }

}
