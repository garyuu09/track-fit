import SwiftUI

// MARK: - 個別のトレーニング記録モデル
struct WorkoutRecord: Identifiable {
    let id = UUID()
    var exerciseName: String
    var weight: Double
    var reps: Int
    var sets: Int
}

// MARK: - 1日分のトレーニング記録
struct DailyWorkout: Identifiable {
    let id = UUID()
    let date: Date

    // その日実施したトレーニング一覧
    var records: [WorkoutRecord]

    // Googleカレンダー連携済みかどうか
    var isSyncedToCalendar: Bool = false
}

// MARK: - メインビュー
struct WorkoutRecordView: View {
    @State private var dailyWorkouts: [DailyWorkout] = [
        DailyWorkout(
            date: dateFromString("2024/12/31"),
            records: [
                WorkoutRecord(exerciseName: "ベンチプレス", weight: 50.0, reps: 10, sets: 3),
                WorkoutRecord(exerciseName: "スクワット",   weight: 70.0, reps: 8,  sets: 3),
                WorkoutRecord(exerciseName: "デッドリフト", weight: 80.0, reps: 5,  sets: 2)
            ]
        ),
        DailyWorkout(
            date: dateFromString("2025/01/01"),
            records: [
                WorkoutRecord(exerciseName: "プルアップ",        weight: 0.0,  reps: 10, sets: 3),
                WorkoutRecord(exerciseName: "ショルダープレス", weight: 30.0, reps: 8,  sets: 3)
            ]
        )
    ]

    /// アコーディオンが展開されている日付(DailyWorkout)の id を管理
    @State private var expandedDailyIDs: Set<UUID> = []

    @State private var searchText: String = ""

    // シートの表示・非表示を管理するフラグ
    @State private var showDatePickerSheet = false

    @State var showDatePicker: Bool = false
    @State var savedDate: Date? = nil

    // 選択した日付
    @State private var selectedDate = Date()

    var body: some View {
        ZStack {
            NavigationStack {
                TopView() // 何かの上部ビュー(サンプル)
                    .frame(width: 300)

                List {
                    ForEach($dailyWorkouts) { $daily in
                        VStack(alignment: .leading, spacing: 8) {
                            // 上段: 三角アイコン + 日付 + Googleカレンダー反映ボタン
                            HStack {
                                NavigationLink {
                                    // 遷移先 (WorkoutSheetView) にバインディングでDailyWorkoutを渡す
                                    WorkoutSheetView(daily: $daily)
                                } label: {
                                    // 展開状態でアイコンを切り替え(▼ or ▶)
                                    let isExpanded = expandedDailyIDs.contains(daily.id)
                                    Image(systemName: isExpanded ? "triangle.fill" : "triangle")
                                        .rotationEffect(Angle(degrees: isExpanded ? 0 : 90))
                                        .foregroundColor(.gray)

                                    // 日付テキスト
                                    Text(formattedDate(date: daily.date))
                                        .font(.headline)
                                        .onTapGesture {
                                            withAnimation {
                                                toggleExpanded(daily.id)
                                            }
                                        }

                                    Spacer()

                                    // Googleカレンダー連携ボタン
                                    Button(action: {
                                        daily.isSyncedToCalendar.toggle()
                                    }) {
                                        if daily.isSyncedToCalendar {
                                            // 連携済み
                                            Label("連携済み", systemImage: "calendar.badge.checkmark")
                                                .font(.footnote)
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.green, lineWidth: 1)
                                                )
                                        } else {
                                            // 未連携
                                            Label("連携", systemImage: "calendar.badge.plus")
                                                .font(.footnote)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.blue, lineWidth: 1)
                                                )
                                        }
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            // 折り畳み領域: 日付が展開されている場合だけ表示
                            if expandedDailyIDs.contains(daily.id) {
                                Divider()

                                // Grid全体で左寄せ
                                Grid(alignment: .leading) {
                                    // レコードごとに行を作成
                                    ForEach(daily.records) { record in
                                        GridRow {
                                            Text(record.exerciseName)
                                            Text("\(Int(record.weight))kg")
                                            Text("x")
                                            Text("\(record.reps)回")
                                            Text("x")
                                            Text("\(record.sets)セット")
                                        }
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // 新規の日付を追加する例
                            let newDaily = DailyWorkout(date: Date(), records: [])
                            dailyWorkouts.append(newDaily)
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                .navigationTitle("トレーニング一覧")
                .navigationBarTitleDisplayMode(.inline)
                // 丸い追加ボタン（下部固定）
                .safeAreaInset(edge: .bottom, alignment: .center) {
                    Button(action: {
                        // シートを表示させる
                        showDatePicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text("トレーニング日を追加")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2),
                                radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .zIndex(1)
                }
                // シートを表示するためのモディファイア
                .sheet(isPresented: $showDatePickerSheet) {
                    // シートの中身
                    VStack(spacing: 20) {
                        Text("トレーニング日を選択してください")
                            .font(.headline)

                        // 日付の選択を行うDatePicker
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        Button("完了") {
                            // シートを閉じる
                            showDatePickerSheet = false
                        }
                    }
                    .presentationDetents([
                      .height(300),
                      .fraction(0.3)
                    ])
                    .padding()
                }
            }
            if showDatePicker {
                CustomDatePicker(
                    showDatePicker: $showDatePicker,
                    savedDate: $savedDate,
                    dailyWorkouts: $dailyWorkouts,
                    selectedDate: savedDate ?? Date()
                )
                .animation(.linear, value: savedDate)
                .transition(.opacity)
            }
        }
    }

    // 折り畳み/展開をトグルするヘルパーメソッド
    private func toggleExpanded(_ id: UUID) {
        if expandedDailyIDs.contains(id) {
            expandedDailyIDs.remove(id)
        } else {
            expandedDailyIDs.insert(id)
        }
    }

    /// Date を "yyyy/MM/dd" 形式の文字列に変換する関数
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian) // 西暦を使う
        formatter.locale = Locale(identifier: "ja_JP")        // 日本語ロケール
        formatter.dateFormat = "yyyy/MM/dd"                   // 表示形式
        return formatter.string(from: date)
    }
}

// MARK: - トレーニング1件分のカード表示
struct CardView: View {
    let record: WorkoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.exerciseName)
                .font(.headline)

            HStack {
                Text("\(Int(record.weight)) kg")
                Spacer()
                Text("\(record.reps) 回")
            }
            .font(.subheadline)

            Text("セット数: \(record.sets)")
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

// MARK: - トレーニング管理画面 (NavigationStackでプッシュ遷移先)
struct WorkoutSheetView: View {
    // 親画面から受け取ったDailyWorkoutをバインディングで持つ
    // これにより直接編集が可能で、戻った時に反映される
    @Binding var daily: DailyWorkout

    @State private var editingRecord: WorkoutRecord? = nil

    // 2カラムのレイアウトでカード表示
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // ForEachに直接$daily.records.indicesを渡すと、バインドしやすい
                ForEach($daily.records.indices, id: \.self) { index in
                    let record = daily.records[index]
                    CardView(record: record)
                        .onTapGesture {
                            editingRecord = record
                        }
                }
            }
            .padding()
        }
        // 新規トレーニングを追加ボタン
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let newRecord = WorkoutRecord(exerciseName: "新種目", weight: 10, reps: 10, sets: 3)
                    daily.records.append(newRecord)
                } label: {
                    Label("追加", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("トレーニング管理")
        .navigationBarTitleDisplayMode(.inline)
        // 編集用のシート（簡易実装）
        .sheet(item: $editingRecord) { rec in
            EditWorkoutSheetView(
                record: rec,
                onSave: { updatedRec in
                    // daily.records内の要素を更新
                    if let idx = daily.records.firstIndex(where: { $0.id == updatedRec.id }) {
                        daily.records[idx] = updatedRec
                    }
                    editingRecord = nil
                },
                onDelete: {
                    if let idx = daily.records.firstIndex(where: { $0.id == rec.id }) {
                        daily.records.remove(at: idx)
                    }
                    editingRecord = nil
                }
            )
        }
    }
}

// MARK: - トレーニング編集用シート(簡易的)
struct EditWorkoutSheetView: View {
    @State var record: WorkoutRecord

    var onSave: (WorkoutRecord) -> Void
    var onDelete: () -> Void

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("種目名")) {
                    TextField("種目名", text: $record.exerciseName)
                }
                Section(header: Text("重量(kg)")) {
                    TextField("重量", value: $record.weight, format: .number)
                        .keyboardType(.decimalPad)
                }
                Section(header: Text("回数")) {
                    TextField("回数", value: $record.reps, format: .number)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("セット数")) {
                    TextField("セット数", value: $record.sets, format: .number)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("このトレーニングを削除")
                    }
                }
            }
            .navigationTitle("編集")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("キャンセル") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    onSave(record)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct CustomDatePicker: View {
    @Binding var showDatePicker: Bool
    @Binding var savedDate: Date?
    @Binding var dailyWorkouts: [DailyWorkout]
    @State var selectedDate: Date = Date()

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showDatePicker = false
                }
            VStack {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .datePickerStyle(.graphical)
                Divider()
                HStack {
                    Button("キャンセル") {
                        showDatePicker = false
                    }
                    Spacer()
                    Button("保存") {
                        savedDate = selectedDate
                        guard let savedDate else { return }
                        showDatePicker = false
                        // 新規の日付を追加するなどの処理 (例)
                        let newDaily = DailyWorkout(date: savedDate, records: [])
                        dailyWorkouts.append(newDaily)
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 10)
            }
            .padding(.horizontal, 20)
            .background(
                Color.gray
                    .cornerRadius(30)
            )
            .padding(.horizontal, 20)
        }
    }
}


// MARK: - ヘルパー
fileprivate func dateFromString(_ string: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.date(from: string) ?? Date()
}

// MARK: - プレビュー
#Preview {
    WorkoutRecordView()
}
