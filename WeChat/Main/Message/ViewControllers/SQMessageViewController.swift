//
//  SQMessageViewController.swift
//  WeChat
//
//  Created by ysq on 2017/9/18.
//  Copyright © 2017年 ysq. All rights reserved.
//

import UIKit
import RealmSwift

class SQMessageViewController: UIViewController {
    
    private lazy var statusView: NetworkConnectStatusView = {
        let view = NetworkConnectStatusView(frame: CGRect(x: 0, y: 0, width: 140, height: 40))
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: self.view.bounds, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
        return table
    }()
    
    private var in_chatId = 0
    
    private var listData: [MessageListModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SQWebSocketService.sharedInstance.setupSocket(accessId: UserModel.sharedInstance.id.StringValue, accessToken: UserModel.sharedInstance.accessToken)
        setupSubviews()
        loadData()
        receivedMsg()
        addMsgStatusObserver()
        networkStatusChanged()
        connectionStatusChanged()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNavbarTheme()
        in_chatId = 0
        connectServer()
    }
    
    private func setupSubviews() {
        navigationItem.titleView = statusView
        view.addSubview(tableView)
    }
    
    private func addMsgStatusObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(SQMessageViewController.sendMsg(noti:)), name: NSNotification.Name.init(kIMSendMessageNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SQMessageViewController.messageValueChanged(noti:)), name: NSNotification.Name.init(kIMMessageValueChangedNofication), object: nil)
    }
    
    private func connectServer() {
        if !SQWebSocketService.sharedInstance.isConnection {
            SQWebSocketService.sharedInstance.connectionServer(complectionHanlder: {
//                [weak self] in
                
                
            }) {_ in
//                [weak self] (error) in
                
            }
        }
    }
    
    // MARK: -- Sync Data
    
    private func loadUnPullData() {
        statusView.updateStatus(connectStatus: .dataReceiving)
        var timestamp = UserDefaults.standard.integer(forKey: UserModel.sharedInstance.id.StringValue + "msg_timestamp")
        if timestamp == 0 {
            timestamp = Int(Date().timeIntervalSince1970) * 1000
        }
        
        IMDataManager.sharedInstance.syncMsg(timestamp: timestamp) {
            [weak self] (data, newData ,error) in
            if error {
                self?.statusView.updateStatus(connectStatus: .dataReceevedFailure)

            } else {
                self?.statusView.updateStatus(connectStatus: .connectSuccess)
                
                for element in newData {
                    self?.handleMsg(data: element, isSend: false)
                }
                if let lastTime = data.last?.create_time {
                    self?.saveLastMsg(timestamp: lastTime)
                    //有可能还有未拉取的数据, 当前是一次拉取20条数据
                    if data.count == 20 {
                        self?.loadUnPullData()
                    } else {
                        //所有数据拉取完了...拉取未读条数
                        self?.loadUnReadMsgCount()
                    }
                }
            }
        }
//        IMDataManager.sharedInstance.getUnReadMsgCount(chatIds: "2,3,7")
    }
    
    private func loadUnReadMsgCount() {
        var ids = ""
        for element in listData {
            ids = ids + "," + element.chatId.StringValue
        }
        IMDataManager.sharedInstance.getUnReadMsgCount(chatIds: ids)
    }
    
    
    private func networkStatusChanged() {
        NetworkStatusManager.shared.networkStatusChangedHandle = {
            [weak self] status in
            switch status {
            case .none:
                self?.view.show(message: "网络连接失败,请检查网络连接情况")
            case .wifi:
                self?.view.show(message: "已连接到WIFI网络")
            case .cellular:
                self?.view.show(message: "已连接到4G网络")
            }
        }
    }
    
    private func connectionStatusChanged() {
        SQWebSocketService.sharedInstance.statusChangedHandle = {
            [weak self] status in
            if status == IMSocketConnectionStatus.connectSuccess {
                self?.loadUnPullData()
            }
            self?.statusView.updateStatus(connectStatus: status)
        }
    }
    
    // MARK: -- 数据处理
    
    private func loadData() {
        listData = SQCache.allMsgList()
        self.tableView.reloadData()
    }
    
    private func receivedMsg() {
        IMDataManager.sharedInstance.receivedHandler = {
            [weak self] (model) in
            print("received msg in message controller")
            self?.saveLastMsg(timestamp: model.create_time)
            self?.handleMsg(data: model, isSend: false)
        }
    }
    
    @objc private func sendMsg(noti: Notification) {
        if let userInfo = noti.userInfo {
            if let model = userInfo[kIMMessageValueKey] as? IMMessageModel {
                self.handleMsg(data: model, isSend: true)
            }
        }
    }
    
    @objc private func messageValueChanged(noti: Notification) {
        if let userInfo = noti.userInfo {
            if let model = userInfo[kIMMessageValueKey] as? IMMessageModel {
                if let index = self.searchForData(id: model.received_id) {
                    let msg = self.listData[index]
                    SQCache.update(time: model.create_time, msg_id: model.msg_id, model: msg)
                    tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                }
            }
        }
    }
    
    private func handleMsg(data: IMMessageModel, isSend: Bool) {
        let listModel = MessageListModel()
        listModel.msg_id = data.msg_id
        if isSend {
            listModel.chatId = data.received_id
            listModel.name = data.received_name
            listModel.avatar = data.received_avatar
        } else {
            listModel.avatar = data.sender_avatar
            listModel.chatId = data.sender_id
            listModel.name = data.sender_name
            listModel.unread_count = 1
        }
        listModel.msg_seq = data.msg_seq
        listModel.content = data.msg_content
        listModel.create_time = data.create_time
        
        if let index = self.searchForData(id: listModel.chatId) {
            let oldMsg = self.listData[index]
            //如果是正在聊天的或者是自己发送的 就不登记未读数
            if !isSend && oldMsg.chatId != in_chatId {
                listModel.unread_count = oldMsg.unread_count + 1
            }
            SQCache.delete(model: oldMsg)
            
            self.listData.remove(at: index)
        }
        
        self.listData.insert(listModel, at: 0)
        self.listDataSort()
        SQCache.saveMsgListInfo(with: listModel)
        self.tableView.reloadData()

    }
    
    private func listDataSort() {
        for (index, element) in listData.enumerated() {
            let realm = try! Realm()
            try! realm.write {
                element.sort = index + 1
            }
        }
    }
    
    private func searchForData(id: Int) -> Int? {
        for (index, element) in listData.enumerated() {
            if element.chatId == id {
                return index
            }
        }
        return nil
    }
    
    private func saveLastMsg(timestamp: Int) {
        UserDefaults.standard.set(timestamp, forKey: UserModel.sharedInstance.id.StringValue + "msg_timestamp")
        UserDefaults.standard.synchronize()
    }
    
}

extension SQMessageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "sqMessageCell") as? SQMessageCell
        if cell == nil {
            cell = SQMessageCell(style: .default, reuseIdentifier: "sqMessageCell")
        }
        cell?.model = listData[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? SQMessageCell {
            cell.showRedMessage = false
        }
        let chat = IMChatViewController()
        chat.chat_id = listData[indexPath.row].chatId
        chat.name = listData[indexPath.row].name
        navigationController?.pushViewController(chat, animated: true)
        let realm = try! Realm()
        try! realm.write {
            listData[indexPath.row].unread_count = 0
        }
        //记录当前正在聊天的id
        in_chatId = chat.chat_id
    }
    
}
