//
//  SystemSearchField.swift
//  weather
//
//  A lightweight wrapper around UISearchTextField to get a native search field
//  without relying on NavigationStack/.searchable.
//

import SwiftUI
import UIKit

struct SystemSearchField: UIViewRepresentable {
    final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: SystemSearchField
        var lastResignToken: UUID?

        init(parent: SystemSearchField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChanged?(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChanged?(false)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onSubmit?()
            textField.resignFirstResponder()
            return true
        }
    }

    let placeholder: String
    @Binding var text: String
    let resignToken: UUID
    var onFocusChanged: ((Bool) -> Void)?
    var onSubmit: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UISearchTextField {
        let field = UISearchTextField(frame: .zero)
        field.placeholder = placeholder
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.returnKeyType = .search
        field.clearButtonMode = .whileEditing
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UISearchTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        // When resignToken changes, we resign first responder to "close" search.
        if context.coordinator.lastResignToken != resignToken {
            context.coordinator.lastResignToken = resignToken
            uiView.resignFirstResponder()
        }
    }
}
