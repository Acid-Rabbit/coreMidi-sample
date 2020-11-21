//
//  MidiManager.swift
//  coreMidi-sample
//
//  Created by 服部翼 on 2020/11/19.
//

import Foundation
import CoreMIDI

protocol MIDIManagerDelegate {
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8)
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8)
    func logOutPrint(log: Any)
}


class MIDIManager {
    
    var numberObSources = 0
    var sourceNames = [String]()
    
    var delegate: MIDIManagerDelegate?
    
    init() {
        findMIDISources()
    }
    
    //MARK: MIDIデバイスの一覧を取得
    func findMIDISources() {
        sourceNames.removeAll()
        numberObSources = MIDIGetNumberOfSources() //システム内のデバイスの数を返します。
        
        for i in 0..<numberObSources {
            let src = MIDIGetSource(i) //システム内のソースを返します。
            var cfStr: Unmanaged<CFString>?
            /*
             Unmanaged<T> は参照型の値をこの管理下から外すためのハンドラであり、
             参照型の値 T に対して、明示的な参照カウンタ操作を呼び出せます。
             */
            
            //オブジェクトの文字列型プロパティを取得します。
            let err: OSStatus = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &cfStr)
            
            if err == noErr {
                //takeRetainedValue() Unmanagedから参照型へ変換、カウンタはそのまま
                if let str = cfStr?.takeRetainedValue() as String? {
                    sourceNames.append(str)
                }
            }
            
            /*
             注意点はCore MIDIはCore Foundationを使用するC言語ベースのフレームワークなので、文字列はStringではなくCFStringであり、
             文字列の取得はCFStringのポインタを渡す形で行う点です。
             取得されたCFStringは自動でメモリ管理されないため、takeRetainedValue()を呼んだ上でSwiftの文字列に変換します。
             */
        }
    }
    
    //MARK: MIDIClientを作成
    func connectMIDIClient(_ index: Int) {
        let name = NSString(string: sourceNames[index])
        var client = MIDIClientRef() //クライアントごとの状態を維持するオブジェクト。
        var err = MIDIClientCreateWithBlock(name, &client) { (pointer) in
            self.onMIDIStatusChanged(message: pointer)
        }
        
        if err != noErr {
            print("client_Error")
            return
        }
        
        //MARK: MIDIInputPortを作成
        let portName = NSString("inputPort")
        var port = MIDIPortRef() //クライアントが維持するMIDI接続。
        err = MIDIInputPortCreateWithBlock(client, portName, &port) { (packetList, pointer) in
            self.onMIDIMessageReceived(message: packetList, srcConnRefCon: pointer)
        }
        
        if err != noErr {
            print("MIDI_input_Error")
            return
        }
        
        let src = MIDIGetSource(index)
        err = MIDIPortConnectSource(port, src, nil)
        if err != noErr {
            delegate?.logOutPrint(log: "MIDI_output_Error")
            print("MIDI_output_Error")
            return
        }
    }
    
    func onMIDIStatusChanged(message: UnsafePointer<MIDINotification>) {
        delegate?.logOutPrint(log: message)
        print("MIDI Status changed!")
    }
    
    func onMIDIMessageReceived(message: UnsafePointer<MIDIPacketList>, srcConnRefCon:UnsafeMutableRawPointer?) {
        print("MIDI Message Received")
        let packetList: MIDIPacketList = message.pointee
        let numPackets = packetList.numPackets
        
        var packet = packetList.packet
        print("packet:::",packet)
        delegate?.logOutPrint(log: packet)
        /*
         MIDIメッセージはMIDIPacketListというデータ型にまとめて入っており、
         MIDIPacketNext()を呼んでやることで次のデータへのポインタが返ってくるようになっています。
         */
        
        /*
         最初の1バイトが0x9nの場合ノートオン、0x8nの場合はノートオフで、numPacketsはチャンネル番号を表します。
         またノートオン／オフの場合は続く2バイトでノートナンバー（音高）とベロシティ（強さ）が取得できるので、
         これらの情報を使って音の高さ、強さに合わせた処理を書けばよいでしょう。
         */
        for _ in 0..<numPackets {
            let mes: UInt8 = packet.data.0 & 0xF0
            let ch: UInt8 = packet.data.0 & 0x0F
            
            if mes == 0x90 && packet.data.2 != 0 {
                print("note ON")
                let noteNo = packet.data.1
                let velocity = packet.data.2
                DispatchQueue.main.async {[weak self] in
                    self?.delegate?.noteOn(ch: ch, note: noteNo, vel: velocity)
                }
            } else if (mes == 0x80 || mes == 0x90) {
                let noteNo = packet.data.1
                let velocity = packet.data.2
                DispatchQueue.main.async {[weak self] in
                    self?.delegate?.noteOff(ch: ch, note: noteNo, vel: velocity)
                }
            }
            
            let packetPtr = MIDIPacketNext(&packet)
            packet = packetPtr.pointee
        }
    }
}
