//
//  ViewController.swift
//  SelectPhotosS1
//
//  Created by oshitahayato on 2017/12/26.
//  Copyright © 2017年 oshitahayato. All rights reserved.
//

import UIKit
//バイブレーションインポート
import AudioToolbox
//写真exif編集のため
import Photos



class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	//写真を表示するビュー
	@IBOutlet weak var imageView: UIImageView!
	
	//バイブレーションタイマー
	var timer: Timer!
	var nowPlaying = "true"
	var bpm = 60.0
	
	//1回だけloadされる
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		//デフォルト画像設定
		imageView.image = UIImage(named:"nophoto.png")
		// 自身の変数 nowPlaying を監視対象として登録
		self.addObserver(self, forKeyPath: "self.nowPlaying", options: [.old, .new], context: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//カメラロールから写真を選択する処理
	@IBAction func choosePicture(_ sender: Any) {
		//カメラロール利用可能かどうか？
		if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
			//写真を選ぶビュー
			let pickerView = UIImagePickerController()
			//写真の選択元をカメラロール
			pickerView.sourceType = .photoLibrary
			//デリゲート
			pickerView.delegate = self
			//ビューに表示
			self.present(pickerView, animated: true)
			//表示されたビューからexif読み出し
			
		}
	}
	
	//写真を選んだあとに呼ばれる処理
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		//exif読み込み
		//get asset urlにより、画像の保存場所を取得
		let assetURL = info[UIImagePickerControllerReferenceURL] as? URL
		let url = NSURL(string: (assetURL?.description)!)
		
		let result = PHAsset.fetchAssets(withALAssetURLs: [url as! URL], options:nil)
		//写真情報を取得するため
		let asset:PHAsset = result.firstObject! as PHAsset
		let editOptions = PHContentEditingInputRequestOptions()
		editOptions.isNetworkAccessAllowed = true
		
		asset.requestContentEditingInput(with: editOptions, completionHandler: {(contentEditingInput, _) -> Void in
			
			let url = contentEditingInput?.fullSizeImageURL
			//画像nilの条件処理
			if let inputImage:CIImage = CoreImage.CIImage(contentsOf: url!){
				//print("画像:\(inputImage)")
				let meta:NSDictionary? = inputImage.properties as NSDictionary?
				//print("exif:\(meta?["{Exif}"] as? NSDictionary)")
				let exif:NSDictionary? = meta?["{Exif}"] as? NSDictionary
				let text = exif?.object(forKey: kCGImagePropertyExifUserComment) as! String?
				//print(text)
				//text -> double変換
				if(text == nil){
					print(text)
				}else{
					// if, guard などを使って切り分ける
					if let p = Double(text!){
						print(p)
						//心拍タイマー処理
						self.bpm = 60/p
						self.timerloop(bpm: self.bpm)
						self.nowPlaying = "false"
					}
				}
			}
		})
		/*
		*/
		//print(image)
		
		//選択した写真を取得する
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
		//ビューに選択
		self.imageView.image = image
		//写真を選ぶビューを引っ込める
		self.dismiss(animated: true)
		
	}
	
	//タイマーループ処理構造体
	func timerloop(bpm: Double){
		print(bpm)
		timer = Timer.scheduledTimer(timeInterval: bpm,
									 target: self,
									 selector: #selector(self.vibrateLoop),
									 userInfo: nil,
									 repeats: true)
		timer.fire()
		//print("looooooooooop")
	}
	
	//写真をリセットする処理
	@IBAction func resetPicture(_ sender: Any) {
		//アラートで確認
		let alert = UIAlertController(title: "確認", message: "画像を初期化しても良いですか？", preferredStyle: .alert)
		let okButton = UIAlertAction(title: "OK", style: .default, handler: {(action: UIAlertAction) -> Void in
			//デフォルトの画像を表示する
			self.imageView.image = UIImage(named:"nophoto.png")
			if(self.nowPlaying == "false"){
				self.nowPlaying = "true"
				print(self.nowPlaying)
				self.timer.invalidate()
			}
			
			
		})
		let cancelButton = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
		//アラートボタン追加
		alert.addAction(okButton)
		alert.addAction(cancelButton)
		//アラート表示
		present(alert,animated: true, completion: nil)
		//タイマー処理停止リセット
		//timer.invalidate()
	}
	
	// 監視対象の値に変化があった時に呼ばれる
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		//print(keyPath!) // プロパティ名
		//print(object!) // 対象オブジェクト
		print(change![.oldKey]!) // 変化前の値
		print(change![.newKey]!) // 変化後の値
		//タイマー処理停止リセット
		timer.invalidate()
		nowPlaying = "true"
	}
	// オブジェクト破棄時に監視を解除
	deinit {
		self.removeObserver(self, forKeyPath: "self.nowPlaying")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		//timerloop(bpm: self.bpm)
	}
	
	
	@objc func vibrateLoop(){
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
	


}

