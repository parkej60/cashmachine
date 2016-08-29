//
//  main.swift
//  cashmachine
//
//  Created by Jameson Parker on 8/28/16.
//  Copyright © 2016 Parker. All rights reserved.
//

import Foundation


class ConsoleIO {

    enum OutputType {
        case Error
        case Standard
    }
    
    enum OptionType: String {
        case Reload = "R"
        case Withdrawl = "W"
        case Inquire = "I"
        case Quit = "Q"
        case Unknown
        
        init(value: String) {
            switch value {
            case "R": self = .Reload
            case "W": self = .Withdrawl
            case "I": self = .Inquire
            case "Q": self = .Quit
            default: self = .Unknown
            }
        }
    }
    
    
    func getOption(option: String) -> (option:OptionType, value: AnyObject) {
        
        // Get our first character
        let index = option.startIndex.advancedBy(1)
        let inputCommand = option.substringToIndex(index)
        let optionType:OptionType = OptionType(value: inputCommand.uppercaseString)
        
        if optionType == OptionType.Withdrawl || optionType == OptionType.Inquire {
            if option.rangeOfString("$") != nil {
                
                if optionType == OptionType.Inquire {
                    
                    let range = option.startIndex.advancedBy(1)..<option.endIndex
                    var words = [String]()
                    
                    option.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, _, _, _) -> () in
                        words.append(substring!)
                    }
                    
                    if words.count > 0 {
                        return (optionType,words)
                    }
                    
                    
                    
                } else {
                    
                    let startIndex = option.rangeOfString("$")?.startIndex.advancedBy(1)
                    if  option.substringFromIndex(startIndex!) != "" {
                        
                        let amount = option.substringFromIndex(startIndex!)
                        
                        if Int(amount) != nil {
                            return (optionType, Int(amount)!)
                        }
                        
                    }
                }
            }
            
            return (OptionType.Unknown,"")
        }
    
        
        return (optionType, option)
        
    }
    
    func writeMessage(message: String, to: OutputType = .Standard) {
        switch to {
        case .Standard:
            print("\u{001B}[;m\(message)")
        case .Error:
            fputs("\u{001B}[0;31m\(message)\n", stderr)
        }
    }
    
    func getInput() -> String {
        
        let keyboard = NSFileHandle.fileHandleWithStandardInput()
        let inputData = keyboard.availableData
        let strData = NSString(data: inputData, encoding: NSUTF8StringEncoding)!
        return strData.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
}

class CashMachine {
    
    let consoleIO = ConsoleIO()
    
    let DOLLAR_AMOUNTS = [100,50,20,10,5,1] 	// Lets us dicated dollar amounts allowed.
    let CURRENCY_SYMBOL = "$"                   // Selected readable currency symbol
    let WITHDRAWL_REQUEST = []                  // Amount the user is requing to withdrawl
    
    var TEMP_BALANCE = [Int:Int]()                       // Temporary storage for possible updated balance
    var MACHINE_BALANCE = [Int:Int]()                   // Holds associative array of dollar amounts
    var REMAINING_BALANCE = 0
    
    func interactiveMode() {
        
        consoleIO.writeMessage("Welcome to the Cash machine. This program is a ATM simulation.")
        consoleIO.writeMessage("Please enter a command....")
        
        reload()
        showBalance()
       
        var shouldQuit = false
        while !shouldQuit {
            
            let (option, value) = consoleIO.getOption(consoleIO.getInput())
            
            switch option {
            case .Withdrawl:
                    withdrawl(value as! Int)
                    break;
                case .Inquire:
                    inquire(value as! [String])
                    break;
                case .Reload:
                    reload()
                    break;
                case .Quit:
                    shouldQuit = true
                    break;
            default:
                consoleIO.writeMessage("Failure: Invalid Command", to: .Error)
            }
        }
    }
    
    func setRemainingBalance(){

        REMAINING_BALANCE = 0;
        for (amount,quantity) in TEMP_BALANCE {
            REMAINING_BALANCE += amount * quantity
        }
    }
    
    func reload(stockAmount:Int = 10){
        for amount in DOLLAR_AMOUNTS {
            MACHINE_BALANCE[amount] = stockAmount
            TEMP_BALANCE = MACHINE_BALANCE
        }
        
        setRemainingBalance()
    }
    
    func inquire(amounts:[String]){
        
        for amount in amounts {
            
            if Int(amount) != nil && MACHINE_BALANCE[Int(amount)!] != nil {
                consoleIO.writeMessage(CURRENCY_SYMBOL + amount + " - " + String(MACHINE_BALANCE[Int(amount)!]!) )
            }else{
                consoleIO.writeMessage("Failure: Invalid inquiry amount.", to: .Error)
            }
        }
    }
    
    func showBalance(){
        consoleIO.writeMessage(" ")
        consoleIO.writeMessage("Machine Balance")
        
        for i in 0 ..< MACHINE_BALANCE.count {
            consoleIO.writeMessage(CURRENCY_SYMBOL + String(DOLLAR_AMOUNTS[i]) + " - " + String(MACHINE_BALANCE[DOLLAR_AMOUNTS[i]]!))
        }
        
    }
    
    func withdrawl(amount:Int = 0){
    
        var withdrawlAmount = amount
        
        TEMP_BALANCE = MACHINE_BALANCE
        
        if REMAINING_BALANCE > withdrawlAmount {
            
            for dollarAmount in DOLLAR_AMOUNTS {
                
                if withdrawlAmount == 0 {
                    break
                }
                
                let modulus = withdrawlAmount % dollarAmount
                let billsAvailable = TEMP_BALANCE[dollarAmount]! as Int
                let billsNeeded = withdrawlAmount / dollarAmount
                let billsDifference = billsAvailable - billsNeeded
                var amountToWithdraw = 0
                
                if modulus != withdrawlAmount && billsAvailable != 0 {
                    
                    if billsDifference < 0 {
                        amountToWithdraw = billsAvailable * dollarAmount
                        TEMP_BALANCE[dollarAmount] = 0
                    }else if billsDifference > 1 {
                        amountToWithdraw = billsNeeded * dollarAmount
                        TEMP_BALANCE[dollarAmount] = billsDifference
                    }
                
                    withdrawlAmount -= amountToWithdraw
                    
                    setRemainingBalance()
                    
                }
            }
            
            
            if withdrawlAmount != 0 {
                consoleIO.writeMessage("");
                consoleIO.writeMessage("Failure: Insufficient funds. The system needs to be reloaded.", to: .Error)
            }else{
                consoleIO.writeMessage("");
                consoleIO.writeMessage("Success Dispensed " + CURRENCY_SYMBOL + String(amount));
                
                MACHINE_BALANCE = TEMP_BALANCE
                showBalance()
                
            }
        }else{
            consoleIO.writeMessage("Failure: Insufficient funds",to: .Error)
        }
    }
}

let cashMachine = CashMachine()
cashMachine.interactiveMode()


