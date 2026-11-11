import SwiftUI
import MessageUI

/// 애플 메일 작성 화면을 앱 위에 모달로 띄우는 래퍼 (`MFMailComposeViewController`)
///
///     .sheet(isPresented: $showsMail) {
///         MailComposeView(recipient: "…", subject: "…", body: "…")
///     }
///
/// - 기기에 메일 계정이 없으면 `canSendMail`이 false라서 띄울 수 없어요. 부르는 쪽에서 `MailComposeView.canSend`로 먼저 확인하고,
///   안 되면 `mailto:` 링크 등으로 대신해요.
/// - 보내기 · 취소 · 임시 저장 어느 쪽이든 작성 화면은 알아서 닫혀요.
struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    var subject: String = ""
    var body: String = ""

    /// 이 기기에서 애플 메일 작성 화면을 띄울 수 있는지
    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: { dismiss() }) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            dismiss()
        }
    }
}
