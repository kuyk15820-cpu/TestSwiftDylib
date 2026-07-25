import UIKit
import UniformTypeIdentifiers

class MainViewController: UIViewController, UIDocumentPickerDelegate {

    private let injectButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Dylib Tester"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    private func setupUI() {
        // Configure Status Label
        statusLabel.text = "พร้อมสำหรับการทดสอบ .dylib"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Configure Inject Button
        injectButton.setTitle("เลือกไฟล์ .dylib เพื่อทดสอบ", for: .normal)
        injectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        injectButton.backgroundColor = .systemBlue
        injectButton.setTitleColor(.white, for: .normal)
        injectButton.layer.cornerRadius = 12
        injectButton.addTarget(self, action: #selector(selectDylibTapped), for: .touchUpInside)
        injectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(injectButton)

        // Layout Constraints
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: injectButton.topAnchor, constant: -20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            injectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            injectButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            injectButton.widthAnchor.constraint(equalToConstant: 250),
            injectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Action: Open Document Picker
    @objc private func selectDylibTapped() {
        let dylibType = UTType(filenameExtension: "dylib") ?? .data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [dylibType], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        // คัดลอกไฟล์มาไว้ใน Documents ของแอปก่อนสั่ง dlopen
        if let localDylibURL = copyToDocuments(sourceURL: selectedURL) {
            injectDylib(at: localDylibURL.path)
        }
    }

    // MARK: - Helper: Copy to Documents Directory
    private func copyToDocuments(sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let destinationURL = docsURL.appendingPathComponent(sourceURL.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            showAlertDialog(message: "คัดลอกไฟล์ไม่สำเร็จ: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Core Logic: dlopen Execution
    private func injectDylib(at path: String) {
        // เรียกใช้ C API: dlopen
        let handle = dlopen(path, RTLD_NOW)
        
        if handle == nil {
            if let error = dlerror() {
                let errorStr = String(cString: error)
                statusLabel.textColor = .systemRed
                statusLabel.text = "[-] โหลด Dylib ล้มเหลว:\n\(errorStr)"
                showAlertDialog(message: "Error: \(errorStr)")
            }
        } else {
            statusLabel.textColor = .systemGreen
            statusLabel.text = "[+] โหลด Dylib เข้า Memory สำเร็จ!\nPath: \(path)"
            showAlertDialog(message: "โหลด .dylib สำเร็จแล้ว!")
            
            // หมายเหตุ: หาก dylib มี Constructor (เช่น __attribute__((constructor))) 
            // โค้ดใน dylib จะทำงานอัตโนมัติทันทีที่ dlopen สำเร็จ
        }
    }

    // MARK: - Alert Helper
    private func showAlertDialog(message: String) {
        let alert = UIAlertController(title: "แจ้งเตือน", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ตกลง", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
