# TelegramCharts
This app maked for [Telegram March and April contests](https://t.me/contest)

My telegram account: @AlexanderStef
My telegram content account: https://contest.dev/chart-ios/entry45


I consume time:
Around 40 hours for Stage1 (March) during two weeks. 
And 55 hours for Stage2 (April) during one weeks.
All this in parallel with the main work.


In both cases I took the 4th place.

# March Contests
### Goal
Build simple (only line) charts based on input data Telegram had provided.
### Description
For look this version need move to tag `v7`. The version was written by fan without a goal to win.
You can find two directories:
Main - Сontains code table with 5 chart cells and cells for change column visible.
Charts - Contains code for show chart and interval selector. 


Code use CALayer with UIBezierPath and not optimized for old devices - can lags.


# April Contests
### Goal
Build five (All different) charts based on input data Telegram had provided. 
An additional goal was also proposed, but I initially decided not to do it.
### Description
For look this version need move to tag `v11` or current commit. The version was written to get the prize.
I specifically retain CALayer and UIBezierPath despite a lot of experience in OpenGL.
But wrote more optimization for smooth work:
* CallFrequenceLimiter - to not recalculate often. Need only for offload CPU and battery ;)
* Cache charts to image in background thread - for smooth scrolling
* Cache UILabels and text size - for smooth transition interval and visible
* Improve UIBezierPath calculations - draw only visible interval
* Improve mathematical component - for quick calculations (but there is something to improve) 


You can find two directories:
Main - Constains code table with 6 chart cells and cells for change column visible.
Charts - Contains code for show chart and interval selector.


More detail about `Charts` directory:
* `ChartProvider.swift` - for load Chart data from json
* `ChartStyle.swift` - color configs for charts
* `Configs.swift` - animation time configs for charts
* `CallFrequenceLimiter.swift` - limits the number of calls per second
* `Models` directory - contains all models: 
+ `Charts.swift` and `Column.swift` - model from provider
+ `AABB.swift` - limiting the area
+ `ColumnViewModel.swift` and `ChartViewModel.swift` - public view models for saving charts/columns state.
+ `ColumnUIModel.swift` and `ChartUIModel.swift` - internal models to display chart.
* `Views` directory - contains all views. First level has public views other internal.
* `Views\Internal` directory - contains base subviews: Hint, interval, chart, dates, axis views.
* `Views\Internal\ColumnsView` directory - contains code for render Columns.

`ColumnsView` directory:
* `ColumnsView.swift` - container containing all columns.
* `ColumnViewLayerWrapper.swift` - base class for render columns. Contains more methods for animation and support cache.
* `PolyLineLayerWrapper.swift` - contains code for generate line points by ColumnUIModel.
* `BarLayerWrapper.swift` - contains code for generate bars points by ColumnUIModel.
* `AreaViewLayerWrapper.swift` - contains code for generate fill line points by ColumnUIModel.


# Finally
This code is not complete - it is stable but not perfect. Use for commercial purposes - does not make sense.
