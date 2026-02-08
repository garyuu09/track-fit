//
//  DatePickerSheet.swift
//  TrackFit
//
//  Extracted from WorkoutSheetView.swift
//

import SwiftUI

/// 日時選択用のシート
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var date: Date

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(title, selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                Spacer()
            }
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(
                trailing: Button("閉じる") {
                    dismiss()
                })
        }
    }
}
