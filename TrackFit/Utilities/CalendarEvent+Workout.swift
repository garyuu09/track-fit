//
//  CalendarEvent+Workout.swift
//  TrackFit
//
//  Created by Ryuga on 2024/12/30.
//

import Foundation

extension CalendarEvent {
  /// description(メモ欄) から WorkoutEventData を解析して返す
  var workoutData: WorkoutEventData? {
    guard let desc = description else {
      return nil
    }
    // descを行ごとに分割
    let lines = desc.components(separatedBy: "\n")

    // 一時的に解析結果を入れる辞書
    var info = [String: String]()

    for line in lines {
      // 例: "種目: ベンチプレス" → ["種目", "ベンチプレス"]
      let parts = line.components(separatedBy: ":")
      guard parts.count == 2 else { continue }
      let key = parts[0].trimmingCharacters(in: .whitespaces)
      let value = parts[1].trimmingCharacters(in: .whitespaces)
      info[key] = value
    }

    // 種目, 重量, セット数, 回数を取り出す (無かったらnil)
    guard let exerciseName = info["種目"],
      let weight = info["重量"]  // 例 "60 kg"
    else {
      return nil
    }

    // セット数, 回数 は Intに変換
    guard let setsString = info["セット数"],
      let sets = Int(setsString),
      let repsString = info["回数"],
      let reps = Int(repsString)
    else {
      return nil
    }

    // start/end から iOS の Date を復元する例
    // (start?.dateTime を ISO8601 でデコードして使う など)
    guard let startDT = start?.dateTime,
      let parsedDate = ISO8601DateFormatter().date(from: startDT)
    else {
      return nil
    }

    let workoutEvent = WorkoutEventData(
      exerciseName: exerciseName,
      weight: weight,
      sets: sets,
      reps: reps,
      date: parsedDate
    )
    return workoutEvent
  }
}
