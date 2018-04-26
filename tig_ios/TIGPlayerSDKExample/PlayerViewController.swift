//
//  PlayerViewController.swift
//  TIGPlayerSDKExample
//
//  Created by ks on 2017/09/05.
//
//

import UIKit

import TIGPlayer

class PlayerViewController: UIViewController {
    
    public var content: Content! = nil
    
    var player: TIGSDK_Player!
    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.player = TIGSDK_Player()
        self.player.tigMode = TIGSDK_Player.modeState.blink
        self.player.enableToggleMode = false
        self.player.showShareButton = false
        self.player.enableWipe = false
        self.player!.playWithURL(contents: self.content, contentView: self.view)
        
        self.timer = Timer.scheduledTimer(timeInterval:5.0,
                                          target: self,
                                          selector: #selector(updateCurrentTime),
                                          userInfo:nil,
                                          repeats: true)
    }
    
    func updateCurrentTime() {
        // ストックアイテムを取得し、1つ削除してセットしなおす
        if (self.player != nil) {
            var items = self.player.getStockItems()
            dump(items)
            
            if !items.isEmpty {
                items.removeFirst()
                self.player.setStockItems(stockItems: items)
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
