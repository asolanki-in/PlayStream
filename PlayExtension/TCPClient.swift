//
//  TCPClient.swift
//  PlayScreen
//
//  Created by Anil Solanki on 08/12/24.
//

import Foundation
import CocoaAsyncSocket
import OSLog


class TCPClient: NSObject, GCDAsyncSocketDelegate  {
    private var serverSocket: GCDAsyncSocket?
        private var clientSockets: [GCDAsyncSocket] = []
        private let port: UInt16
        
        init(port: UInt16 = 5001) {
            self.port = port
            super.init()
            setupServer()
        }
        
        private func setupServer() {
            serverSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            
            do {
                try serverSocket?.accept(onPort: port)
                os_log(.debug, log: .default, "Server started on port \(self.port)");
            } catch {
                os_log("Error starting server: \(error)")
            }
        }
        
        // MARK: - GCDAsyncSocketDelegate
        
        func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
            print("New client connected: \(newSocket.connectedHost ?? "unknown")")
            clientSockets.append(newSocket)
            
            // Start reading data from this client
            newSocket.readData(withTimeout: -1, tag: 0)
        }
        
        func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
            // Process received data
            if let message = String(data: data, encoding: .utf8) {
                print("Received message: \(message)")
                
                // Echo back to client
                let response = "Server received: \(message)".data(using: .utf8)!
                sock.write(response, withTimeout: -1, tag: 0)
            }
            
            // Continue reading
            sock.readData(withTimeout: -1, tag: 0)
        }
        
        func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
            if let error = err {
                print("Client disconnected with error: \(error)")
            } else {
                print("Client disconnected")
            }
            
            clientSockets.removeAll { $0 === sock }
        }
        
        // Method to broadcast data to all connected clients
        func broadcast(data: Data) {
            for clientSocket in clientSockets {
                clientSocket.write(data, withTimeout: -1, tag: 0)
            }
        }
}
