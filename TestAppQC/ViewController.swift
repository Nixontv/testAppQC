//
//  ViewController.swift
//  VoiceRecognitionTest
//
//  Created by Nikita Velichko on 16/08/2019.
//  Copyright © 2019 Nikita Velichko. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    let synth = AVSpeechSynthesizer()
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    var request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
    
    let someText = "Hello my name is Nick "
//    "And when Nick came could never find tiny friends."
    var isFinal = false
    var isFinish = false
    var someTextArray: [String] = []
    var someTextArray2: [String] = []
    var someTextArray3: [String] = []

    
    @IBOutlet weak var speechLabel: UILabel!
    @IBOutlet weak var recognizedLabel: UILabel!
    @IBOutlet weak var recognizeButton: UIButton!
    @IBOutlet weak var speechButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechLabel.text = someText
        someTextArray = someText.byWords
        print(someTextArray)
    }
    
    func recordAndRecognizeSpeech(){
         mostRecentlyProcessedSegmentDuration = 0
         let node = audioEngine.inputNode
         let recordingFormat = node.outputFormat(forBus: 0)
         node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { ( buffer, _) in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do{
            try audioEngine.start()
        }catch{
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {return}
            
        if !myRecognizer.isAvailable {return}
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            [unowned self]
            (result, _) in
            if let transcription = result?.bestTranscription {
                self.updateUIWithTranscription(transcription)
            }
        }
    }
    
    func updateUIWithTranscription(_ transcription: SFTranscription) {
        recognizedLabel.text = transcription.formattedString
        isFinal = false
        
        if let lastSegment = transcription.segments.last,
            lastSegment.duration >= mostRecentlyProcessedSegmentDuration {
            mostRecentlyProcessedSegmentDuration = lastSegment.duration
           
            someTextArray2.append(lastSegment.substring)
         
            if someTextArray2.last == someTextArray2.penultimate(){
                
                someTextArray2.removeLast()
            
            }else{
                someTextArray3 = someTextArray2
                print(someTextArray3)
                
                if someTextArray.count == 0 {
                    isFinish = true
                    
                    if isFinish == true{
                        self.audioEngine.stop()
                        request.endAudio()
                        audioEngine.inputNode.removeTap(onBus: 0)
                        recognizeButton.setTitle("Restart", for: .normal)
                        someTextArray = someText.byWords
                        someTextArray3 = []
                    }
                }else{
                    
                if someTextArray[0].lowercased() == someTextArray3.last?.lowercased(){
                    
                    speechLabel.colorString(text: speechLabel.text, coloredText: someTextArray[0], color: .green)
                    someTextArray.removeFirst()
                    
                }else{
                    speechLabel.colorString(text: speechLabel.text, coloredText: someTextArray[0], color: .red)
                    
                    isFinal = true
                    
                    if isFinal == true {
                        self.audioEngine.stop()
                        request.endAudio()
                        audioEngine.inputNode.removeTap(onBus: 0)
                        recognizeButton.setTitle("Try Again!", for: .normal)
                        
                        }
                   
                    
                    }
                
                }
            }
        
        }
       
    }
    
    
    @IBAction func runSpeechButton(_ sender: Any) {
        let utterance = AVSpeechUtterance(string: speechLabel.text ?? "No Text")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        if synth.isSpeaking == true{
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
            speechButton.setTitle("Run Spearking", for: .normal)
        }else{
        synth.speak(utterance)
            speechButton.setTitle("Stop Spearking", for: .normal)
        }
    }
    
    
    @IBAction func tryButton(_ sender: Any) {
        
        if audioEngine.isRunning {

            audioEngine.stop()
            request.endAudio()
            //recognizeButton.isEnabled = false
            audioEngine.inputNode.removeTap(onBus: 0)
            recognizeButton.setTitle("Try", for: .normal)

        } else {
        
        recordAndRecognizeSpeech()
        recognizeButton.setTitle("Stop", for: .normal)
            
//        }
    }
}
}

extension UILabel {
    
    func colorString(text: String?, coloredText: String?, color: UIColor?) {
        
        let attributedString = NSMutableAttributedString(string: text!)
        let range = (text! as NSString).range(of: coloredText!)
        attributedString.setAttributes([NSAttributedString.Key.foregroundColor: color!],
                                       range: range)
        self.attributedText = attributedString
    }
    
}

import Foundation


extension String {
    var byWords: [String] {
        var byWords:[String] = []
        enumerateSubstrings(in: startIndex..<endIndex, options: .byWords) {
            guard let word = $0 else { return }
            print($1,$2,$3)
            byWords.append(word)
        }
        return byWords
    }
    func firstWords(_ max: Int) -> [String] {
        return Array(byWords.prefix(max))
    }
    var firstWord: String {
        return byWords.first ?? ""
    }
    func lastWords(_ max: Int) -> [String] {
        return Array(byWords.suffix(max))
    }
    var lastWord: String {
        return byWords.last ?? ""
    }
}
extension Array {
    func penultimate() -> Element? {
        if self.count < 2 {
            return nil
        }
        let index = self.count - 2
        return self[index]
    }
}

extension StringProtocol { // for Swift 4 you need to add the constrain `where Index == String.Index`
    var byWords: [SubSequence] {
        var byWords: [SubSequence] = []
        enumerateSubstrings(in: startIndex..., options: .byWords) { _, range, _, _ in
            byWords.append(self[range])
        }
        return byWords
    }
}
