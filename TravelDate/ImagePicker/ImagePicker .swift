//
//  ImagePicker .swift
//  Hardwood365
//
//  Created by Dev CodingZone on 22/12/25.
//
import UIKit
import Photos
import AVFoundation

final class ImagePickerManager: NSObject {

    // MARK: - Properties
    private weak var presentingVC: UIViewController?
    private var completion: ((UIImage) -> Void)?

    private let picker = UIImagePickerController()

    // MARK: - Init
    init(presentingVC: UIViewController) {
        self.presentingVC = presentingVC
        super.init()
        picker.delegate = self
        picker.allowsEditing = true
    }

    // MARK: - Public API
    func showImagePicker(
        allowCamera: Bool = true,
        completion: @escaping (UIImage) -> Void
    ) {
        self.completion = completion

        let alert = UIAlertController(
            title: "Select Image",
            message: nil,
            preferredStyle: .actionSheet
        )

        if allowCamera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(
                UIAlertAction(title: "Camera", style: .default) { _ in
                    self.openCamera()
                }
            )
        }

        alert.addAction(
            UIAlertAction(title: "Gallery", style: .default) { _ in
                self.openGallery()
            }
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        presentingVC?.present(alert, animated: true)
    }

    // MARK: - Private
    private func openCamera() {
        checkCameraPermission {
            self.picker.sourceType = .camera
            self.presentingVC?.present(self.picker, animated: true)
        }
    }

    private func openGallery() {
        picker.sourceType = .photoLibrary
        presentingVC?.present(self.picker, animated: true)
    }

    private func checkCameraPermission(granted: @escaping () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            granted()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                DispatchQueue.main.async {
                    if allowed { granted() }
                }
            }
        default:
            self.showPermissionAlert(
                title: "Camera Access Needed",
                message: "Please allow camera access in Settings"
            )
        }
    }

    private func showPermissionAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentingVC?.present(alert, animated: true)
    }
}


extension ImagePickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        if let editedImage = info[.editedImage] as? UIImage {
            completion?(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            completion?(originalImage)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
