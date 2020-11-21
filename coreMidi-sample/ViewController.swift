//
//  ViewController.swift
//  coreMidi-sample
//
//  Created by 服部翼 on 2020/11/19.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    private var midi: MIDIManager?
    
    var logPrint = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "LogTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "LogTableViewCell")
        
        tableView.delegate = self
        tableView.dataSource = self
        logPrint.append("start_viewController")
        midi = MIDIManager()
        
        
    }
    
    func midiConnect() {
        if let midi = midi {
            print(midi)
            if 0 < midi.numberObSources {
                midi.connectMIDIClient(0)
                midi.delegate = self
            }
        }
    }
    
    @IBAction func scanButton(_ sender: Any) {
        print("tapScan")
        midiConnect()
    }
}

extension ViewController: UITableViewDelegate ,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logPrint.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogTableViewCell", for: indexPath) as! LogTableViewCell
        cell.textLabel?.text = logPrint[indexPath.row]
        return cell
    }
}

extension ViewController: MIDIManagerDelegate {
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8) {
        print("noteOn",ch,note,vel)
    }
    
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8) {
        print("noteOff",ch,note,vel)
    }
    
    func logOutPrint(log: Any) {
        let log = "\(log)"
        logPrint.append(log)
        tableView.reloadData()
    }
}
