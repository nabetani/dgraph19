import math
import numpy as np
from matplotlib import pyplot
from matplotlib.backends.backend_pdf import PdfPages
import pandas as pd
from datetime import datetime, date, timedelta


def filenames():
    return {
        "Japan": "logs/2020_03_29_16_40.csv"
    }


SQUARE_20cm = (20/2.54, 20/2.54)


def ymd(v):
    return date(v[0], v[1], v[2])


def getDays(v):
    max = ymd(v[-1])
    r = []
    d = ymd(v[0])
    while d <= max:
        r.append(d)
        d = d+timedelta(days=1)
    return r


def getY(values, day):
    match = [v for v in values if ymd(v) == day]
    if match:
        return match[0][3]
    return 0


def plot_op(fig, datas):
    fig.suptitle("COVID-19 death toll")
    graph = fig.add_subplot(1, 1, 1)  # nrows, ncols, index
    for key in datas:
        values = datas[key].values
        days = getDays(values)
        y = [getY(values, day) for day in days]
        graph.plot(days, y, label=key)
    labels = graph.get_xticklabels()
    pyplot.setp(labels, rotation=90)
    graph.legend()
    fig.subplots_adjust(top=0.9, bottom=0.15)
    fig.align_labels()  # 同一ページ内の y-label の位置などを揃える


def main():
    fns = filenames()
    datas = {}
    for key in fns:
        fn = fns[key]
        datas[key] = pd.read_csv(fn, usecols=[0, 1, 2, 3])
    plot_op(pyplot.figure(figsize=SQUARE_20cm), datas)

    pyplot.savefig('graph.png')


main()
