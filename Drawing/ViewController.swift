//
//  ViewController.swift
//  Drawing
//
//  Created by HanYuan on 2024/12/3.
//

import PencilKit
import ReplayKit
import Photos


class ViewController: UIViewController {
    
    
    let canvasView = PKCanvasView()
    var toolPicker = PKToolPicker()
    var screenRecorder: RPScreenRecorder!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCanvasView()
        setToolPicker()
        screenRecorder = RPScreenRecorder.shared()
        
    }
    
    
    func setCanvasView() {
        canvasView.backgroundColor = .white
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.drawingPolicy = .anyInput // 支援手指和 Apple Pencil 繪圖
        view.addSubview(canvasView)
    }
    
    func setToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    
    func startScreenRecording() {
        
        if screenRecorder.isAvailable {
            screenRecorder.startRecording { error in
                if let error = error {
                    print("Error starting screen recording: \(error)")
                } else {
                    print("Screen recording started")
                }
            }
        } else {
            print("Screen recording is not available")
        }
    }
    
    func stopScreenRecording() {
        
        if screenRecorder.isRecording {
            screenRecorder.stopRecording { (previewController, error) in
                if let error = error {
                    print("Error stopping screen recording: \(error)")
                } else {
                    print("Screen recording stopped")
                    if let previewController = previewController {
                        previewController.previewControllerDelegate = self
                        self.present(previewController, animated: true, completion: nil)
                    }
                }
            }
        } else {
            print("No active screen recording to stop.")
        }
    }
    
    func saveCanvasToPhotos() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    let alert = UIAlertController(title: "成功", message: "畫布已保存到相簿。", preferredStyle: .alert)
                    let action = UIAlertAction(title: "確定", style: .default) { _ in
                        self.resetCanvas()
                    }
                    alert.addAction(action)
                    self.present(alert, animated: true)
                } else if let error = error {
                    let alert = UIAlertController(title: "錯誤", message: "無法保存畫布：\(error.localizedDescription)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "確定", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func resetCanvas() {
        canvasView.drawing = PKDrawing()
        setToolPicker()
    }
    
    
    @IBAction func undoButtonTapped(_ sender: UIBarButtonItem) {
        
        if self.undoManager?.canUndo == true {
            self.undoManager?.undo()
        }
    }
    
    @IBAction func saveDrawing(_ sender: UIBarButtonItem) {
        saveCanvasToPhotos()
    }
    
    @IBAction func startRecording(_ sender: UIBarButtonItem) {
        if sender.title == "Start" {
            startScreenRecording()
            sender.title = "Stop"
        } else {
            stopScreenRecording()
            sender.title = "Start"
        }
        
    }
}

extension ViewController: RPPreviewViewControllerDelegate {
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        
        previewController.dismiss(animated: true, completion: nil)
        resetCanvas()
        
    }
}

