//
//  LigandListVC.swift
//  swifty_proteins
//
//  Created by Nyameko RARANE on 2019/01/30.
//  Copyright © 2019 Nyameko RARANE. All rights reserved.
//

import UIKit

class LigandListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    var ligandList:[String] = []
    var searchedLigands:[String] = []
    var searchingForLigands = false
    var selectedLigand: LigandModel!
    
    @IBOutlet weak var ligandTable: UITableView!
    @IBOutlet weak var ligandSearchBar: UISearchBar!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if (searchingForLigands)
        {
            return (searchedLigands.count)
        }
        else
        {
            return (ligandList.count)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
        if (searchingForLigands)
        {
            retrieveLigand(searchedLigands[indexPath.row])
        }
        else
        {
            retrieveLigand(ligandList[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ligandCell", for: indexPath)  as! LigandTableViewCell
        if (searchingForLigands)
        {
            cell.ligandName.text = searchedLigands[indexPath.row]
        }
        else
        {
            cell.ligandName.text = ligandList[indexPath.row]
        }
        
        return (cell)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        searchingForLigands = true
        searchedLigands = []
        searchedLigands = ligandList.filter({$0.contains((ligandSearchBar.text!.uppercased()))})
        if (searchedLigands.count == 0)
        {
            searchedLigands = ligandList
        }
        DispatchQueue.main.async
            {
                self.ligandTable.reloadData()
        }
    }
    
    func retrieveLigandsFromFile()
    {
        let path = Bundle.main.path(forResource: "ligands", ofType: "txt")
        let fileManager = FileManager.default
        if (fileManager.fileExists(atPath: path!))
        {
            do
            {
                let fileText = try String(contentsOfFile: path!, encoding: .utf8)
                ligandList = fileText.components(separatedBy: "\n")
            }
            catch
            {
                self.createAlert(title: "File Error", message: "Error occured when reading file")
            }
        }
        else
        {
            self.createAlert(title: "Ligands not found", message: "File containing ligands does not exist")
        }
    }
    
    func retrieveLigand(_ ligandName: String)
    {
        let url1 = "https://files.rcsb.org/ligands/view/"
        let url2 = "_ideal.pdb"
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        let indicator = UIActivityIndicatorView()
        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        self.view.addSubview(indicator)
        
        
        let finalUrl = URL(string: url1 + ligandName + url2)
        let task = URLSession.shared.dataTask(with: finalUrl!, completionHandler:
        {
            (data, response, error) in
            
            if (error != nil)
            {
                UIApplication.shared.endIgnoringInteractionEvents()
                indicator.stopAnimating()
                self.createAlert(title: "Ligand not retrieved", message: "Ligand \(ligandName) was not found.")
            }
            
            if (response != nil)
            {
                let response = response as? HTTPURLResponse
                if (response?.statusCode == 200)
                {
                    DispatchQueue.main.async
                        {
                            UIApplication.shared.endIgnoringInteractionEvents()
                            indicator.stopAnimating()
                            let responseContent = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.ascii.rawValue)) as String?
                            var atomArray: [String] = []
                            var connectionArray: [String] = []
                            
                            let lines = responseContent?.split(separator: "\n")
                            for line in lines!
                            {
                                if (line.range(of:"ATOM") != nil)
                                {
                                    atomArray.append(String(line))
                                }
                                if (line.range(of:"CONECT") != nil)
                                {
                                    connectionArray.append(String(line))
                                }
                            }
                            let nodes = self.getNodes(atomArray)
                            let connections = self.getConnections(connectionArray, nodes)
                            self.selectedLigand = LigandModel(name: ligandName, nodes: nodes, connections: connections)
                            self.performSegue(withIdentifier: "drawLigand", sender: self)
                    }
                }
                else
                {
                    DispatchQueue.main.async
                        {
                            UIApplication.shared.endIgnoringInteractionEvents()
                            indicator.stopAnimating()
                    }
                    self.createAlert(title: "Ligand not retrieved", message: "Ligand \(ligandName) was not found.")
                }
            }
            
        })
        task.resume()
    }
    
    func getNodes(_ atomsArray: [String])->[Node]
    {
        var atoms: [Node] = []
        var id = 1
        for atomString in atomsArray
        {
            
            let splitedAtom = atomString.split(separator: " ")
            let atom = getAtom(String(splitedAtom[11]))
            let color = getCPKColor(String(splitedAtom[11]).uppercased())
            let x = Float(splitedAtom[6])!
            let y = Float(splitedAtom[7])!
            let z = Float(splitedAtom[8])!
            let node:Node = Node(id: id, x_pos: x, y_pos: y, z_pos: z, node_color: color, atom: atom, plotted: false, plottedVector: nil)
            atoms.append(node)
            id = id + 1
        }
        return (atoms)
    }
    
    
    func getConnections(_ connectionArray: [String], _ nodes : [Node]) -> [Connection]
    {
        var connections: [Connection] = []
        
        for connectionString in connectionArray
        {
            let splitConnectionArray = connectionString.split(separator: " ")
            let firstNodeID = Int(splitConnectionArray[1])!
            for index in 2...splitConnectionArray.count - 1
            {
                let secondNodeID = Int(splitConnectionArray[index])!
                if (!doesConnectionExist(connections, firstNodeID, secondNodeID))
                {
                    let firstNode = self.getNodeByID(nodes, firstNodeID)!
                    let secondNode = self.getNodeByID(nodes, secondNodeID)!
                    connections.append(Connection(node1: firstNode, node2: secondNode))
                }
            }
        }
        return (connections)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "drawLigand"
        {
            let drawController = segue.destination as! Ligand3DVC
            drawController.ligandToDraw = self.selectedLigand
        }
    }
    
    func doesConnectionExist(_ connections: [Connection], _ id1: Int, _ id2: Int) -> Bool
    {
        for connection in connections
        {
            if ((connection.node1.id == id1 && connection.node2.id == id2 ) ||
                (connection.node1.id == id2 && connection.node2.id == id1 ))
            {
                return (true)
            }
        }
        return (false)
    }
    
    func getNodeByID(_ nodes: [Node], _ id: Int) -> Node?
    {
        var resultNode: Node? = nil
        for node in nodes
        {
            if (node.id == id)
            {
                resultNode = node
                break
            }
        }
        return (resultNode)
    }
    
    func getAtom(_ symbol: String) ->Atom?
    {
        var atom:Atom? = nil
        if let path = Bundle.main.path(forResource: "ElementsJSON", ofType: "json")
        {
            do
            {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                {
                    if let elements = jsonResponse!["elements"] as? [Any]
                    {
                        for element in elements
                        {
                            if let atomData = element as? [String: Any]
                            {
                                if (symbol.lowercased() == (atomData["symbol"] as! String).lowercased())
                                {
                                    atom = Atom(
                                        name: atomData["name"] as! String,
                                        atomic_mass: atomData["atomic_mass"] as! Double,
                                        number: atomData["number"] as! Int,
                                        symbol: atomData["symbol"] as! String,
                                        summary: atomData["summary"] as! String
                                    )
                                    break
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
                self.createAlert(title: "Element not found", message: "Element \(symbol) does not exist on the periodic table.")
            }
        }
        return (atom)
    }
    
    
    func getCPKColor(_ symbol: String)->UIColor
    {
        switch symbol
        {
        case "H":
            return UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        case "C":
            return UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        case "N":
            return UIColor(red: 0/255, green: 0/255, blue: 255/255, alpha: 1)
        case "O":
            return UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        case "F", "CL" :
            return UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1)
        case "BR":
            return UIColor(red: 220/255, green: 20/255, blue: 60/255, alpha: 1)
        case "I":
            return UIColor(red: 148/255, green: 0/255, blue: 211/255, alpha: 1)
        case "HE", "NE", "AR", "XE", "KR":
            return UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1)
        case "P":
            return UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)
        case "S":
            return UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)
        case "B":
            return UIColor(red: 250/255, green: 128/255, blue: 114/255, alpha: 1)
        case "LI", "NA", "K", "RB", "CS", "FR":
            return UIColor(red: 238/255, green: 130/255, blue: 238/255, alpha: 1)
        case "BE", "MG", "CA", "SR", "BA", "RA":
            return UIColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 1)
        case "TI":
            return UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
        case "FE":
            return UIColor(red: 255/255, green: 76/255, blue: 0/255, alpha: 1)
        default:
            return UIColor(red: 255/255, green: 105/255, blue: 180/255, alpha: 1)
        }
    }
    
    func createAlert(title: String, message: String)
    {
        let alert = UIAlertController(title : title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:
            {
                (action) in
                alert.dismiss(animated: true, completion: nil)
        }
        ))
        present(alert,animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        ligandSearchBar.delegate = self
        ligandTable.delegate = self
        
        //dismiss keyboard on tap
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // LigandTable.layer.backgroundColor = UIColor.black.cgColor
        retrieveLigandsFromFile()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

}
