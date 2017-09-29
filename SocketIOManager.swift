//
//  SocketIOManager.swift
//
//  Created by Akhilesh on 28/11/16.
//  Copyright © Akhilesh. All rights reserved.
//

import Foundation
import SocketIO

enum EventType: String {
    case connect
    case disconnect
    case error
}

enum SocketStatus {
    case connect(Any)
    case error(Any)
    case disconnected(Any)
    case other((String, Any))
}

class SocketIOManager: NSObject {
    
    //MARK:- Properties
    private var socketConfig: SocketIOClientConfiguration?
    private var socketIO: SocketIOClient?
    static var shared: SocketIOManager?
    static var socketUrl =  String()
    static var accessToken: String?
    var eventCallBack: ((SocketStatus) -> Void)? {
        didSet {
            self.socketJoin()
        }
    }
    private var events = [EventType.connect.rawValue, EventType.error.rawValue, EventType.disconnect.rawValue]
    
    
    @discardableResult
    func addEvents(names: [String]) -> SocketIOManager {
        self.events += names
        return self
    }
    
    override init() {
        super.init()
        guard let socketUrl = URL(string: SocketIOManager.socketUrl),
            let accessToken = SocketIOManager.accessToken else {
                print("Could not get socketUrl or accesstoken")
                return
        }
        socketConfig = SocketIOClientConfiguration(arrayLiteral: SocketIOClientOption.connectParams(["authorization": accessToken]))
        if let socketConfig = self.socketConfig {
            socketIO = SocketIOClient(socketURL: socketUrl, config: socketConfig)
        }
    }
    
    private func addHandlers(events: [String]) {
        self.switchOffHandlers(events: events)
        for event in events {
            socketIO?.on(event, callback: { [weak self] (data, ack) in
                print("\(event) added")
                print(data)
                guard let callBack = self?.eventCallBack
                    else {
                        return
                }
                switch event {
                case "connect":
                    callBack(.connect(data))
                case "error":
                    callBack(.error(data))
                case "disconnect":
                    callBack(.disconnected(data))

                default:
                    print("listening to other Event")
                    callBack(.other((event, data)))
                }
            })
        }
    }

    
   private func switchOffHandlers(events: [String]) {
        
        for event in events {
            socketIO?.off(event)
        }
    }
    
    func emitEvent(name: String, params: [String: Any]?) {
        var para = params
        if para == nil {
            para = [:]
        }
        socketIO?.emit(name, with: [para])
    }
    
   private func socketJoin() {
        self.addHandlers(events: events)
        socketIO?.connect()
    }
    
    func socketDisconnect() {
        self.socketIO?.disconnect()
    }
}
