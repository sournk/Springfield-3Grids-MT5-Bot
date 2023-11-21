# Springfield-3Grids-MT5-Bot

MQL5 Task: [207191](https://www.mql5.com/en/job/207191)
Requirements read in [requirements.md](requirements.md).

The Springfield bot is an expert advisor for MetaTrader 5. It implements a grid algorithm with increasing volume for the next opened position at a set price distance.

The bot can simultaneously manage 3 grids on a single instrument with different parameters. 

The next position in each grid is opened after the price passes a specified distance in the opposite direction of the take profit. The new positions volume calculates as a the volume of the last grid position multiplied by a specified coefficient.

The bot maintains a take profit on all its positions at a specified distance from the grid's weighted average price. If any of the grid positions are closed, the bot will update the take profit for the remaining orders by the specified distance from the average price. Manually updating the take profit for a position is not possible, the bot will set the necessary value if it detects that the current one has changed.

![The bot is set on the chart](img/0003.%20Bot%20Chart.png)

# Inputs

![Inputs Dialog](img/0002.%20Result%20settings.png)

Для каждой сетки применяются следующие параметры:
1. MaxTrades: Max grid size.
2. Lots: Initial grid order lots size.
3. LotsExponent: Next grid order volume ratio.
4. Step: Price distance to open next grid order, points.
6. Take Profit: Distance from grid breakeven, points.
7. RSI timeframe.


