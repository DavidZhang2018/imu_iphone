//
//  ViewController.swift
//  test
//
//  Created by Justin Kwok Lam CHAN on 4/4/21.
//

import Charts
import UIKit
import CoreMotion

class ViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var ts: Double = 0
    var gyro_x: Double = 0
    var angle: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.lineChartView.delegate = self
        
        let set_a: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "x")
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.blue)
        
        let set_b: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "y")
        set_b.drawCirclesEnabled = false
        set_b.setColor(UIColor.red)
        
        let set_c: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "z")
        set_c.drawCirclesEnabled = false
        set_c.setColor(UIColor.green)
        self.lineChartView.data = LineChartData(dataSets: [set_a,set_b,set_c])
    }
    
    @IBAction func startSensors(_ sender: Any) {
        ts=NSDate().timeIntervalSince1970
        label.text=String(format: "%f", ts)
        startboth()
        startButton.isEnabled = false
        stopButton.isEnabled = true
    }
    
    @IBAction func stopSensors(_ sender: Any) {
        stopboth()
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    
    var timer_accel:Timer?
    var accel_file_url:URL?
    var accel_fileHandle:FileHandle?
    
    var timer_gyro:Timer?
    var gyro_file_url:URL?
    var gyro_fileHandle:FileHandle?
    
    let xrange:Double = 500
    
    func startboth() {

            if motion.isGyroAvailable {
               self.motion.gyroUpdateInterval = 1.0 / 60.0
               self.motion.startGyroUpdates()
             
             do {
                 let file = "gyro_file_\(ts).txt"
                 if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                     gyro_file_url = dir.appendingPathComponent(file)
                 }
                 
                 try "ts,x,y,z\n".write(to: gyro_file_url!, atomically: true, encoding: String.Encoding.utf8)

                 gyro_fileHandle = try FileHandle(forWritingTo: gyro_file_url!)
                 gyro_fileHandle!.seekToEndOfFile()
             } catch {
                 print("Error writing to file \(error)")
             }
           }
        
        
        // Configure a timer to fetch the data.
        self.timer_accel = Timer(fire: Date(), interval: (1.0/60.0),
                                 repeats: true, block: { [self] (timer) in
            
        
            // get the gyro data
            if let data = self.motion.gyroData {
                let x = data.rotationRate.x-0.004
                let y = data.rotationRate.y+0.0027
                let z = data.rotationRate.z+0.0036
               self.gyro_x = x
               let timestamp = NSDate().timeIntervalSince1970
               let text = "\(timestamp), \(x), \(y), \(z)\n"
               print ("G: \(text)")
               
            }

            
            
            // Make sure the accelerometer hardware is available.
            if self.motion.isAccelerometerAvailable {
             // sampling rate can usually go up to at least 100 hz
             // if you set it beyond hardware capabilities, phone will use max rate
               self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
               self.motion.startAccelerometerUpdates()
             
             // create the data file we want to write to
             // initialize file with header line
             do {
                 // get timestamp in epoch time
                 let file = "accel_file_\(ts).txt"
                 if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                     accel_file_url = dir.appendingPathComponent(file)
                 }
                 
                 // write first line of file
                 try "ts,x,y,z\n".write(to: accel_file_url!, atomically: true, encoding: String.Encoding.utf8)

                 accel_fileHandle = try FileHandle(forWritingTo: accel_file_url!)
                 accel_fileHandle!.seekToEndOfFile()
             } catch {
                 print("Error writing to file \(error)")
             }}
                
            
           // Get the accelerometer data.
            if let data = self.motion.accelerometerData {
                let x = data.acceleration.x-0.0013
                let y = data.acceleration.y+0.0038
                let z = data.acceleration.z+0.0068
                self.angle = abs(0.98*(self.angle+(1.0/60)*self.gyro_x*180/Double.pi))+abs(0.02*(180-acos(z/sqrt(x*x+y*y+z*z))*180/Double.pi))

              let timestamp = NSDate().timeIntervalSince1970
              let text = "\(timestamp), \(x), \(y), \(z)\n"
              print ("A: \(text)")

              self.accel_fileHandle!.write(text.data(using: .utf8)!)
                
              self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(counter), y: self.angle), dataSetIndex: 0)
              // refreshes the data in the graph
              self.lineChartView.notifyDataSetChanged()
                
              self.counter = self.counter+1
              
              // needs to come up after notifyDataSetChanged()
              if counter < xrange {
                  self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: xrange)
              }
              else {
                  self.lineChartView.setVisibleXRange(minXRange: counter, maxXRange: counter+xrange)
              }
           }
            
        })

        // Add the timer to the current run loop.
      RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
        


    }
    
    
    func stopboth() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
        
           accel_fileHandle!.closeFile()
       }
        
        
        if self.timer_gyro != nil {
           self.timer_gyro?.invalidate()
           self.timer_gyro = nil

           self.motion.stopGyroUpdates()
           
            gyro_fileHandle!.closeFile()
        }
     }
    }
    
