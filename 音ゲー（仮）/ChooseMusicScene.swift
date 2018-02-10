//
//  ChooseSoundScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//



import SpriteKit
import GameplayKit

class ChooseMusicScene: SKScene {
	
	var picker:PickerKeyboard!
	let playButton = UIButton()
	let settingButton = UIButton()
	let settingImage = UIImage(named: "SettingIcon")
	let settingImageSelected = UIImage(named: "SettingIconSelected")
	
	
	override func didMove(to view: SKView) {
		
		backgroundColor = .white
		
		//ピッカーキーボードの設置
		let rect = CGRect(origin:CGPoint(x:self.frame.midX - self.frame.width/6,y:self.frame.height/3) ,size:CGSize(width:self.frame.width/3 ,height:50))
		picker = PickerKeyboard(frame:rect)
		picker.backgroundColor = .gray
		picker.isHidden = false
		self.view?.addSubview(picker!)
		
		
		//ボタンの設定
		playButton.addTarget(self, action: #selector(onClickPlayButton(_:)), for: .touchUpInside)
		playButton.frame = CGRect(x: 0,y: 0, width:self.frame.width/5, height: 50)
		playButton.backgroundColor = UIColor.red
		playButton.layer.masksToBounds = true
		playButton.setTitle("この曲で遊ぶ", for: UIControlState())
		playButton.setTitleColor(UIColor.white, for: UIControlState())
		playButton.setTitle("この曲で遊ぶ", for: UIControlState.highlighted)
		playButton.setTitleColor(UIColor.black, for: UIControlState.highlighted)
		playButton.isHidden = false
		playButton.layer.cornerRadius = 20.0
		playButton.layer.position = CGPoint(x: self.frame.midX + self.frame.width/3, y:self.frame.height*29/72)
		self.view?.addSubview(playButton)
		
		
		settingButton.setImage(settingImage, for: .normal)
		settingButton.setImage(settingImageSelected, for: .highlighted)
		settingButton.addTarget(self, action: #selector(onClickSettingButton(_:)), for: .touchUpInside)
		settingButton.frame = CGRect(x: self.frame.width*9.4/10,y: self.frame.width*0.1/10, width:self.frame.width/16, height: self.frame.width/16)//yは上からの座標
		self.view?.addSubview(settingButton)
	}
	
	override func update(_ currentTime: TimeInterval) {
		
	}
	
	@objc func onClickPlayButton(_ sender : UIButton){
		//消す
		hideMainContents()
		
		picker.resignFirstResponder()	//FirstResponderを放棄
		
		//移動
		let scene = GameScene(musicName:picker.textStore ,size: (view?.bounds.size)!)
		let skView = view as SKView!
		skView?.showsFPS = true
		skView?.showsNodeCount = true
		skView?.ignoresSiblingOrder = true
		scene.scaleMode = .resizeFill
		skView?.presentScene(scene)  // GameSceneに移動

	}
	
	@objc func onClickSettingButton(_ sender : UIButton){
		//消す
		hideMainContents()
		
		//表示
	}
	
	func showMainContents(){
		picker.isHidden = false
		playButton.isHidden = false
		settingButton.isHidden = false
	}
	
	func hideMainContents(){
		picker.isHidden = true
		playButton.isHidden = true
		settingButton.isHidden = true
	}
}
