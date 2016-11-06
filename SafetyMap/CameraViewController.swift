//
//  CameraViewController.swift
//  SafetyMap
//
//  Created by Yanbo Fang on 10/30/16.
//  Copyright © 2016 Yanbo Fang. All rights reserved.
//

import UIKit
import AVFoundation
import AWSS3


class CameraViewController: UIViewController,  AVAudioRecorderDelegate {
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    @IBOutlet weak var recordButton: UIButton!
    var audioFileName: URL? = nil
    
    func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 128, height: 64))
        recordButton.setTitle("I'm SAFE!", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    func upload(outputFileURL: NSURL!) {
        
        let transferManager:AWSS3TransferManager = AWSS3TransferManager.default()
        
        let request = AWSS3TransferManagerUploadRequest()
        request?.bucket = "safetymapdata"
        request?.body = outputFileURL as URL!
        request?.storageClass = AWSS3StorageClass.reducedRedundancy
        request?.uploadProgress = ({
            (bytesSent: Int64, totalBytesSent: Int64,  totalBytesExpectedToSend: Int64) in
        })
        
        transferManager.upload(request).continue({ (task: AWSTask) -> AnyObject! in
            return nil
        })
    }

    func startRecording() {
        audioFileName = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName!, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordButton.setTitle("Recording", for: .normal)
        } catch {
            finishRecording(success: false)
        }
        finishRecording(success: true)

    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            upload(outputFileURL: audioFileName as NSURL!)
        } else {
            // recording failed :(
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        recordButton.backgroundColor = UIColor(red:0.96, green:0.41, blue:0.57, alpha:1.0)
        
        // Do any additional setup after loading the view.
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
            }
        } catch {
            // failed to record!
        }
        
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
        
    }
    
    func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
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
