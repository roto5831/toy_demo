//
//  ContentsListHistoryViewController.swift
//  TIGPlayerExample
//
//  Created by ks on 2017/10/31.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import SDWebImage
import TIGPlayer

protocol ContentsListHistoryViewControllerDelegate:class {
    func selectContent(sender: ContentsListHistoryViewController, selectedContent:Content)
    func selectItem(sender: ContentsListHistoryViewController,  selectedContent:Content, selectedItem:Item)
}


class ContentsListHistoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout, ContentsListHistoryCellDelegate {

    /// コンテンツリストラベル
    @IBOutlet weak var contentsListButton: UIButton!
    
    /// 再生一覧ラベル
    @IBOutlet weak var playListButton: UIButton!
    
    /// コンテンツのコレクションビュー
    @IBOutlet weak var collectionView: UICollectionView!
    
    /// コンテンツリスト
    public var contentsList = [Content]()
    public var allContentsList = [Content]()
    public var playContentsList = [Content]()
    
    /// リスト画面列挙
    enum listType {
        case allContents
        case playedContents
    }
    
    /// 表示しているリスト
    var isShowingList = listType.allContents
    
    /// デリゲート
    weak var  delegate:ContentsListHistoryViewControllerDelegate? = nil
    
    /// ぼかし用のビュー
    var visualEffectView: UIVisualEffectView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.clear
        visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        visualEffectView?.frame = self.view.bounds
        self.view.insertSubview(visualEffectView!, at: 0)
        
        let nib = UINib(nibName: "ContentsListHistoryCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ContentsListHistoryCell")
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visualEffectView?.frame = self.view.bounds
        switch self.isShowingList {
        case listType.allContents:
            self.allContents(UIButton.init())
            break
        case listType.playedContents:
            self.playContents(UIButton.init())
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// 画面回転時にコレクションのセルのサイズを再設定する
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        getViewAppearance(size: size)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        getViewAppearance(size: self.view.frame.size)
    }

    func getViewAppearance(size: CGSize){
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flowLayout.invalidateLayout()
    }
    
    /// ボタンのスタイルを設定
    func changeButtonState(button:UIButton, enable: Bool) {
        var buttonImage:UIImage? = nil
        if enable{
            switch button.tag{
            case 4:
                buttonImage = UIImage.init(named: "ContentsListButton")
                break
            case 5:
                buttonImage = UIImage.init(named: "PlayListButton")
                break
            default:
                break
            }
        }else{
            switch button.tag{
            case 4:
                buttonImage = UIImage.init(named: "ContentsListTitleGray")
                break
            case 5:
                buttonImage = UIImage.init(named: "PlayListTitleGray")
                break
            default:
                break
            }
        }
        
        UIView.performWithoutAnimation {
            button.setImage(buttonImage!, for: .normal)
            button.layoutIfNeeded()
        }
    }
    
    /// コンテンツリスト
    ///
    /// - Parameter sender: sender
    @IBAction func allContents(_ sender: Any) {
        self.isShowingList = listType.allContents
        self.contentsList = self.allContentsList
        self.collectionView.reloadData()
        
        self.changeButtonState(button: self.contentsListButton, enable: true)
        self.changeButtonState(button: self.playListButton, enable: false)
    }

    /// 再生一覧
    ///
    /// - Parameter sender: sender
    @IBAction func playContents(_ sender: Any) {
        self.isShowingList = listType.playedContents
        self.contentsList = self.playContentsList
        self.collectionView.reloadData()
        
        self.changeButtonState(button: self.contentsListButton, enable: false)
        self.changeButtonState(button: self.playListButton, enable: true)
    }

    /// 閉じる
    ///
    /// - Parameter sender: sender
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentsListHistoryCell", for: indexPath) as! ContentsListHistoryCell
        let content = self.contentsList[indexPath.row % self.contentsList.count]
        
        cell.delegate = self
        
        cell.titleLabel.text = content.contentsTitle
        cell.timeLabel.text = TIGPlayerUtils.positionFormatTime(position: content.contentsDuration)
        cell.thumbnailImage.sd_setImage(with: URL(string: content.contentsImage!))
        
        cell.content = content
        cell.reloadStockItems()

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contentsList.count
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let content = self.contentsList[indexPath.row % self.contentsList.count]
        self.delegate?.selectContent(sender: self, selectedContent: content)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width: CGFloat = collectionView.frame.width
        let height: CGFloat = 97
        return CGSize(width: width, height: height)
    }
    
    // MARK: - ContentsListHistoryCellDelegate
    func selectItem(sender: ContentsListHistoryCell, selectedItem: Item) {
        self.delegate?.selectItem(sender: self, selectedContent: sender.content, selectedItem: selectedItem)
    }
}
