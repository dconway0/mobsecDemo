//
//  ViewController.swift
//  malDemo
//
//  Created by David Conway on 4/21/25.
//

//  ' OR '1' = '1

import UIKit
import CryptoKit
import SQLite3

class ViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var positionField: UITextField!
    @IBOutlet weak var salaryField: UITextField!
    @IBOutlet weak var addPassField: UITextField!
    @IBOutlet weak var addMessage: UILabel!
    
    @IBOutlet weak var findPassField: UITextField!
    @IBOutlet weak var findMessage: UILabel!
    
    @IBOutlet weak var secretMessage: UILabel!
    
    var Verified: Bool = false
    
    var db: OpaquePointer?

    override func viewDidLoad() {
        super.viewDidLoad()
        openDatabase()
        createTable()
        // Do any additional setup after loading the view.
    }
    
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0)}.joined()
    }
    
    func getDatabasePath() -> String {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[0]
        let dbPath = documentsDirectory.appendingPathComponent("employees.sqlite").path
        return dbPath
    }
    
    func openDatabase() {
        let dbPath = getDatabasePath()
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("Successfully opened or created database at: \(dbPath)")
        } else {
            print("Unable to  open database")
        }
    }
    
    func createTable() {
        let createTableQuery =  """
        CREATE TABLE  IF NOT EXISTS users (
            username TEXT PRIMARY KEY,
            position TEXT,
            salary REAL,
            password TEXT UNIQUE
        );
        """
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) == SQLITE_OK {
            print("Table created or already exists")
        } else {
            print("Failed to create table.")
        }
    }

    @IBAction func addEmp(_ sender: UIButton) {
        guard let name = nameField.text, let position = positionField.text, let salary = Double(salaryField.text!), let password = addPassField.text else { return }
        
        let passHash = hashPassword(password)
        
        let query = "INSERT INTO users (username, position, salary, password) VALUES (?, ?, ?, ?);"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, (position as NSString).utf8String, -1, nil)
            sqlite3_bind_double(stmt, 3, salary)
            sqlite3_bind_text(stmt, 4, (passHash as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_DONE {
                addMessage.text = "User inserted"
            } else {
                addMessage.text = "Insert failed"
            }
        } else {
            addMessage.text = "Insert prep failed"
        }
        
        sqlite3_finalize(stmt)
    }
    
    @IBAction func findEmp(_ sender: Any) {
        guard let password = findPassField.text else { return }
        
        let passHash = hashPassword(password)
        
        let query = "SELECT * FROM users WHERE password = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            
            sqlite3_bind_text(stmt, 1, (passHash as NSString).utf8String, -1, nil)
            
            var results = ""
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                let username = String(cString: sqlite3_column_text(stmt, 0))
                let position = String(cString: sqlite3_column_text(stmt, 1))
                let salary = sqlite3_column_double(stmt, 2)
                let password = String(cString: sqlite3_column_text(stmt, 3))
                
                results += "Name: \(username)\nPosition: \(position)\nSalary: \(salary)\nPassword: \(password)\n\n"
            }
            
            if results.isEmpty {
                findMessage.text = "No results found"
            } else {
                Verified = true
                findMessage.text = results
            }
        } else {
            findMessage.text = "Query failed"
        }
        sqlite3_finalize(stmt)
    }
    
    @IBAction func getSecret(_ sender: Any) {
        if Verified {
            secretMessage.text = "Secret message for verified"
        } else {
            secretMessage.text = "Not verified"
        }
    }
    
}

