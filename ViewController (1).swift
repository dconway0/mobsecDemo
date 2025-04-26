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
        guard let name = nameField.text, let position = positionField.text, let salary = Int(salaryField.text!), let password = addPassField.text else { return }
        
        let query = "INSERT INTO users (username, position, salary, password) VALUES ('\(name)', '\(position)', '\(salary)', '\(password)');"
        if sqlite3_exec(db, query, nil, nil, nil) == SQLITE_OK {
            addMessage.text = "User inserted"
        } else {
            addMessage.text = "Insert failed"
        }
    }
    
    @IBAction func findEmp(_ sender: Any) {
        guard let password = findPassField.text else { return }
        let query = "SELECT * FROM users WHERE password = '\(password)';"
        print("\(query)")
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            var results = ""
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                let username = String(cString: sqlite3_column_text(stmt, 0))
                let position = String(cString: sqlite3_column_text(stmt, 1))
                let salary = sqlite3_column_double(stmt, 2)
                let password = String(cString: sqlite3_column_text(stmt, 3))
                
                results += "Name: \(username)\nPosition: \(position)\nSalary: \(salary)\nPassword: \(password)\n\n"
            }
            findMessage.text = results.isEmpty ? "No results found" : results
        } else {
            findMessage.text = "Query failed"
        }
        sqlite3_finalize(stmt)
    }
    
    @IBAction func getSecret(_ sender: Any) {
        secretMessage.text = "This message is not protected by any verification"
    }
    
}

