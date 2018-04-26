//
//  ViewController.swift
//  TIGPlayerSDKExample
//
//  Created by ks on 2017/09/05.
//
//

import UIKit
import PromiseKit
import TIGPlayer

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var table: UITableView!
    
    var contentsList = [Content]()
    var currentContent: Content!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        firstly {
            TIGSDK_ApiClient.getContentsList()
        }.then { value in
            self.contentsList = value as! [Content]
        }.then { _ in
            self.table.reloadData()
        }.catch{ error in
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ table: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contentsList.count
    }
    
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        let content = self.contentsList[indexPath.row]

        cell.textLabel?.text = content.contentsTitle
        
        return cell
    }
    
    func tableView(_ table: UITableView,didSelectRowAt indexPath: IndexPath) {
        self.currentContent = self.contentsList[indexPath.row]
        performSegue(withIdentifier: "toPlayerController",sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "toPlayerController") {
            let subVC: PlayerViewController = (segue.destination as? PlayerViewController)!
            subVC.content = self.currentContent
        }
    }
}

