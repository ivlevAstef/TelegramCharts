//
//  ChartUIModel.swift
//  TelegramCharts
//
//  Created by Alexander Ivlev on 10/04/2019.
//  Copyright © 2019 CFT. All rights reserved.
//

import UIKit

private enum Consts
{
    internal static let yValuesCount: Int = 6

}

private typealias ValueModifier = (Int, ColumnViewModel) -> (AABB.Value)

internal struct ChartUIModel
{
    internal let dates: [Chart.Date]
    internal let columns: [ColumnUIModel]
    internal let aabb: AABB
    internal let percentage: Bool
    
    internal let interval: ChartViewModel.Interval
    internal let fullInterval: ChartViewModel.Interval
    
    public init(viewModel chartVM: ChartViewModel, fully: Bool, size: Double) {
        self.dates = chartVM.dates
        self.interval = chartVM.interval
        self.fullInterval = chartVM.fullInterval
        self.percentage = chartVM.percentage

        let size = ChartUIModel.calculateSize(viewModel: chartVM, maxSize: size)

        let fixedInterval = calcFixedInterval(by: fully ? fullInterval : interval, use: chartVM.dates)
        let c = (16.0 + 5) / Double(UIScreen.main.bounds.width)
        let longInterval = calcLongInterval(by: fully ? fullInterval : interval, use: chartVM.dates, c: c)
        
        if chartVM.percentage {
            self.aabb = percentageAABB(viewModel: chartVM, interval: fixedInterval)
        } else if chartVM.stacked {
            self.aabb = stackedAABB(viewModel: chartVM, interval: fixedInterval, longInterval: longInterval)
        } else {
            self.aabb = normalAABB(viewModel: chartVM, interval: fixedInterval, longInterval: longInterval)
        }
        
        if chartVM.yScaled {
            self.columns = y2Calculator(viewModel: chartVM, interval: fixedInterval, longInterval: longInterval, aabb: self.aabb, size: size)
        } else if chartVM.stacked {
            self.columns = stackedCalculator(viewModel: chartVM, interval: fixedInterval, aabb: self.aabb, size: size)
        } else {
            self.columns = simpleCalculator(viewModel: chartVM, interval: fixedInterval, aabb: self.aabb, size: size)
        }
    }

    private static func calculateSize(viewModel chartVM: ChartViewModel, maxSize: Double) -> Double {
        let distance = Double(chartVM.interval.to - chartVM.interval.from)
        let fullDistance = Double(chartVM.fullInterval.to - chartVM.fullInterval.from)

        let count = Double(chartVM.dates.count) * (distance / fullDistance)

        let cSize = Double(0.75 * UIScreen.main.bounds.width) / count

        return max(1.0, min(cSize, maxSize))
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
    
    internal func find(around date: Chart.Date, in interval: ChartViewModel.Interval) -> Chart.Date {
        let date = max(interval.from, min(date, interval.to))
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

// Value modifiers

private func makeValueModifier(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval) -> ValueModifier {
    if chartVM.percentage {
        return makePercentageValueModifier(viewModel: chartVM, interval: interval)
    }
    return makeNormalValueModifier(viewModel: chartVM, interval: interval)
}


private func makeNormalValueModifier(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval) -> ValueModifier {
    return { i, vm in
        return AABB.Value(vm.values[i])
    }
}

private func makePercentageValueModifier(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval) -> ValueModifier {
    let visibleColumns = chartVM.columns.filter { $0.isVisible }
    var sums: [AABB.Value] = []
    
    for i in 0..<chartVM.dates.count {
        let values = visibleColumns.map { $0.values[i] }
        let sum = AABB.Value(values.reduce(ColumnViewModel.Value(0), +))
        sums.append(sum)
    }
    
    return { i, vm in
        return 100.0 * AABB.Value(vm.values[i]) / sums[i]
    }
}

// AABB

private func stackedAABB(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, longInterval: ChartViewModel.Interval) -> AABB {
    var minValue: AABB.Value = 0
    var maxValue: AABB.Value = 0
    
    let visibleColumns = chartVM.columns.filter { $0.isVisible }
    for i in 0..<chartVM.dates.count {
        if longInterval.from <= chartVM.dates[i] && chartVM.dates[i] <= longInterval.to {
            var value: AABB.Value = 0
            for column in visibleColumns {
                value += AABB.Value(column.values[i])
            }
            
            minValue = min(minValue, value)
            maxValue = max(maxValue, value)
        }
    }
    
    return AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue)
}

private func percentageAABB(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval) -> AABB {
    return AABB(minDate: interval.from, maxDate: interval.to, minValue: 0, maxValue: 100)
}

private func normalAABB(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, longInterval: ChartViewModel.Interval) -> AABB {
    var minValue: AABB.Value = AABB.Value.greatestFiniteMagnitude
    var maxValue: AABB.Value = -AABB.Value.greatestFiniteMagnitude
    
    let visibleColumns = chartVM.columns.filter { $0.isVisible }
    for i in 0..<chartVM.dates.count {
        if longInterval.from <= chartVM.dates[i] && chartVM.dates[i] <= longInterval.to {
            for column in visibleColumns {
                minValue = min(minValue, AABB.Value(column.values[i]))
                maxValue = max(maxValue, AABB.Value(column.values[i]))
            }
        }
    }
    
    return modifyAABB(AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue))
}

// Column UI model

private func makeColumnUIModel(_ columnVM: ColumnViewModel,
                               isOpacity: Bool,
                               aabb: AABB,
                               data: [ColumnUIModel.Data],
                               verticalValues: [AABB.Value],
                               size: Double) -> ColumnUIModel
{
    return ColumnUIModel(isVisible: columnVM.isVisible,
                         isOpacity: isOpacity,
                         aabb: aabb,
                         data: data,
                         verticalValues: verticalValues,
                         color: columnVM.color,
                         name: columnVM.name,
                         size: size,
                         type: columnVM.type)
}

private func stackedCalculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, aabb: AABB, size: Double) -> [ColumnUIModel]
{
    let (begin, end) = makeBeginEndForYValues(viewModel: chartVM, aabb: aabb)
    let modifier = makeValueModifier(viewModel: chartVM, interval: interval)
    var prevData: [ColumnUIModel.Data]? = nil
    return chartVM.columns.map { columnVM in
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, modifier: modifier, prevData: prevData)
        prevData = data
        return makeColumnUIModel(columnVM,
                                 isOpacity: columnVM.type == .line,
                                 aabb: aabb,
                                 data: data,
                                 verticalValues: makeYValues(viewModel: chartVM, begin: begin, end: end),
                                 size: size)
    }
}

private func simpleCalculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, aabb: AABB, size: Double) -> [ColumnUIModel]
{
    let (begin, end) = makeBeginEndForYValues(viewModel: chartVM, aabb: aabb)
    let modifier = makeValueModifier(viewModel: chartVM, interval: interval)
    return chartVM.columns.map { columnVM in
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, modifier: modifier, prevData: nil)
        return makeColumnUIModel(columnVM,
                                 isOpacity: true,
                                 aabb: aabb,
                                 data: data,
                                 verticalValues: makeYValues(viewModel: chartVM, begin: begin, end: end),
                                 size: size)
    }
}

private func y2Calculator(viewModel chartVM: ChartViewModel, interval: ChartViewModel.Interval, longInterval: ChartViewModel.Interval,
                          aabb: AABB, size: Double) -> [ColumnUIModel] {
    func calculateAABB(column: ColumnViewModel) -> AABB {
        var minValue: AABB.Value = AABB.Value.greatestFiniteMagnitude
        var maxValue: AABB.Value = -AABB.Value.greatestFiniteMagnitude
        
        for i in 0..<chartVM.dates.count {
            if longInterval.from <= chartVM.dates[i] && chartVM.dates[i] <= longInterval.to {
                minValue = min(minValue, AABB.Value(column.values[i]))
                maxValue = max(maxValue, AABB.Value(column.values[i]))
            }
        }
        
        return modifyAABB(AABB(minDate: interval.from, maxDate: interval.to, minValue: minValue, maxValue: maxValue))
    }
    
    let modifier = makeValueModifier(viewModel: chartVM, interval: interval)
    return chartVM.columns.map { columnVM in
        let aabb = calculateAABB(column: columnVM)
        let (begin, end) = makeBeginEndForYValues(viewModel: chartVM, aabb: aabb, rounded: false)
        let data = makeData(by: chartVM, columnVM: columnVM, aabb: aabb, modifier: modifier, prevData: nil)
        return makeColumnUIModel(columnVM,
                                 isOpacity: true,
                                 aabb: aabb,
                                 data: data,
                                 verticalValues: makeYValues(viewModel: chartVM, begin: begin, end: end),
                                 size: size)
    }
}

// MARK: - Support

private func calcLongInterval(by interval: ChartViewModel.Interval, use dates: [Chart.Date], c: Double) -> ChartViewModel.Interval {
    let dateStep = Double(dates[1] - dates[0])
    let dateRange = Double(interval.to - interval.from)
    
    let minDate = max(dates[0], Chart.Date(Double(interval.from) - 2.0 * dateStep - c * dateRange))
    let maxDate = min(dates[dates.count - 1], Chart.Date(Double(interval.to) + 2.0 * dateStep + c * dateRange))
    
    return ChartViewModel.Interval(from: minDate, to: maxDate)
}

private func calcFixedInterval(by interval: ChartViewModel.Interval, use dates: [Chart.Date]) -> ChartViewModel.Interval {
    let dateStep = Double(dates[1] - dates[0])
    let minDate = max(dates[0], Chart.Date(Double(interval.from) - 1.0 * dateStep))
    let maxDate = min(dates[dates.count - 1], Chart.Date(Double(interval.to) + 1.0 * dateStep))
    
    return ChartViewModel.Interval(from: minDate, to: maxDate)
}

private func modifyAABB(_ aabb: AABB) -> AABB {
    return roundAABB(increaseAABB(aabb))
}

private func increaseAABB(_ aabb: AABB, increaseProcent: Double = 0.02) -> AABB {
    let minValue = aabb.minValue - aabb.valueInterval * increaseProcent
    let maxValue = aabb.maxValue - aabb.valueInterval * increaseProcent
    
    return AABB(minDate: aabb.minDate, maxDate: aabb.maxDate, minValue: minValue, maxValue: maxValue)
}


private func calculateValueRoundScale(interval: Double) -> Int64 {
    var interval = interval
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

private func roundAABB(_ aabb: AABB) -> AABB {
    let roundScale = calculateValueRoundScale(interval: aabb.maxValue - aabb.minValue)
    let minValue = aabb.minValue - Double(Int64(aabb.minValue) % roundScale)
    let maxValue = aabb.maxValue + Double(roundScale - Int64(aabb.maxValue) % roundScale)
    
    return AABB(minDate: aabb.minDate, maxDate: aabb.maxDate, minValue: minValue, maxValue: maxValue)
}

private func makeBeginEndForYValues(viewModel chartVM: ChartViewModel, aabb: AABB, rounded: Bool = true) -> (begin: AABB.Value, end: AABB.Value) {
    if rounded {
        let preStep = (aabb.maxValue - aabb.minValue) / (Double(Consts.yValuesCount) + 1)
        let preEnd = aabb.minValue + preStep * Double(Consts.yValuesCount)
        
        let begin = aabb.minValue
        let roundScale = calculateValueRoundScale(interval: preEnd - begin)
        let end = preEnd + Double(roundScale - Int64(preEnd) % roundScale)
        
        return (begin, end)
    }
    
    let step = (aabb.maxValue - aabb.minValue) / (Double(Consts.yValuesCount) + 1)
    let end = aabb.minValue + step * Double(Consts.yValuesCount)
    
    return (aabb.minValue, end)
}

private func makeYValues(viewModel chartVM: ChartViewModel, begin: AABB.Value, end: AABB.Value) -> [AABB.Value] {
    if chartVM.percentage {
        return [0.0, 25.0, 50.0, 75.0, 100.0]
    }
    
    let step = (end - begin) / (Double(Consts.yValuesCount) - 1)
    var result: [AABB.Value] = []
    
    var value = begin
    for _ in 0..<Consts.yValuesCount {
        result.append(value)
        value += step
    }
    
    return result
}

private func makeData(by chartVM: ChartViewModel,
                      columnVM: ColumnViewModel,
                      aabb: AABB,
                      modifier: ValueModifier,
                      prevData: [ColumnUIModel.Data]?) -> [ColumnUIModel.Data] {
    var data: [ColumnUIModel.Data] = []
    data.reserveCapacity(columnVM.values.count)
    
    if chartVM.stacked {
        for i in 0..<columnVM.values.count {
            let value = columnVM.isVisible ? modifier(i, columnVM) : 0
            let from: AABB.Value = prevData?[i].to ?? aabb.minValue
            let to: AABB.Value = from + value
            data.append(ColumnUIModel.Data(date: chartVM.dates[i], from: from, to: to, original: columnVM.values[i]))
        }
    } else {
        for i in 0..<columnVM.values.count {
            let value = modifier(i, columnVM)
            data.append(ColumnUIModel.Data(date: chartVM.dates[i], from: aabb.minValue, to: value, original: columnVM.values[i]))
        }
    }
    
    return data
}
