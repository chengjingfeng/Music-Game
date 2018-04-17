//
//  Buttons.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import SpriteKit

extension GameScene {
    
    
    
    // タッチ関係(恐らく、同フレーム内でupdate()等の後に呼び出されている)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard !isAutoPlay else { return }
        
        
        judgeQueue.sync {
            
            uiTouchLoop: for uiTouch in touches {  // すべてのタッチに対して処理する（同時押しなどもあるため）
                
                let pos = uiTouch.location(in: self.view?.superview)
                
                // フリック判定したかを示すBoolを加えてallTouchにタッチ情報を付加
                self.allGSTouches.append(GSTouch(touch: uiTouch, isJudgeableFlick: true, isJudgeableFlickEnd: false, storedFlickJudgeLaneIndex: nil))
                
                for lane in self.lanes {
                    guard lane.isTimeLagSet else { continue uiTouchLoop }
                }
                
                
                guard Dimensions.judgeRects[0].YRange.contains(pos.y) else {     // 以下、ボタンの判定圏内にあるtouchのみを処理する(kara用)。judgeRect.YRangeは共通のはずなので、とりあえず先頭のものを使用。
                    continue
                }

                
                // 判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
                var nearbyNotes: [(laneIndex: Int, timelag: TimeInterval, note: Note, distanceXToButton: CGFloat)] = []
                for (index, judgeRect) in Dimensions.judgeRects.enumerated() {
                    
                    if judgeRect.contains(pos) {    // ボタンの範囲
                        
                        if (self.lanes[index].judgeTimeState == .still) ||
                            (self.lanes[index].judgeTimeState == .passed) { continue }
                        
                        if self.lanes[index].isEmpty { continue }
                        
                        let note = self.lanes[index].headNote!
                        let distanceXToButton = abs(pos.x - Dimensions.buttonX[index])
                        
                        if self.lanes[index].middleObservationTimeState == .after {    // middleの判定圏内（後）
                            nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note, distanceXToButton: distanceXToButton))
                            continue
                        }
                        
                        
                        if (note is Tap) || (note is Flick) || (note is TapStart) { // flickが最近なら他を無視（ここでは判定しない）
                            nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: note, distanceXToButton: distanceXToButton))
                            continue
                        }
                    }
                }
                
                if nearbyNotes.isEmpty {
                    self.actionSoundSet.play(type: .kara)
                } else {
                    nearbyNotes.sort { (A, B) -> Bool in
                        if A.timelag == B.timelag { return A.distanceXToButton < B.distanceXToButton }
                        
                        return A.timelag < B.timelag
                    }
                    
                    if (nearbyNotes[0].note is Tap) ||
                       (nearbyNotes[0].note is TapStart) ||
                       (nearbyNotes[0].note is Middle) {
                        
                        if self.judge(lane: self.lanes[nearbyNotes[0].laneIndex], timeLag: nearbyNotes[0].timelag, gsTouch: self.allGSTouches[self.allGSTouches.count-1]) {
//                            self.actionSoundSet.play(type: .tap)
                        } else {
                            print("判定失敗:tap")
                        }
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard !isAutoPlay else { return }
        
        judgeQueue.sync {
            for i in self.lanes {
                guard i.isTimeLagSet else { return }
            }
            
            for uiTouch in touches {
                
                let touchIndex = self.allGSTouches.index(where: { $0.touch == uiTouch } )!
                
                let pos = uiTouch.location(in: self.view?.superview)
                let ppos = uiTouch.previousLocation(in: self.view?.superview)
                
                let moveDistance = sqrt(pow(pos.x - ppos.x, 2) + pow(pos.y - ppos.y, 2))
                
                // 判定対象を選ぶため、押された範囲のレーンから最近ノーツを取得
                var nearbyNotes: [(laneIndex: Int, timelag: TimeInterval, note: Note, distanceXToButton: CGFloat)] = []
                
                // pposループ
                for (index, judgeRect) in Dimensions.judgeRects.enumerated() {
                    
//                    guard Dimensions.judgeYRange.contains(ppos.y) else { break } // このループでは、移動直前の位置がボタンの判定圏内にあるtouchのみを処理する
//                    
                    if judgeRect.contains(ppos) {
                        if !(judgeRect.contains(pos)) { // 移動後にレーンから外れていた場合は、外れる直前にいた時間で判定
                            
                            if self.lanes[index].middleObservationTimeState == .before {
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {
//                                    self.actionSoundSet.play(type: .middle)
                                    break
                                }
                            }
                        }
                        
                        // フリックの判定
                        guard !(self.lanes[index].isEmpty) else { continue }
                        
                        let judgeNote = self.lanes[index].headNote!
                        if moveDistance > 10 && self.lanes[index].judgeTimeState != .still &&
                            self.lanes[index].judgeTimeState != .passed {
                            
                            let gsTouch = self.allGSTouches[touchIndex] // エイリアス
                            
                            if ((judgeNote is Flick) && gsTouch.isJudgeableFlick) ||
                                ((judgeNote is FlickEnd) && gsTouch.isJudgeableFlickEnd) {
                                // ソート開始!
                                let distanceXToButton = abs(ppos.x - Dimensions.buttonX[index])
                                
                                nearbyNotes.append((laneIndex: index, timelag: self.lanes[index].timeLag, note: judgeNote, distanceXToButton: distanceXToButton))
                                continue
                            }
                        }
                    }
                    
                   
                }
                
                if !(nearbyNotes.isEmpty) {
                    
                    nearbyNotes.sort { (A, B) -> Bool in
                        if A.timelag == B.timelag { return A.distanceXToButton < B.distanceXToButton }
                        
                        return A.timelag < B.timelag
                    }
                    if (nearbyNotes[0].note is Flick) || (nearbyNotes[0].note is FlickEnd) {    // nearbyNotesにはFlickかFlickEndしか入ってない。念のため
                        
                        if self.lanes[nearbyNotes[0].laneIndex].isFlickAndBefore {      // judgeするにはまだ早いんだ！！可能性の芽を摘むな！
                            
                            self.lanes[nearbyNotes[0].laneIndex].storedFlickJudgeInformation = (nearbyNotes[0].timelag, uiTouch)  // parfect前までは、後にperfectになるかもしれないので保持
                            self.allGSTouches[touchIndex].storedFlickJudgeLaneIndex = nearbyNotes[0].laneIndex
                            
                        } else if self.judge(lane: self.lanes[nearbyNotes[0].laneIndex], timeLag: nearbyNotes[0].timelag, gsTouch: self.allGSTouches[touchIndex]) {
                            
//                            self.actionSoundSet.play(type: .flick)
                            
                        } else {
                            print("判定失敗: flick")     // 二重判定防止に成功した時とか
                        }
                    }
                }
                
                
                // middleの話。afterで、外から中に入ってきた時は、その時判定する
               for (index, judgeRect) in Dimensions.judgeRects.enumerated() {
                    if !(judgeRect.contains(ppos)) && judgeRect.contains(pos) {
                        
                        if self.lanes[index].middleObservationTimeState == .after {    // 入った先のレーンの最初がmiddleで、それがparfect時刻を過ぎても判定されずに残っている場合
                            if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {
//                                self.actionSoundSet.play(type: .middle)
                                break
                            }
                        }
                    }
                }
                
                // storedFlickについて、指がレーンから外れていた場合、これ以上待っても決してperfectにはならないので、即判定してしまう。
                if let buttonXAndLaneIndex = self.allGSTouches[touchIndex].storedFlickJudgeLaneIndex {
                    if !(Dimensions.judgeRects[buttonXAndLaneIndex].contains(pos)) {
                        
                        storedFlickJudge(lane: lanes[buttonXAndLaneIndex])
                    }
                }
            }
        }
    }
    
    // touchMovedと似てる。TapEndの判定をするかだけが違う
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard !isAutoPlay else { return }

        judgeQueue.sync {
            
            for touch in touches {
                
                var isAllLanesTimeLagSet = true
                for lane in self.lanes {
                    if !(lane.isTimeLagSet) { isAllLanesTimeLagSet = false }
                }
                
                if isAllLanesTimeLagSet {
                    
                    let touchIndex = self.allGSTouches.index(where: { $0.touch == touch } )!
                    
                    let pos = touch.location(in: self.view?.superview)
                    let ppos = touch.previousLocation(in: self.view?.superview)
                    
                    
                    // pposループ
                    for (index, judgeRect) in Dimensions.judgeRects.enumerated() {
                        if  judgeRect.contains(ppos) && !(judgeRect.contains(pos)) { // 移動後にレーンから外れていた場合
                            
                            if self.lanes[index].middleObservationTimeState == .before {
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {
//                                    self.actionSoundSet.play(type: .middle)
                                    
                                    break
                                }
                            }
                            
                        }
                    }
                    
                    
                    // posループ
                    for (index, judgeRect) in Dimensions.judgeRects.enumerated() {
                        
                        if judgeRect.contains(pos) {  // ボタンの範囲
                            if self.lanes[index].middleObservationTimeState == .before { // 早めに指を離した場合
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {
//                                    self.actionSoundSet.play(type: .middle)
                                    break
                                }
                            } else if self.lanes[index].middleObservationTimeState == .after { // 入った先のレーンの最初がmiddleで、それがparfect時刻を過ぎても判定されずに残っている場合
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {
//                                    self.actionSoundSet.play(type: .middle)
                                    break
                                }
                            }
                            
                            if self.lanes[index].isEmpty { continue }
                            let note = self.lanes[index].headNote
                            if note is TapEnd {
                                if self.judge(lane: self.lanes[index], timeLag: self.lanes[index].timeLag, gsTouch: self.allGSTouches[touchIndex]) {    // 離しの判定
                                    
//                                    self.actionSoundSet.play(type: .tap)
                                    break
                                }
                            } else if ((note is Flick    && self.allGSTouches[touchIndex].isJudgeableFlick) ||
                                       (note is FlickEnd && self.allGSTouches[touchIndex].isJudgeableFlickEnd)) &&
                                      self.lanes[index].isJudgeRange  {   // flickなのにflickせずに離したらmiss
                                
                                self.missJudge(lane: self.lanes[index])
                            }
                        }
                    }
                    
                    
                    // storedFlickが残っていないか確認
                    if let laneIndex = self.allGSTouches[touchIndex].storedFlickJudgeLaneIndex {
                        storedFlickJudge(lane: lanes[laneIndex])
                    }
                    
                    self.allGSTouches.remove(at: self.allGSTouches.index(where: { $0.touch == touch } )!)
                } else {    // !(isAllTimeLagSet)
                    self.allGSTouches.remove(at: self.allGSTouches.index(where: { $0.touch == touch } )!)
                }
            }
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("タッチがcancelされました")
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        print("touchesEstimatedPropertiesUpdated")
    }
    
    
    enum NoteType {
        case tap, flick, tapStart, middle, tapEnd, flickEnd
    }
    
    
    
    // 受け取ったLaneの先頭ノーツを判定する。失敗したらfalseを返す。引数でtimeLagを渡すのは（judge呼び出し時ではなく）タッチされた時のものを使用するため。
    ///受け取ったLaneの先頭ノーツを判定する。
    ///
    /// - Parameters:
    ///   - lane: 判定対象のレーン
    ///   - timeLag: 判定したいノーツの正しい時間と実際に叩かれた時間との差。（judge呼び出し時ではなく）タッチされた時のものを使用する。
    ///   - gsTouch: ノーツを叩いたGSTouchインスタンス。GameSceneから解放されていたらnilを入れること。
    /// - Returns: 成否をBoolで返す
    func judge(lane: Lane, timeLag: TimeInterval, gsTouch: GSTouch?) -> Bool {
        
        guard !(lane.isEmpty),
                lane.isJudgeRange else {
                    print("laneが空、あるいは判定時間圏内にノーツがありません. laneIndex: \(lane.laneIndex)")
                    return false
                    
        }
        
        let judgeNote = lane.headNote!
        
        guard judgeNote.isJudgeable else {
            print("判定対象ノーツ.isJudgeableがfalseです. laneIndex: \(lane.laneIndex)")
            return false
        }
        
        
        // 以下は判定が確定しているものとする
        
        // 音を鳴らす
        switch lane.headNote! {
        case is Flick, is FlickEnd          : self.actionSoundSet.play(type: .flick)
        case is Middle                      : self.actionSoundSet.play(type: .middle)
        case is Tap, is TapStart, is TapEnd : self.actionSoundSet.play(type: .tap)
        default                             : print("ノーツの型の見落とし")
        }
        
        // 必要ならgsTouch関係の処理
        switch judgeNote {
        case is Flick, is FlickEnd:
            gsTouch?.isJudgeableFlick = false    // このタッチでのフリック判定を禁止
            gsTouch?.isJudgeableFlickEnd = false
            
            // storedFlickJudgeに関する処理
            gsTouch?.storedFlickJudgeLaneIndex = nil
            lane.storedFlickJudgeInformation = nil
            
        case is Tap:
            gsTouch?.isJudgeableFlick = false
            gsTouch?.isJudgeableFlickEnd = false
            
        case is TapStart, is Middle:
            gsTouch?.isJudgeableFlick = false
            gsTouch?.isJudgeableFlickEnd = true
       
        default: break
            
        }
       
       
        
        
        switch lane.getJudgeTimeState(timeLag: timeLag) {
        case .parfect:
            setJudgeLabelText(text: "parfect!!")
            ResultScene.parfect += 1
            ResultScene.combo += 1
            if ResultScene.combo > ResultScene.maxCombo {
                ResultScene.maxCombo += 1
            }
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .great:
            setJudgeLabelText(text: "great!")
            ResultScene.great += 1
            ResultScene.combo += 1
            if ResultScene.combo > ResultScene.maxCombo {
                ResultScene.maxCombo += 1
            }
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .good:
            setJudgeLabelText(text: "good")
            ResultScene.good += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .bad:
            setJudgeLabelText(text: "bad")
            ResultScene.bad += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        case .miss:
            setJudgeLabelText(text: "miss!")
            ResultScene.miss += 1
            ResultScene.combo = 0
            judgeNote.isJudged = true
            setNextIsJudgeable(judgeNote: judgeNote)
            releaseNote(lane: lane)
            return true
        default:    // still,passedなら判定しない(guardで弾いてるはず。)
            print("judge error. laneIndex: \(lane.laneIndex)")
            return false
        }
        
        
    }
    
    /// parfect終了時(laneからのdelegate)または指が外れた時に呼び出される。
    func storedFlickJudge(lane: Lane) {
        
        guard lane.storedFlickJudgeInformation != nil else { return }
        
       
        if judge(lane: lane, timeLag: lane.storedFlickJudgeInformation!.timeLag,
                 gsTouch: self.allGSTouches.first(where: { $0.touch == lane.storedFlickJudgeInformation!.touch })) { //（laneから呼び出され、すでに指が離れている場合はtouchはnilになる）
            
//            self.actionSoundSet.play(type: .flick)
        } else {
            
            print("storedFlickJudgeに失敗")
        }
    }
    
    /// 受け取ったLaneの先頭ノーツを判定する。失敗したらfalseを返す。middleのperfect専用
    /// laneの先頭がMiddleであるか、それがparfect時間であるかの判定も兼ねている
    func parfectMiddleJudge(lane: Lane, gsTouch: GSTouch) -> Bool {
        
        guard !(lane.isEmpty),
              lane.headNote is Middle,
              lane.headNote!.isJudgeable else { return false }
        
        if lane.judgeTimeState == .parfect {
            if !(judge(lane: lane, timeLag: lane.timeLag, gsTouch: gsTouch)) {
                print("parfectMiddleJugeに失敗")
                return false
            } else {
                return true
            }
        }
        
//        switch lane.judgeTimeState {
//        case .parfect:
//            setJudgeLabelText(text: "parfect!!")
//            ResultScene.parfect += 1
//            ResultScene.combo += 1
//            if ResultScene.combo > ResultScene.maxCombo {
//                ResultScene.maxCombo += 1
//            }
//            lane.headNote!.isJudged = true
//            setNextIsJudgeable(judgeNote: lane.headNote!)
//            releaseNote(lane: lane)
//            return true
//        default:
//            break
//        }
        
        return false
    }
    
    @discardableResult
    func missJudge(lane: Lane) -> Bool {
        guard !(lane.isEmpty), lane.headNote!.isJudgeable else { return false }
        
        setJudgeLabelText(text: "miss!")
        ResultScene.miss += 1
        ResultScene.combo = 0
        lane.headNote!.isJudged = true
        setNextIsJudgeable(judgeNote: lane.headNote!)
        releaseNote(lane: lane)
        return true
    }
    
    func setNextIsJudgeable(judgeNote: Note)  {
        if judgeNote is TapStart {
            let note = judgeNote as! TapStart
            note.next.isJudgeable = true
        } else if judgeNote is Middle {
            let note = judgeNote as! Middle
            note.next.isJudgeable = true
        }
    }
    
    func releaseNote(lane: Lane) {  // ノーツや同時押し線、関連ノードを開放する
        
        if let i = sameLines.index(where: { $0.note1 === lane.headNote! } ) {    //同時押し線を解放
            
            sameLines.remove(at: i)
        } else if let i = sameLines.index(where: { $0.note2 === lane.headNote! } ) { //同時押し線を解放
            
            sameLines.remove(at: i)
        }
        if let note = lane.headNote! as? TapEnd {        //始点から終点まで、連鎖的に参照を削除
            let index = notes.index(where: { $0 === note.start } )
            notes.remove(at: index!)
        } else if let note = lane.headNote! as? FlickEnd {
            let index = notes.index(where: { $0 === note.start } )
            notes.remove(at: index!)
        } else if lane.headNote! is Tap || lane.headNote! is Flick {
            let index = notes.index(where: { $0 === lane.headNote! } )
            notes.remove(at: index!)
        }
        lane.removeHeadNote()                // レーンからの参照を削除
        
    }
}
