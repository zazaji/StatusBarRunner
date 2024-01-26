//
//  RunnersViewModel.swift
//  StatusBarRunner
//
//  Created by ou on 12/21/23.
//

import SwiftUI

struct ProcessesView: View {
    @ObservedObject var viewModel: RunnersViewModel
    @State private var isEditing = false
    @State private var showingSettings = false
    @State private var showingPreferences = false

    @State private var currentEditItem: RunnerItem?
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("StatusBarRunner").font(.system(size: 16)) .padding(.leading, 15)
                    Spacer()
                    HStack {
                        Button(action: {
                            self.showingPreferences = true
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue) // Set the color to blue

                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("statusBarRunner")
                            let url = URL(fileURLWithPath: path.path)
                            
                            NSWorkspace.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue) // Set the color to blue

                            }
                            .padding(.vertical, 5)
                        }.buttonStyle(PlainButtonStyle())
                        
                    }.padding(.trailing, 10)
                }
                .frame(maxWidth: .infinity)
                List{
                    ForEach($viewModel.items) { $item in

                        HStack {
                            
                            Toggle(isOn: $item.isLoginToRun) {}

                            Text(item.name)
                            
                            Spacer()
                            
//                            Toggle(isOn: $item.isRunning) {}
                            Toggle(isOn: Binding(
                                get: { item.isRunning },
                                set: { _ in viewModel.toggleRunner(item: item) }
                            )) {}
                            .toggleStyle(SwitchToggleStyle())

                        }
                        .onTapGesture(count: 1) {
                            self.showingSettings = true
                            self.currentEditItem = item
                            self.isEditing = true
                        }
                    }
                    .onDelete(perform: viewModel.deleteItem)
                    .onMove(perform: viewModel.moveItem)
                    

                }
                
                HStack {
                    Button("Add") {
                        isEditing = false
                        showingSettings = true
                    }
                    
                    Button("save") {
                        viewModel.saveItems()
                    }
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(.vertical, 5)

            }
            .sheet(isPresented: $showingPreferences) {
                PreferencesView(isPresented:$showingPreferences)
            }
            .sheet(isPresented: $showingSettings ) {
                if let currentItem = currentEditItem , isEditing == true {
                    SettingsView(items: $viewModel.items,id:currentItem.id,
                                 newName:currentItem.name,newCmd:currentItem.cmd,
                                 isPresented: $showingSettings,isEditing:true,
                                 editingItem: currentItem)
                }else{

                    SettingsView(items: $viewModel.items,id:UUID(),newName:"",newCmd:"",
                                 isPresented: $showingSettings,isEditing:false,
                                 editingItem: viewModel.items[0])
                }
            }
        }
    }

}
