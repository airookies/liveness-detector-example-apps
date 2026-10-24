import PhotosUI
import SwiftUI

/// Picks one photo from the library and returns it as a JPEG of at most 1280 px.
/// (SwiftUI's PhotosPicker needs iOS 16; the SDK supports iOS 15.)
struct PhotoPicker: UIViewControllerRepresentable {
  let onPick: (Data) -> Void

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.filter = .images
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

  final class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let onPick: (Data) -> Void
    init(onPick: @escaping (Data) -> Void) { self.onPick = onPick }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true)
      results.first?.itemProvider.loadObject(ofClass: UIImage.self) { [onPick] object, _ in
        guard let image = object as? UIImage else { return }
        let scale = min(1, 1280 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let jpeg = UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.9) { _ in
          image.draw(in: CGRect(origin: .zero, size: size))
        }
        DispatchQueue.main.async { onPick(jpeg) }
      }
    }
  }
}
