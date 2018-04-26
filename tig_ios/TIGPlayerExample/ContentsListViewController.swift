//
//  ContentsListViewController.swift
//  TIGPlayerExample
//
//  Created by 藤原 章敬 on 2017/05/16.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import TIGPlayer
import PromiseKit
import SwiftyJSON
import ObjectMapper
import SDWebImage
import AudioToolbox

/// コンテンツリストの制御者
class ContentsListViewController: UIViewController ,UIPageViewControllerDataSource,UIPageViewControllerDelegate,ContentsListHistoryViewControllerDelegate {

    /// 最上位のview
    @IBOutlet weak var dlView: UIView!
    
    /// コンテンツ動画をシェアするボタン
    @IBOutlet weak var shareButton: ContentsShareButton!

    /// コンテンツリスト・再生履歴を表示するボタン
    @IBOutlet weak var contentsListButton: UIButton!
    
    /// サイドメニューボタン
    @IBOutlet weak var sideMenuButton: UIButton!
    
    /// コンテンツリストのコンテナ
    /// UIPageViewControllerが埋め込まれている
    @IBOutlet weak var containerView: UIView!

    /// ストックしたアイテムを表示する
    @IBOutlet weak var itemCollectionView: UICollectionView!

    /// コンテンツ毎のプレビュー画像
    @IBOutlet weak var movieImage: UIImageView!
    
    @IBOutlet weak var blurView: UIView!
    /// フッター
    @IBOutlet weak var stockAreaView: UIView!

    /// 左コンテンツへの移動
    @IBOutlet weak var leftButton: UIButton!
    
    /// 右コンテンツへの移動
    @IBOutlet weak var rightButton: UIButton!
    
    /// 再生ボタン
    var playButton: UIButton!

    /// 削除モード
    var deleteMode = false
    
    /// 現在のページNo
    var pageNumber = 0

    /// コンテンツリスト
    var contentsList = [Content]()
    
    /// 再生履歴
    var playContentsList = [Content]()
    
    /// ストックアイテムリスト
    var box = [Item]()
    
    /// ページ制御者
    var pageViewController: UIPageViewController?
    
    /// プレビュー画像制御者リスト
    var vcArray = [MovieViewController]()
    
    /// ぼかし画像配列
    var preImageUrlArray = [URL!]()
    
    /// コントロールパーツなどベースビュー幅と高さ
    let playContentBtnFrame:(width:CGFloat, height:CGFloat) = (128,135)
    
    /// ぼかし用のビュー
    var visualEffectView: UIVisualEffectView? = nil

    /// タップで画面ページングできるかどうか
    var isPageTransitionEnabledByTap = true
    
    /// URL Schemeで設定したURLからアプリを起動する場合contentsId設定
    var passedContentsIdFromUrl:String? = nil
    
    /// ActivityIndicator
    var indicator: UIActivityIndicatorView!
    
    /// indicator size
    let indicatorSize: CGSize = CGSize.init(width: 50, height: 50)
    
    /// コンテンツ一覧、再生履歴VC
    var listHistoryVC: ContentsListHistoryViewController!
    
    /// ステータスバー表示非表示
    var isStatusBarHidden = false
    
    /// GoogleAnalytics
    let tigAnalytics = TIGAnalytics()
    
    /// viewがロードされたタイミングでコンテンツリストを取得
    override func viewDidLoad() {
        NSLog("----viewDidLoad内----")
        super.viewDidLoad()
        
        // blur effect view作る styleはdark
        self.blurView.backgroundColor = UIColor.clear
        let deviceWidth =  deviceInfo.bounds.width > deviceInfo.bounds.height ? deviceInfo.bounds.width:deviceInfo.bounds.height
        self.blurView.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: deviceWidth, height: deviceWidth))
        let visualEffectView = UIVisualEffectView(effect:UIBlurEffect(style: .dark))
        visualEffectView.frame = self.blurView.frame
        self.blurView.insertSubview(visualEffectView, at: 0)
        
        // プレビュー画像配列クリア
        self.preImageUrlArray.removeAll()
        self.loadContentData()
        
        // Play button 初期化
        self.playButton = self.initPlayButton()
        self.dlView.addSubview(self.playButton)
        
        // タップで削除モードを消す
        let oneTapToCloseDeleteMode = UITapGestureRecognizer(target: self, action: #selector(self.tapToCloseDeleteMode(sender:)))
        oneTapToCloseDeleteMode.numberOfTapsRequired = 1
        self.dlView.addGestureRecognizer(oneTapToCloseDeleteMode)
        
        // 端末の向きがかわったらNotificationを呼ばす設定.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onOrientationChange(notification:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
        // コンテンツスライドビューでステータスバーを表示
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.showStatusBar),
                                               name: NSNotification.Name.showStatusBar,
                                               object: nil)
        // プレヤーが表示される時、ステータスバーを隠す
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.hideStatusBar),
                                               name: NSNotification.Name.hideStatusBar,
                                               object: nil)
        
        // 長押しを認識.
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGesture(sender:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.allowableMovement = 100
        self.itemCollectionView.addGestureRecognizer(longPressGesture)
        
        // ストックアイテムのcellをタップしたら、アイテム紹介サイトへ飛んで行く
        let oneTap:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.jumpToItemSite(sender:)))
        self.itemCollectionView.addGestureRecognizer(oneTap)
        
        // indicator生成して表示する
        self.indicatorCreater(size: self.indicatorSize)
        
        // 最初は隠して、ローディングが終わったら表示するように修正
        self.showOrHidePartsAtTheBeginning(hiding: true)
        
        // GoogleAnalytics
        self.view.addSubview(self.tigAnalytics)
    }
    
    /// status bar 非表示
    override open var prefersStatusBarHidden: Bool{
        return self.isStatusBarHidden
    }
    
    /// status bar style
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// ステータスバーを表示
    func showStatusBar(){
        self.isStatusBarHidden = false
        setNeedsStatusBarAppearanceUpdate()
        self.tigAnalytics.enableNotification()
    }
    
    /// ステータスバーを隠す
    func hideStatusBar(){
        self.isStatusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
        self.tigAnalytics.disableNotification()
    }
    
    /// 端末向きがかわったら呼び出される.
    func onOrientationChange(notification: NSNotification){
        NSLog("----onOrientationChange内----")
        self.playButton.center = self.dlView.center
        self.showOrHideStockArea()
        self.adjustGoLeftRightBtnsPositions()
    }
    
    /// 子ビューを描画するタイミングで現在ページをロード
    override func viewWillLayoutSubviews() {
        NSLog("----viewWillLayoutSubviews内----")
        guard contentsList.count != 0 else{
            return
        }
        self.loadCurrentPage(content:contentsList[self.pageNumber])
    }
    
    /// layout処理終了
    override func viewDidLayoutSubviews() {
        NSLog("----viewDidLayoutSubviews内----")
        self.playButton.center = self.dlView.center
        self.adjustGoLeftRightBtnsPositions()
        self.toggleBackScreen(self.deleteMode)
        self.showOrHideStockArea()
        self.view.layoutIfNeeded()
    }
    
    /// View の表示が完了
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /// View の非表示が完了
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    /// コンテンツリスト取得
    /// コンテンツリスト画面描画準備
    func loadContentData(){
        firstly {
            ApiClient.request(url:Router.apiHost.getURL(path: Router.path.contentsList))
            }.then { value in
                self.parseContentListResponse(json: JSON(value))
            }.then { _ in
                self.preapareForContentsRendering(contentsList:self.contentsList)
            }.catch{ error in
                self.leftButton.isHidden = true
                self.rightButton.isHidden = true
                TIGLog.error(message: "PromiseKit", anyObject:error)
        }
    }

    /// コンテンツリストjsonをパース
    ///
    /// - Parameter json: json
    func parseContentListResponse(json: JSON) {
        print(json)
        if let jsonDic = json["body"]["contents_list"].array{
            let sorted = jsonDic.sorted(by: < )
            var contentsIds:[String] = []
            sorted.forEach{content in
                if let content = Content(JSON: content.dictionaryObject!){
                    self.contentsList.append(content)
                    contentsIds.append(content.contentsId)
                }
            }
            if contentsIds.count != 0{
                let defaults = UserDefaults.standard
                defaults.set(contentsIds, forKey: "contentsIds")
            }
            
            if self.passedContentsIdFromUrl != nil{
                for (index, content) in self.contentsList.enumerated(){
                    if let contentsId = content.contentsId, let idFromUrl = self.passedContentsIdFromUrl {
                        print("****passedContentsIdFromUrl:\(idFromUrl)****")
                        print("****index:\(index)&contentsId:\(contentsId)****")
                        if "\(contentsId)" == "\(idFromUrl)" {
                            self.pageNumber = index
                            print("****UniversalLinkもしくはURLSchemaに\(self.pageNumber + 1)ページ目が指定されました****")
                        }
                    }
                }
            }
        }
    }

    /// コンテンツリスト画面描画準備
    ///
    /// - Parameter contentsList: contentsList
    func preapareForContentsRendering(contentsList: [Content]){
        var index = 0
        contentsList.forEach{ content in
            var items:Items? = PersistentManager.getByPrimaryKey(Items.self, primaryKey: content.contentsId)
            if let  _ = items{
            }else{
                items = Items()
            }
            PersistentManager.update(items){
                items!.contentsId = content.contentsId
            }
            
            /// コンテンツの数だけプレビュー動画制御者を生成
            let vc = storyboard?.instantiateViewController(withIdentifier:String(describing: MovieViewController.self)) as! MovieViewController
            
            if let title = content.contentsTitle{
                vc.titleStr = title
            }
            if let url = self.getMovieBackGroundUrl(index: index){
                NSLog("index\(index)のurlは：\(url)")
                vc.url = url
                self.preImageUrlArray.append(url)
            }
            if let duration = content.contentsDuration{
                vc.duration = TIGPlayerUtils.positionFormatTime(position: duration)
            }
            if let description = content.rootDescription{
                vc.descriptionStr = description
            }
            self.vcArray.append(vc)
            index = index + 1
        }

        // ContainerView に Embed した UIPageViewController を取得する
        self.pageViewController = childViewControllers[0] as? UIPageViewController

        // dataSource を設定する
        self.pageViewController!.dataSource = self
        self.pageViewController!.delegate = self

        // 最初に表示する画面として配列の先頭の ViewController を設定する
        guard vcArray.count > 0 else{
            self.leftButton.isHidden = true
            self.rightButton.isHidden = true
            self.playButton.isHidden = true
            return
        }
        
        // 指定ページへ遷移
        self.pageJumpingForward(animated:false)
        
        // page numberのチェックと再設定がありますので
        self.checkToLeftRightButton()
        
        // コレクションビューに表示するストックアイテムデータ
        self.itemCollectionView.delegate = self
        self.itemCollectionView.dataSource = self
        
        // 現在ページをロードする
        self.loadCurrentPage(content:contentsList[pageNumber])
        
        // 再生履歴の読込
        loadPlayContentsList()
    }


    /// 指定したコンテンツIDのページをロード
    ///
    /// - Parameter contentId: contentId
    func loadCurrentPage(content: Content){
        if let contentsId = content.contentsId{
            // TIGしたアイテムを取得してコレクションビューに表示する
            if let items = PersistentManager.getByPrimaryKey(Items.self, primaryKey:contentsId){
                self.box = items.populate()
                self.itemCollectionView.reloadData()
                self.itemCollectionView.layoutIfNeeded()
            }
            
            // 共有するコンテンツのcontentsIdを設定
            self.shareButton.setValue(contentsId, forKey: "contentsId")
        }

        // 現在ロードしているコンテンツをローカルストレージに保存
        saveCurrentContentId(content: content)
    }
    
    /// 現在ロードしているコンテンツをローカルストレージに保存
    ///
    /// - Parameter content: content
    func saveCurrentContentId(content:Content){
        var currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue)
        if let  _ = currentContent{
        }else{
            currentContent = CurrentContent()
        }
        
        // 現在のコンテンツ内容更新
        PersistentManager.update(currentContent){
            currentContent!.contentsId = content.contentsId
            currentContent!.videoUrl = content.videoUrl
            currentContent!.videoShotPrev = content.videoShotPrev
            if let contentsDesc = content.contentsDesc{
                currentContent!.contentsDesc = contentsDesc
            }
            if let contentsTitle = content.contentsTitle{
                currentContent!.contentsTitle = contentsTitle
            }
            if let groupIdent = content.groupIdent{
                currentContent!.groupIdent = groupIdent
            }
        }
    }
    
    /// 動画プレビュー画像URLを取得
    ///
    /// - Parameter index: pageIndex
    /// - Returns: return URL?
    func getMovieBackGroundUrl(index:Int)->URL?{
        if let backgroundImageurl = self.contentsList[index].contentsImage{
            if let url =  NSURL(string:backgroundImageurl) as URL?{
                return url
            }
        }
        return nil
    }
    
    /// 動画再生
    ///
    /// - Parameter sender: UIButton
    func tapSingle(sender: UIButton) {
        let alert = NetworkAlertController.getConnectionAlert()
        if alert.getNetworkCheck() {
            return self.PlayMovie()
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    /// 長押しで削除モードに切り替え
    ///
    /// - Parameter sender: UILongPressGestureRecognizer
    func longPressGesture(sender: UILongPressGestureRecognizer){
        if(sender.state == UIGestureRecognizerState.began){
            if(!self.deleteMode){
                self.shortVibrate()
                self.deleteMode = true
                self.updatePartsAppearanceWhileDeleteModeChange(deleteMode: self.deleteMode)
                self.itemCollectionView.reloadData()
            }
        }
    }
    
    /// 長押しで削除モード起動時バイブ音
    func shortVibrate() {
        AudioServicesPlaySystemSound(1003);
        AudioServicesDisposeSystemSoundID(1003);
    }
    
    /// ストックアイテムコレクション内でアイテムセルをタップしたら、紹介サイトへ飛ぶ
    func jumpToItemSite(sender: UITapGestureRecognizer){
        if(sender.state == UIGestureRecognizerState.ended){
            if (!self.deleteMode) {
                let point = sender.location(in: self.itemCollectionView)
                print ("point: \(point)")
                // touch locationでcollection viewのindexを取得する
                guard let tappedIndexPath:IndexPath = self.itemCollectionView.indexPathForItem(at: point) else {
                    return
                }
                print("itemIndex:\(tappedIndexPath.item)")
                    
                if let url = NSURL(string:box[tappedIndexPath.item].itemWebURL){
                    guard let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue)else{
                        return
                    }
                    
                    self.tigAnalytics.config(contentsId: currentContent.groupIdent + "-" + currentContent.contentsId)
                    
                    TIGNotification.post(TIGNotification.linkout, from: nil, payload:[
                        "scene": "contentsList",
                        "itemId": box[tappedIndexPath.item].itemId,
                        "url": box[tappedIndexPath.item].itemWebURL
                        ])
                    
                    UIApplication.shared.openURL(url as URL)
                }
            }
        }
    }
    
    /// 削除モードのアイテム削除ボタンがタップされる時
    ///
    /// - Parameter sender: UITapGestureRecognizer
    func tapToCloseDeleteMode(sender:UITapGestureRecognizer){
        self.closeDeleteMode()
    }
    
    /// deleteModeを終了させる
    func closeDeleteMode(){
        if self.deleteMode {
            self.deleteMode = false
            self.updatePartsAppearanceWhileDeleteModeChange(deleteMode: deleteMode)
            self.checkToLeftRightButton()
            self.deSelectAllForDelete()
            if self.box.count <= 0 {
                // Hide stock area
                self.stockAreaView.isHidden = true
                self.downMovieTitleTimeLabelsPositions()
            }
        }
    }
    /// 背景画像を切り替え
    /// 削除モード時はぼかし効果を入れる
    ///
    /// - Parameter mode: mode description
    func toggleBackScreen(_ mode: Bool) {
        // 背景にぼかし画像を設定
        if self.preImageUrlArray.count > 0 {
            NSLog("preImageUrlArrayの長さ：\(self.preImageUrlArray.count)")
            let preImageUrl = self.preImageUrlArray[self.pageNumber]
            self.movieImage.sd_setImage(with: preImageUrl!, completed: { (image, error, imageCacheType, imageUrl) in
                if image != nil{
                    self.indicator.stopAnimating()
                    self.showOrHidePartsAtTheBeginning(hiding: false)
                    self.checkToLeftRightButton()
                }
            })
        }
    }
    
    /// サイドメニュー表示
    @IBAction func showSideMenu(_ sender: Any) {
        let storyboard: UIStoryboard = UIStoryboard(name: "SideMenuViewController", bundle: Bundle.main)
        let vc: SideMenuViewController = storyboard.instantiateInitialViewController() as! SideMenuViewController
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: false, completion: nil)
    }
    
    /// コンテンツを１つ左へ移動
    ///
    /// - Parameter sender: sender
    @IBAction func pushLeft(_ sender: Any) {
        guard self.vcArray.count != 0, self.isPageTransitionEnabledByTap else{
            return
        }
        if (pageNumber > 0) {
            pageNumber -= 1
            self.pageJumpingReverse(animated: true)
        }
        self.toggleBackScreen(self.deleteMode)
    }


    /// コンテンツを１つ右へ移動
    ///
    /// - Parameter sender: sender
    @IBAction func pushRight(_ sender: Any) {
        guard self.vcArray.count != 0, self.isPageTransitionEnabledByTap else{
            return
        }
        let pageMax = self.vcArray.count
        if (pageNumber < pageMax-1) {
            pageNumber += 1
            self.pageJumpingForward(animated:true)
        }
        self.toggleBackScreen(self.deleteMode)
    }

    /// コンテンツ一覧と再生履歴を表示
    ///
    /// - Parameter sender: sender
    @IBAction func showContentsListAndHistoryView(_ sender: Any) {
        if self.listHistoryVC == nil {
            let storyboard: UIStoryboard = UIStoryboard(name: "ContentsListHistoryViewController", bundle: Bundle.main)
            self.listHistoryVC = storyboard.instantiateInitialViewController() as! ContentsListHistoryViewController
            self.listHistoryVC.modalPresentationStyle = .overFullScreen
            self.listHistoryVC.delegate = self
            self.listHistoryVC.contentsList = self.contentsList
            self.listHistoryVC.allContentsList = self.contentsList
            self.listHistoryVC.playContentsList = self.playContentsList
        }else{
            self.loadPlayContentsList()
            self.listHistoryVC.contentsList = self.contentsList
            self.listHistoryVC.allContentsList = self.contentsList
            self.listHistoryVC.playContentsList = self.playContentsList
            self.listHistoryVC.viewDidLayoutSubviews()
        }
        // コンテンツ一覧、再生履歴画面表示
        self.present(self.listHistoryVC, animated: true, completion: nil)
    }

    // MARK: -ContentsListHistoryViewControllerDelegate-
    func selectContent(sender: ContentsListHistoryViewController, selectedContent: Content) {
        sender.dismiss(animated: true) {
            //            let index = self.contentsList.index{ return $0 === content }
            //            self.pageNumber = index!
            // pageNumberを取得して、ページ更新する
            for (index, content) in self.contentsList.enumerated(){
                if let contentsId = content.contentsId, let selectedContentsId = selectedContent.contentsId{
                    print("contentsId:\(contentsId)")
                    print("selectedContentsId:\(selectedContentsId)")
                    if "\(contentsId)" == "\(selectedContentsId)" {
                        self.pageNumber = index
                        self.pageJumpingForward(animated: false)
                        // この時点で画面更新
                        self.loadCurrentPage(content:content)
                        self.toggleBackScreen(self.deleteMode)
                        return
                    }
                }
            }
        }
    }
    
    func selectItem(sender: ContentsListHistoryViewController, selectedContent: Content, selectedItem: Item) {
        if let url = NSURL(string:selectedItem.itemWebURL){
            self.tigAnalytics.config(contentsId: selectedContent.groupIdent + "-" + selectedContent.contentsId)
            
            TIGNotification.post(TIGNotification.linkout, from: nil, payload:[
                "scene": "contentsList",
                "itemId": selectedItem.itemId,
                "url": selectedItem.itemWebURL
                ])
            
            UIApplication.shared.openURL(url as URL)
        }
    }
    
    /// 選択したアイテムを削除する
    ///
    /// - Parameter sender: sender
    func deleteSelectedItems() {
        guard contentsList.count != 0 else{
            return
        }
        
        guard let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue)else{
            return
        }
        
        if let items = PersistentManager.getByPrimaryKey(Items.self,primaryKey:contentsList[pageNumber].contentsId){
            var indexPathes = [IndexPath]()
            items.list.forEach({ item in
                if item.currentSelectedStateForDelete{
                    indexPathes.append(IndexPath(item: indexOfKeyInBox(key: "\(currentContent.contentsId)\(item.itemId)"), section: 0))
                }
            })
            items.list.forEach({ item in
                if item.currentSelectedStateForDelete{
                    self.deleteEachItem(itemid: item.itemId)
                }
            })
            self.box = items.populate()
            self.itemCollectionView.deleteItems(at: indexPathes)
            self.itemCollectionView.reloadData()
            // アイテムが全部削除された場合
            if self.box.count <= 0{
                self.closeDeleteMode()
            }
        }
    }

    /// 削除モード時に全選択解除
    func deSelectAllForDelete() {
        guard contentsList.count != 0 else{
            return
        }
        if let items = PersistentManager.getByPrimaryKey(Items.self,primaryKey:contentsList[pageNumber].contentsId){
            items.list.forEach({ item in
                self.updateCurrentSelectedForDelete(itemid: item.itemId, selected: false)

            })
            self.box = items.populate()
        }
        self.itemCollectionView.reloadData()
    }

    /// アイテムIDを指定して、ストックアイテムを削除
    ///
    /// - Parameter itemid: itemid
    func deleteEachItem(itemid: String) {
        TIGLog.debug(message: "itemID:",anyObject: itemid)
        if let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue){
            PersistentManager.delete(ItemModel.self, primaryKey: "\(currentContent.contentsId)\(itemid)")
        }
    }
    
    /// アイテムIDを指定して、ストックアイテムが現在、削除対象として選択されているかどうかを更新
    ///
    /// - Parameters:
    ///   - itemid: itemid
    ///   - selected: selected
    ///   - populate: 永続化モデルから通常モデルへの変換するかどうか
    func updateCurrentSelectedForDelete(itemid: String,selected: Bool,populate:Bool? = nil) {
        TIGLog.debug(message: "itemID,currentSelectedForDeleteitemid:",anyObject: "\(itemid),\(selected)")
        if let currentContent =
            PersistentManager.getByPrimaryKey(
                CurrentContent.self,
                primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue
            ){
            if let savedItem = PersistentManager.getByPrimaryKey(ItemModel.self, primaryKey: "\(currentContent.contentsId)\(itemid)"){
                PersistentManager.update(savedItem){
                    savedItem.currentSelectedStateForDelete = selected
                }
            }
        }
        
        /// 永続化モデルから通常モデルへの変換
        if let populate = populate{
            guard populate else{
                return
            }
            guard let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue)else{
                return
            }
            if let items = PersistentManager.getByPrimaryKey(Items.self, primaryKey:currentContent.contentsId){
                self.box = items.populate()
            }
        }
    }
    
    /// 動画再生
    func PlayMovie() {
        // コンテンツを取得
        let content = contentsList[self.pageNumber]
        guard let contentsId = content.contentsId, let videoUrl = content.videoUrl else{
                return
        }
        TIGLog.debug(message: "contentid", anyObject: contentsId)
        
        // 動画urlを生成して再生する
        if let movieUrl:URL = URL.init(string: videoUrl){
            print("movieUrl: \(movieUrl)")
            TIGLog.debug(message: "URL:",anyObject: movieUrl)
            MediaManager.sharedInstance.playWideVideo(url:movieUrl,
                                                      contentView: self.dlView,
                                                      userinfo: ["contentsId": contentsId])
        }

        // ステータスバーを隠す
        NotificationCenter.default.post(name: .hideStatusBar, object: self, userInfo: nil)
        
        // プレーリストに元々の位置から削除する
        if let index = self.playContentsList.index(where: { return $0 === contentsList[self.pageNumber] }) {
            playContentsList.remove(at: index)
        }
        
        // プレーリストの一番最初に挿入する
        playContentsList.insert(contentsList[self.pageNumber], at: 0)
        
        // 再生履歴のcontentsIdをUserDefaultsに保存する
        savePlayContentsList()
    }

    /// 再生履歴の保存
    func savePlayContentsList() {
        var ids: Array<String> = []
        
        playContentsList.forEach{ content in
            if content.contentsId != nil {
                ids.append(content.contentsId)
            }
        }
        
        let defaults = UserDefaults.standard
        defaults.set(ids, forKey: "playContentsIdsKey")
        defaults.synchronize()
    }
    
    /// 再生履歴の読込
    func loadPlayContentsList() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "playContentsIdsKey") == nil {
            return
        }
        let ids: Array<String> = defaults.object(forKey: "playContentsIdsKey") as! Array<String>
        self.playContentsList.removeAll()
        ids.forEach{ id in
            contentsList.forEach{ content in
                if content.contentsId == id {
                    self.playContentsList.append(content)
                }
            }
        }
    }
    
    /// キーを指定してストックアイテムのインデックス取得
    ///
    /// - Parameter key: key
    /// - Returns: index
    func indexOfKeyInBox(key:String) -> Int{
        var index = 0
        for item in self.box{
            if item.key == key{
                return index
            }
            index += 1
        }
        return 0
    }

    /// 前へページ遷移
    func pageJumpingForward(animated: Bool){
        print("pageNumber: \(self.pageNumber)")
        let toPageVC:MovieViewController = self.vcArray[self.pageNumber]
        self.pageViewController!.setViewControllers([toPageVC], direction: .forward, animated: animated, completion: nil)
    }
    
    /// 後ろへページ遷移
    func pageJumpingReverse(animated: Bool){
        print("pageNumber: \(self.pageNumber)")
        let toPageVC:MovieViewController = self.vcArray[self.pageNumber]
        self.pageViewController!.setViewControllers([toPageVC], direction: .reverse, animated: animated, completion: nil)
    }
    
    // MARK:　UIPageViewControllerDelegate
    /// 一つ前のページへ
    ///
    /// - Parameters:
    ///   - pageViewController: pageViewController
    ///   - viewController: Before
    /// - Returns: nil or UIViewController
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = vcArray.index(of: viewController as! MovieViewController), index > 0 else {
            self.pageNumber -= 1
            self.checkToLeftRightButton()
            return nil
        }
        
        self.pageNumber =  vcArray.index(of: pageViewController.viewControllers?.first as! MovieViewController)!
        self.checkToLeftRightButton()
        return vcArray[index - 1]
    }

    /// 一つ後のページへ
    ///
    /// - Parameters:
    ///   - pageViewController: pageViewController
    ///   - viewController: MovieViewController
    /// - Returns: UIViewController or nil
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = vcArray.index(of: viewController as! MovieViewController), index < vcArray.count - 1 else {
            self.pageNumber += 1
            self.checkToLeftRightButton()
            return nil
        }
        
        self.pageNumber =  vcArray.index(of: pageViewController.viewControllers?.first as! MovieViewController)!
        self.checkToLeftRightButton()
        return vcArray[index + 1]
    }
    
    /// Called before a gesture-driven transition begins
    ///
    /// - Parameters:
    /// - pageViewController: pageViewController
    /// - pendingViewControllers: The view controllers that are being transitioned to.
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        self.isPageTransitionEnabledByTap = true
    }
    
    /// ページ移動終了後に現在のページNoを切り替える
    ///
    /// - Parameters:
    ///   - pageViewController: pageViewController
    ///   - finished: upon
    ///   - previousViewControllers: pre
    ///   - completed: completion Flag
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        NSLog("----pageViewControllerdidFinishAnimating内----")
        let index = vcArray.index(of: pageViewController.viewControllers?.first as! MovieViewController)
        self.pageNumber = index!
        self.adjustGoLeftRightBtnsPositions()
        self.loadCurrentPage(content:contentsList[pageNumber])
        self.toggleBackScreen(self.deleteMode)
        self.showOrHideStockArea()
    }

    /// 左、右への移動ボタンの表示非表示を切り替える
    func checkToLeftRightButton(){
        guard self.vcArray.count != 0 else{
            return
        }
        
        let pageMax = self.vcArray.count

        if pageNumber <= 0 {
            pageNumber = 0
            self.leftButton.isHidden = true
        } else {
            if !self.deleteMode {
                self.leftButton.isHidden = false
            }
        }
        if (pageNumber >= pageMax - 1) {
            pageNumber = pageMax - 1
            self.rightButton.isHidden = true
        } else {
            if !self.deleteMode{
                self.rightButton.isHidden = false
            }
        }
    }
    
    // MARK: -Position adjusting methods-
    /// Adjust go left and go right buttons' positions.
    func adjustGoLeftRightBtnsPositions(){
        // 左へ、右へボタンのY座標を調整
        self.leftButton.frame = CGRect.init(x: self.leftButton.frame.origin.x,
                                            y: self.dlView.center.y - self.leftButton.frame.height/2,
                                            width: self.leftButton.frame.width,
                                            height: self.leftButton.frame.height)
        
        self.rightButton.frame = CGRect.init(x: self.rightButton.frame.origin.x,
                                             y: self.dlView.center.y - self.rightButton.frame.height/2,
                                             width: self.rightButton.frame.width,
                                             height: self.rightButton.frame.height)
    }
    
    /// Show or hide stock area and adjust movie title and movie time labels
    func showOrHideStockArea(){
        // Stock items exist
        if self.box.count > 0 {
            // Show stock area
            self.stockAreaView.isHidden = false
            // Adjust movie title and movie time labels' positions
            self.upMovieTitleTimeLabelsPositions()
        }else{
            // Hide stock area
            self.stockAreaView.isHidden = true
            // Adjust movie title and movie time labels' positions
            self.downMovieTitleTimeLabelsPositions()
        }
    }
    
    /// Up movie title and movie time labels' positions
    func upMovieTitleTimeLabelsPositions(){
        guard self.vcArray.count != 0 else{
            return
        }
        
        NSLog("PageNumber:\(self.pageNumber)")
        let vc:MovieViewController = self.vcArray[self.pageNumber]
        vc.stockAreaHidden = false
    }
    
    /// Down movie title and movie time labels' positions
    func downMovieTitleTimeLabelsPositions(){
        guard self.vcArray.count != 0 else{
            return
        }
        
        NSLog("PageNumber:\(self.pageNumber)")
        let vc:MovieViewController = self.vcArray[self.pageNumber]
        vc.stockAreaHidden = true
    }
    
    /// 削除モード開始、終了時、画面各パーツの表示非表示
    func updatePartsAppearanceWhileDeleteModeChange(deleteMode: Bool){
        self.playButton.isHidden = deleteMode
        self.shareButton.isHidden = deleteMode
        self.contentsListButton.isHidden = deleteMode
        self.sideMenuButton.isHidden = deleteMode
        self.containerView.isHidden = deleteMode
        self.leftButton.isHidden = deleteMode
        self.rightButton.isHidden = deleteMode
    }
    
    /// 再生ボタン初期化
    func initPlayButton() -> UIButton{
        let playButton = UIButton.init(frame: CGRect.init(x: self.dlView.center.x - self.playContentBtnFrame.width/2,
                                                          y: self.dlView.center.y - self.playContentBtnFrame.height/2,
                                                          width: self.playContentBtnFrame.width,
                                                          height: self.playContentBtnFrame.height))
        playButton.center = self.dlView.center
        playButton.backgroundColor = UIColor.clear
        playButton.isHidden = true
        playButton.tag = 2
        playButton.setImage(UIImage.init(named: "PlayContent"), for: .normal)
        playButton.addTarget(self, action: #selector(self.tapSingle(sender:)), for: .touchUpInside)
        return playButton
    }
    
    /// ローディング
    func indicatorCreater(size: CGSize){
        // ActivityIndicatorを作成＆中央に配置
        self.indicator = UIActivityIndicatorView()
        self.indicator.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.indicator.center = self.dlView.center
        self.indicator.hidesWhenStopped = true
        self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        self.indicator.startAnimating()
        self.dlView.addSubview(self.indicator)
    }
    
    /// 一番最初画面ローディング完了後画面パーツを表示する
    func showOrHidePartsAtTheBeginning(hiding: Bool){
        self.shareButton.isHidden = hiding
        self.contentsListButton.isHidden = hiding
        self.sideMenuButton.isHidden = hiding
        self.playButton.isHidden = hiding
    }
}
