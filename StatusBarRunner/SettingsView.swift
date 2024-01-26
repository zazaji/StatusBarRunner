//
//  RunnersViewModel.swift
//  StatusBarRunner
//
//  Created by ou on 12/21/23.
//
import SwiftUI


struct SettingsView: View {
    @Binding var items: [RunnerItem]
    @State var id : UUID
    @State var newName: String
    @State var newCmd: String
    @Binding var isPresented: Bool
    @State var isEditing: Bool
    var editingItem: RunnerItem? // Optional property to hold the item being edited

    var body: some View {
        VStack {
            HStack {
                if isEditing {
                    Text("Modify")
                } else {
                    Text("Add a cmdline runner")
                }
            }
            HStack {
                TextField("cmdline Name", text: $newName).frame(width:400).padding(.horizontal, 10)
            }
            HStack {
                TextField("cmdline Command", text: $newCmd).frame(width:400).padding(.horizontal, 10)
                
            }
            HStack {
                if isEditing {
                    Button("Apply") {
                        updateItem()
                        isPresented = false  // 关闭视图
                    }
                } else {
                    Button("Add") {
                        addItem()
                        isPresented = false  // 关闭视图
                    }
                }
                
            }
            .padding(.vertical, 10)

        }
    }


    func addItem() {
        let newItem = RunnerItem(name: newName, cmd: newCmd,isRunning: false, isLoginToRun: false,processID:0)
        items.append(newItem)
        newName = ""
        newCmd = ""
    }
    func updateItem() {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].name = newName
            items[index].cmd = newCmd
        }
    }
}
