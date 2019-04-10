//
//  ChartUIModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

internal struct ChartUIModel
{
    internal let dates: [Chart.Date]
    internal let columns: [ColumnUIModel]
    internal let aabb: AABB
    
    public let interval: ChartViewModel.Interval
    public let fullInterval: ChartViewModel.Interval
    
    public init(viewModel: ChartViewModel, fully: Bool, size: Double) {
        self.dates = viewModel.dates
        self.interval = viewModel.interval
        self.fullInterval = viewModel.fullInterval
        
        let fixedInterval = calcFixedInterval(by: fully ? fullInterval : interval, use: viewModel.dates)
        
        if viewModel.yScaled {
            (self.columns, self.aabb) = y2Calculator(viewModel: viewModel, interval: fixedInterval, size: size)
        } else if viewModel.stacked {
            (self.columns, self.aabb) = stackedCalculator(viewModel: viewModel, interval: fixedInterval, size: size)
        } else {
            (self.columns, self.aabb) = simpleCalculator(viewModel: viewModel, interval: fixedInterval, size: size)
        }
    }
    
    internal func translate(date: Chart.Date, to rect: CGRect) -> CGFloat {
        let xScale = rect.width / CGFloat(aabb.dateInterval)
        let xOffset = rect.minX - CGFloat(aabb.minDate) * xScale
        
        return xOffset + CGFloat(date) * xScale
    }

    internal func translate(x: CGFloat, from rect: CGRect) -> Chart.Date {
        let x = max(rect.minX, min(x, rect.maxX))
        let xScale = Double(aabb.dateInterval) / Double(rect.width)
        return aabb.minDate + Chart.Date(round(Double(x - rect.minX) * xScale))
    }
    
    internal func find(around date: Chart.Date) -> Chart.Date {
        for i in 1..<dates.count {
            if date <= dates[i] {
                if (date - dates[i - 1]) < (dates[i] - date) {
                    return dates[i - 1]
                }
                return dates[i]
            }
        }
        // uncritical
        return dates[dates.count - 1]
    }

}

private func stackedCalculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, size: Double) -> ([ColumnUIModel], AABB)
{
    var minValue: AABB.Value = 0
    var maxValue: AABB.Value = 0
    
    let visibleColumns = chartVM.columns.filter { $0.isVisible }
    for i in 0..<chartVM.dates.count {
        if interval.from <= chartVM.dates[i] && chartVM.dates[i] <= interval.to {
            let value = AABB.Value(visibleColumns.map { $0.values[i] }.reduce(0, +))
            
            minValue = min(minValue, value)
            maxValue = max(maxValue, value)
        }
    }
    
    let aabb = AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue)
    
    var prevData: [ColumnUIModel.Data]? = nil
    let columns: [ColumnUIModel] = chartVM.columns.map { columnVM in
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, prevData: prevData)
        prevData = data
        return ColumnUIModel(isVisible: columnVM.isVisible,
                             aabb: aabb,
                             data: data,
                             color: columnVM.color,
                             size: size)
    }
    
    return (columns, aabb)
}

private func simpleCalculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, size: Double) -> ([ColumnUIModel], AABB)
{
    let aabbs: [AABB] = calculateAABBs(viewModel: chartVM, interval: interval)
    
    let visibleAABBS = zip(chartVM.columns, aabbs).filter { $0.0.isVisible }.map { $1 }
    let minValue = visibleAABBS.map { $0.minValue }.min() ?? 0
    let maxValue = visibleAABBS.map { $0.maxValue }.max() ?? 0
    
    let aabb = AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue)
    
    let columns: [ColumnUIModel] = chartVM.columns.map { columnVM in
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, prevData: nil)
        return ColumnUIModel(isVisible: columnVM.isVisible,
                             aabb: aabb,
                             data: data,
                             color: columnVM.color,
                             size: size)
    }
    
    return (columns, aabb)
}

private func y2Calculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, size: Double) -> ([ColumnUIModel], AABB)
{
    let aabbs: [AABB] = calculateAABBs(viewModel: chartVM, interval: interval)
    
    let visibleAABBS = zip(chartVM.columns, aabbs).filter { $0.0.isVisible }.map { $1 }
    let minValue = visibleAABBS.map { $0.minValue }.min() ?? 0
    let maxValue = visibleAABBS.map { $0.maxValue }.max() ?? 0
    
    let aabb = AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue)
    
    var prevData: [ColumnUIModel.Data]? = nil
    let columns: [ColumnUIModel] = zip(chartVM.columns, aabbs).map { columnVM, aabb in
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, prevData: prevData)
        prevData = data
        return ColumnUIModel(isVisible: columnVM.isVisible,
                             aabb: aabb,
                             data: data,
                             color: columnVM.color,
                             size: size)
    }
    
    return (columns, aabb)
}

// MARK: - Support

private func calcFixedInterval(by interval: ChartViewModel.Interval, use dates: [Chart.Date]) -> ChartViewModel.Interval {
    let dateStep = dates[1] - dates[0]
    
    let minDate = max(dates[0], interval.from - 1 * dateStep)
    let maxDate = min(dates[dates.count - 1], interval.to + 1 * dateStep)
    
    return ChartViewModel.Interval(from: minDate, to: maxDate)
}

private func calculateAABBs(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval) -> [AABB] {
    return chartVM.columns.map { columnVM in
        assert(chartVM.dates.count == columnVM.values.count)
        
        var minValue = AABB.Value.greatestFiniteMagnitude
        var maxValue = -AABB.Value.greatestFiniteMagnitude
        for i in 0..<chartVM.dates.count {
            if interval.from <= chartVM.dates[i] && chartVM.dates[i] <= interval.to {
                let value = AABB.Value(columnVM.values[i])
                minValue = min(minValue, value)
                maxValue = max(maxValue, value)
                // bar always started from 0, or not?
//                if columnVM.type == .bar {
//                    minValue = min(minValue, 0)
//                    maxValue = max(maxValue, 0)
//                }
            }
        }
        
        return roundAABB(AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue))
    }
}

private func roundAABB(_ aabb: AABB) -> AABB {
    func calculateValueRoundScale() -> Int64 {
        var interval = aabb.maxValue - aabb.minValue
        if interval <= 40 {
            return 1
        }
        
        var scale: Int64 = 10
        while interval >= 400 {
            interval /= 10
            scale *= 10
        }
        
        return scale
    }
    
    let roundScale = calculateValueRoundScale()
    let minValue = aabb.minValue - Double(Int64(aabb.minValue) % roundScale)
    let maxValue = aabb.maxValue + Double(roundScale - Int64(aabb.maxValue) % roundScale)
    
    return AABB(minDate: aabb.minDate, maxDate: aabb.maxDate, minValue: minValue, maxValue: maxValue)
}

private func makeData(by chartVM: ChartViewModel, columnVM: ColumnViewModel, aabb: AABB, prevData: [ColumnUIModel.Data]?) -> [ColumnUIModel.Data] {
    var data: [ColumnUIModel.Data] = []
    data.reserveCapacity(columnVM.values.count)
    
    if columnVM.type == .line {
        for i in 0..<columnVM.values.count {
            let value = AABB.Value(columnVM.values[i])
            data.append(ColumnUIModel.Data(date: chartVM.dates[i], from: value, to: value))
        }
    } else if chartVM.stacked {
        for i in 0..<columnVM.values.count {
            let value = columnVM.isVisible ? AABB.Value(columnVM.values[i]) : 0
            let from: AABB.Value = prevData?[i].to ?? aabb.minValue
            let to: AABB.Value = from + value
            data.append(ColumnUIModel.Data(date: chartVM.dates[i], from: from, to: to))
        }
    } else {
        for i in 0..<columnVM.values.count {
            let value = AABB.Value(columnVM.values[i])
            data.append(ColumnUIModel.Data(date: chartVM.dates[i], from: aabb.minValue, to: value))
        }
    }   
    
    return data
}