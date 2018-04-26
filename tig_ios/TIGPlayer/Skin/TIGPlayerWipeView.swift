//
//  TIGPlayerWipeView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit

///wipe mode時に表示されるview
/// @ACCESS_OPEN
open class TIGPlayerWipeView: UIView, TIGPlayerCustomAction {

    
    /// TIGPlayer
    weak public var player: TIGPlayer?{
        didSet{
           self.wipeButton.player = player
        }
    }
    
    /// view内に内包されているボタン
    @IBOutlet weak var wipeButton: TIGPlayerWipeButton!
}

