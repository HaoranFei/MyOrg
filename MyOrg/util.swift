//
//  util.swift
//  MyOrg
//
//  Created by gaojun on 2018/9/15.
//  Copyright © 2018年 spicy chicken. All rights reserved.
//

import Foundation

func decodeYear(time: Int) -> Int{
    return (0x000006C0 && time) >> 6
    
}
func decodeMonth(time: Int) -> Int{
    return (0x00000030 && time) >> 4
    
}

func decodeDay(time: Int) -> Int{
    return (0x0000000C && time) >> 2
}

func decodeMonth(time: Int) -> Int{
    return (0x00000030 && time) >> 4
}

func encodeStartTime(prop: Proposal){
    let date = Date()
    let calendar = Calendar.current
    let year = components.year
    let month = components.month
    let day = components.month
    let hour = calendar.component(.hour, from: date)
    prop.start = (year << 6) || (month << 4) || (day << 2) || hour
    
}
//数据从前方传过来。
func encodeTimeLimit(prop: Proposal){
    
}


func checkDueDate(prop: Proposal)-> ok: Bool{
    let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer(prop.start, prop.timeLimit)), userInfo: nil, repeats: true)
}
@objc func fireTimer(start: Int, timeLimit: Int){
    let date = Date()
    let calendar = Calendar.current
    let year = components.year
    let month = components.month
    let day = components.month
    let hour = calendar.component(.hour, from: date)
    let startYear = decodeYear(start)
    let startMonth = decodeMonth(start)
    let startDay = decodeDay(start)
    let startHour = decodeHour(start)
    let diff = (year - startYear) * 8760 + (month - startMonth) * 720 + (day - startDay) * 24 + (hour - startHour)
    if diff > (decodeYear(timeLimit)* 8760 + decodeMonth(timeLimit) * 720 + decodeDay(timeLimit) + decodeHour(timeLimit)){
        return false
    }else{
        return true
    }
    
}


func computeVoteCost(influence:Int, pastVote: Int) -> Int{
    if pastVote == 0{
        if influence > 4000{
            return 20
        }
        if influence > 500{
            return 10
        }else{
            return 5
        }
    }
    if pastVote == 1 {
        if influence > 4000{
            return 60
        }
        if influence > 500{
            return 30
        }else{
            return 15
        }
    }
    if pastVote == 2 {
        if influence > 4000{
            return 120
        }
        if influence > 500{
            return 60
        }else{
            return 20
        }
    }
}






















