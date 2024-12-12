
import PencilKit
import ReplayKit
import Photos

class ViewController: UIViewController {
    
    let canvasView = PKCanvasView()
    var toolPicker = PKToolPicker()
    var screenRecorder: RPScreenRecorder!
    var cameraPreviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraPreviewView()
        setCanvasView()
        setToolPicker()
        screenRecorder = RPScreenRecorder.shared()
    }
    
    func setupCameraPreviewView() {
        // 初始化相機預覽
        cameraPreviewView = UIView()
        cameraPreviewView.frame = view.bounds // 全螢幕顯示相機預覽
        cameraPreviewView.backgroundColor = .clear
        view.addSubview(cameraPreviewView) // 相機預覽作為底層背景
    }
    
    //        cameraPreviewView.frame = CGRect(x: 20, y: 50, width: 120, height: 160) // 前鏡頭預覽的大小和位置
    //        cameraPreviewView.backgroundColor = .black
    //        cameraPreviewView.layer.cornerRadius = 10
    //        cameraPreviewView.layer.masksToBounds = true
    
    func setCanvasView() {
        // 初始化畫布，覆蓋在相機預覽上
        canvasView.backgroundColor = .clear // 背景透明
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.drawingPolicy = .anyInput // 支援手指和 Apple Pencil 繪圖
        view.addSubview(canvasView) // 添加畫布
    }
    
    func setToolPicker() {
        // 設定工具選擇器
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }
    
    func startScreenRecording() {
        if screenRecorder.isAvailable {
            screenRecorder.isMicrophoneEnabled = true
            screenRecorder.isCameraEnabled = true
            screenRecorder.startRecording { error in
                if let error = error {
                    print("Error starting screen recording: \(error)")
                } else {
                    print("Screen recording started")
                    self.startCameraPreview()
                }
            }
        } else {
            print("Screen recording is not available")
        }
    }
    
    func stopScreenRecording() {
        if screenRecorder.isRecording {
            screenRecorder.stopRecording { (previewController, error) in
                self.stopCameraPreview()
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
    
    func startCameraPreview() {
        guard let cameraLayer = screenRecorder.cameraPreviewView else {
            print("Camera preview view not available")
            return
        }
        cameraLayer.frame = cameraPreviewView.bounds
        cameraPreviewView.addSubview(cameraLayer)
        cameraPreviewView.isHidden = false
    }
    
    func stopCameraPreview() {
        cameraPreviewView.isHidden = true
        cameraPreviewView.subviews.forEach { $0.removeFromSuperview() }
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
    
    // 支援旋轉
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: { _ in
                self.updateLayoutForOrientation(size: size)
            })
        }
        
        func updateLayoutForOrientation(size: CGSize) {
            // 更新相機和畫布的框架
            cameraPreviewView.frame = CGRect(origin: .zero, size: size)
            canvasView.frame = CGRect(origin: .zero, size: size)
        }
}

extension ViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
        resetCanvas()
    }
}
