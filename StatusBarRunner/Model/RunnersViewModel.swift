//
//  RunnersViewModel.swift
//  StatusBarRunner
//
//  Created by ou on 12/21/23.
//
import Foundation

class RunnerItem: Identifiable, Codable,ObservableObject {
    @Published  var id : UUID
    @Published  var name: String
    @Published  var cmd: String
    @Published  var isRunning: Bool
    @Published  var isLoginToRun: Bool
    @Published  var processID:Int32?

    enum CodingKeys: String, CodingKey {
        case id, name, cmd,isRunning,isLoginToRun,processID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        cmd = try container.decode(String.self, forKey: .cmd)
        isRunning = try container.decode(Bool.self, forKey: .isRunning)
        isLoginToRun = try container.decode(Bool.self, forKey: .isLoginToRun)
        processID = try container.decode(Int32.self, forKey: .processID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(cmd, forKey: .cmd)
        try container.encode(isRunning, forKey: .isRunning)
        try container.encode(isLoginToRun, forKey: .isLoginToRun)
        try container.encodeIfPresent(processID, forKey: .processID)
    }
    
    init(id: UUID = UUID(), name: String, cmd: String, isRunning: Bool,isLoginToRun:Bool,processID:Int32 ) {
        self.id = id
        self.name = name
        self.cmd = cmd
        self.isRunning = isRunning
        self.isLoginToRun = isLoginToRun
        self.processID = processID
    }
}

struct RunnerData: Codable {
    var data: [RunnerItem]
}

class RunnersViewModel: ObservableObject {
    @Published var items: [RunnerItem] = []

    init() {
        initFolder()
        loadItems()
    }
    
    func checkStatusAndUpdate() {
        objectWillChange.send()
        for index in items.indices {
            if let pid = items[index].processID, pid > 0 {
                items[index].isRunning = isProcessRunning(pid: pid)
            } else {
                items[index].isRunning = false
            }
        }
    }

    func initFolder(){
        let fileManager = FileManager.default
        guard let homeDirectory = fileManager.homeDirectoryForCurrentUser.path as String? else { return }
        let logDirectory = "\(homeDirectory)/statusBarRunner"
        
        // 创建日志目录，如果不存在
        if !fileManager.fileExists(atPath: logDirectory) {
            do {
                try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating log directory: \(error)")
            }
        }
        
    }
        
        
        
    func loadItems() {
        let fileManager = FileManager.default
        guard let homeDirectory = fileManager.homeDirectoryForCurrentUser.path as String? else { return }
        let filePath = "\(homeDirectory)/.statusRunner.json"

        if !fileManager.fileExists(atPath: filePath) {
            do {
                let jsonObject: [String: Any] = [:]
                let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
                try jsonData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            } catch {
                print("Error creating JSON file: \(error)")
                return
            }
        }
        guard let data = fileManager.contents(atPath: filePath) else { return }
        
        
        do {
            let decodedData = try JSONDecoder().decode(RunnerData.self, from: data)
            for index in decodedData.data.indices {
                let pid = decodedData.data[index].processID ?? 0
                decodedData.data[index].processID = pid
                decodedData.data[index].isRunning = isProcessRunning(pid: pid)
                
                if decodedData.data[index].isLoginToRun == true {
                    print("start",decodedData.data[index].name,decodedData.data[index].cmd)
                    let pid = executeCommand(name:decodedData.data[index].name, cmd:decodedData.data[index].cmd)
                    decodedData.data[index].processID = pid
                    decodedData.data[index].isRunning = isProcessRunning(pid: pid)
                }
            }
            items = decodedData.data
            print( items[8])
            
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
       items.remove(atOffsets: offsets)
        saveItems()
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
       items.move(fromOffsets: source, toOffset: destination)
        saveItems()
    }

    func saveItems() {
        do {
            let fileManager = FileManager.default
            guard let homeDirectory = fileManager.homeDirectoryForCurrentUser.path as String? else { return }

            let dataToSave = ["data": items]
            let jsonData = try JSONEncoder().encode(dataToSave)

            let filePath = "\(homeDirectory)/.statusRunner.json"
            try jsonData.write(to: URL(fileURLWithPath: filePath))
        } catch {
            print("Error saving items: \(error)")
        }

    }
    func toggleRunner(item: RunnerItem) {
        if item.isRunning {
            if let pid = item.processID {
                terminateProcess(pid: pid)
                item.processID = 0
            }
        } else {
            // 启动新进程
            let pid = executeCommand(name: item.name,cmd: item.cmd)
            item.processID = pid
        }
        item.isRunning.toggle()
        saveItems()
    }
    
    func setLoginToRun(item: RunnerItem, isOn: Bool) {
        item.isLoginToRun.toggle()
//        item.isLoginToRun=isOn
        saveItems()
    }

    

    func executeCommand(name: String,cmd: String) -> Int32 {
        let task = Process()
        let defaultShell = getDefaultShell()

        var fullCommand: String

        if defaultShell.contains("zsh") {
            // 如果是 zsh，使用 zsh 的配置文件
            task.launchPath = "/bin/zsh"
            fullCommand = "source ~/.zshrc; " + cmd
        } else {
            // 默认使用 bash 的配置文件
            task.launchPath = "/bin/bash"
            fullCommand = "source ~/.bash_profile; " + cmd
        }
        print(fullCommand)
        task.arguments = ["-c", fullCommand]
        
        
        // 创建管道
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        // 在一个单独的线程或进程中，从管道中读取输出并将其写入到日志文件中
        DispatchQueue.global(qos: .background).async {
            // 从管道中读取输出
            print("data")
            let output = pipe.fileHandleForReading.readDataToEndOfFile()
            
            // 将输出写入到日志文件中
            let logFile = self.createLogFile(name: name)
                do {
                    try output.write(to: URL(fileURLWithPath: logFile), options: .atomic)
                } catch {
                    print("Error writing output to log file: \(error)")
                }
        }
        // 设置环境变量
        task.environment = ProcessInfo.processInfo.environment

        // 设置工作目录为当前用户的主目录
        task.currentDirectoryPath = FileManager.default.homeDirectoryForCurrentUser.path

        do {
            try task.run()
            return task.processIdentifier
        } catch {
            print("Failed to execute command: \(error)")
            return 0
        }

    }
    
    func getDefaultShell() -> String {
        // 尝试从环境变量获取默认 shell
        if let shell = ProcessInfo.processInfo.environment["SHELL"] {
            return shell
        } else {
            // 如果环境变量中没有，返回一个默认值
            return "/bin/bash"
        }
    }

    private func isProcessRunning(pid: Int32) -> Bool {
        if pid==0{
            return false
        }
        else{
            let process = Process()
            process.launchPath = "/bin/ps"
            process.arguments = ["-p", "\(pid)"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.launch()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("\(pid)")
            }
            return false
        }
    }
    
    
    func terminateProcess(pid: Int32) {
        let killTask = Process()
        killTask.launchPath = "/bin/kill"
        killTask.arguments = ["\(pid)"]
        do {
            try killTask.run()
            killTask.waitUntilExit()
            if killTask.terminationStatus == 0 {
                print("Process terminated successfully.")
            } else {
                print("Failed to terminate process.")
            }
        } catch {
            print("Failed to execute kill command: \(error)")
        }
    }
    func replace_non_alphanumeric(name: String) -> String {
      // Compile a regular expression to match all non-alphanumeric characters.
      let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_]")

      // Replace all non-alphanumeric characters with an underscore.
      let name = regex.stringByReplacingMatches(in: name, range: NSRange(location: 0, length: name.utf16.count), withTemplate: "_")

      // Return the modified string.
      return name
    }
    
    func createLogFile(name:String) -> String {
        // 创建一个日志文件
        let fileManager = FileManager.default
        guard let homeDirectory = fileManager.homeDirectoryForCurrentUser.path as String? else { return "" }
        let logDirectory = "\(homeDirectory)/statusBarRunner"
        
        
        // 创建日志文件
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let currentDate = dateFormatter.string(from: Date())
        let logFile = "\(logDirectory)/\(replace_non_alphanumeric(name:name))-\(currentDate).log"
        print(logFile)
        fileManager.createFile(atPath: logFile, contents: nil)
        
        // 返回日志文件路径
        return logFile
    }
}
