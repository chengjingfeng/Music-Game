//
//  Lane.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2018/01/04.
//  Copyright © 2018年 NakaiKohei. All rights reserved.
//

import SpriteKit


class Lane {
    
    enum JudgeTimeState {    // enumはRange型をサポートしていないのでrawValueにRange型のものを代入することはできない
        case miss, bad, good, great, parfect, still, passed
    }
    
    enum ObsevationTimeState {
        case before, after, otherwise
    }
    
    //判定時間に関する定数群
    private let parfectUpperBorder = 0.05
    private let greatUpperBorder = 0.08
    private let goodUpperBorder = 0.085
    private let badUpperBorder = 0.09
    private let missUpperBorder = 0.1
    
    var timeLag: TimeInterval = 0.0
    var isTimeLagSet = false
    var laneNotes: [Note] = []   // 最初に全部格納する！
    var isSetLaneNotes = false
    let laneIndex: Int!
    var storedFlickJudgeInformation: (timeLag: TimeInterval, touch: UITouch)? {// (判定予定時間(movedが呼ばれた時間), タッチ情報)
        didSet {
            if let newTimeLag = storedFlickJudgeInformation?.timeLag {
                if newTimeLag < 0 {
                    print("storedFlickJudgeの timeLag < 0 は不正です")
                    storedFlickJudgeInformation = nil
                }
            }
        }
    }
    

    /// 判定時間範囲(前miss~後miss)かどうかを返す
    var isJudgeRange: Bool {
        get {
            guard isTimeLagSet else { return false }
            
            switch self.getJudgeTimeState(timeLag: timeLag) {
            case .parfect, .great, .good, .bad, .miss : return true
            default                                   : return false
            }
        }
    }
    
    /// 次の判定ノーツがmiddleで、判定圏内にあり、perfectでなければ、その前後で.beforeか.afterを返す
    /// それ以外の場合は.otherwiseを返す
    var middleObservationTimeState: ObsevationTimeState {
        get {
            guard self.isTimeLagSet,
                  !(laneNotes.isEmpty)       else { return .otherwise }
            guard laneNotes.first is Middle  else { return .otherwise }
            
            switch timeLag {
            case  parfectUpperBorder ..<  missUpperBorder:    return .before
            case -missUpperBorder    ..< -parfectUpperBorder: return .after
            default:                                          return .otherwise
            }
        }
    }
    
    //  次の判定ノーツがフリックで、前半判定圏内にあり、perfectでなければtrue。その他の場合falseを返す
    var isFlickAndBefore: Bool {
        get {
            guard self.isTimeLagSet,
                  !(laneNotes.isEmpty)        else { return false }
            guard laneNotes.first is Flick ||
                  laneNotes.first is FlickEnd else { return false }
            
            return Range(parfectUpperBorder ..< missUpperBorder).contains(timeLag)
        }
    }
    
    var judgeTimeState: JudgeTimeState {    // このインスタンスのtimeLagについてのTimeStateを取得するためのプロパティ
        get{
            guard self.isTimeLagSet else { return .still }
            
            return self.getJudgeTimeState(timeLag: timeLag)
        }
    }
    
    
    
    init(laneIndex: Int){
        self.laneIndex = laneIndex
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ passedTime: TimeInterval, _ BPMs: [(bpm: Double, startPos: Double)]){
        
        // timeLagの更新
        if isSetLaneNotes {
            
            if !(laneNotes.isEmpty) {
                
                timeLag = -passedTime
                
                for (index, BPM) in BPMs.enumerated(){
                    if BPMs.count > index+1 &&
                        laneNotes[0].beat > BPMs[index+1].startPos { // indexが最後でない場合
                        
                        timeLag += (BPMs[index+1].startPos - BPM.startPos) * 60 / BPM.bpm
                        
                    } else {
                        
                        timeLag += (laneNotes[0].beat - BPM.startPos) * 60 / BPM.bpm
                        break
                    }
                }
                
                
            }
            
            self.isTimeLagSet = true    // パース前はtimeLagは更新されないので(このレーンが使われない場合でも)通知する必要あり.
        }
    }
    
    // timeLagに対応する判定を返す
    func getJudgeTimeState(timeLag: TimeInterval) -> JudgeTimeState {
        guard self.isTimeLagSet else {
            print("timeLagが不正です")
            return .still
        }
        
        switch abs(timeLag) {
        case 0                  ..< parfectUpperBorder  : return .parfect
        case parfectUpperBorder ..< greatUpperBorder    : return .great
        case greatUpperBorder   ..< goodUpperBorder     : return .good
        case goodUpperBorder    ..< badUpperBorder      : return .bad
        case badUpperBorder     ..< missUpperBorder     : return .miss
        default                                         : if timeLag > 0 { return .still  }
                                                          else           { return .passed }
        }
    }
}
