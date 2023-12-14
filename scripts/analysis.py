#!/usr/bin/env python3
import csv
import datetime
import matplotlib.pyplot as plt
import os
import shutil
from pathlib import Path
import pandas as pd


def find_begin_and_endtime():
    with open('../transformed_data/transformed.csv') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=';')
        next(csv_reader)  # skip header
        firstline = next(csv_reader)
        begin = int(firstline[0])
        end = int(firstline[0])
        for row in csv_reader:
            if int(row[0]) < begin:
                begin = int(row[0])
            elif int(row[0]) > end:
                end = int(row[0])
    return [[begin, datetime.datetime.utcfromtimestamp(begin).strftime('%Y-%m-%d %H:%M:%S')],
            [end, datetime.datetime.utcfromtimestamp(end).strftime('%Y-%m-%d %H:%M:%S')]]


def find_most(df, key_col, value_col, n):
    delay_dict = {}
    for row in df.index:
        if df[value_col][row] != 0:
            key = df[key_col][row]
            value = df[value_col][row]
            if key in delay_dict:
                delay_dict[key] = delay_dict[key] + value
            else:
                delay_dict[key] = value
    # looking for top n. if n is bigger than list size, return full list
    if len(delay_dict.items()) < n:
        return sorted(delay_dict.items(), key=lambda x: x[1], reverse=True)
    return sorted(delay_dict.items(), key=lambda x: x[1], reverse=True)[:n]


def find_late_departures(df, i):
    return [[x[0], x[1] / 60] for x in find_most(df, 'stationName', 'delay', i)]


def find_late_arrivals(df, i):
    return [[x[0], x[1] / 60] for x in find_most(df, 'destName', 'delay', i)]


def find_late_trains(df, i):
    return [[x[0], x[1] / 60] for x in find_most(df, 'vehicleName', 'delay', i)]


def find_most_cancels_station(df, i):
    return find_most(df, 'stationName', 'canceled', i)

def find_most_cancels_train(df, i):
    return find_most(df, 'vehicleName', 'canceled', i)


def make_plot(arr, title, yax, xax, filename):
    # check if list contains elements
    if len(arr) == 0:
        return None

    # set params for plot
    left = [i + 1 for i in range(len(arr))]
    height = [float(x[1]) for x in arr]
    tick_label = [x[0] for x in arr]

    plt.bar(left, height, tick_label=tick_label,
            width=0.8, color=['pink', 'lightblue', 'lightgreen', 'orange', 'hotpink'])

    plt.xlabel(xax)
    plt.ylabel(yax)
    plt.title('Top ' + str(len(arr)) + ' ' + title)

    plt.gcf().set_size_inches(len(arr) + 2, 10)
    plt.gcf().autofmt_xdate()

    # save plot in plots directory
    img_dir = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/plots/'
    path = ''.join([img_dir, 'top', str(len(arr)), '_', filename])
    plt.savefig(path)
    plt.clf()


def main():
    # remove pre existing directory with plots to create new ones
    img_dir = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/plots/'
    if os.path.isdir(img_dir):
        shutil.rmtree(img_dir)
    # make the plot dir
    os.mkdir(img_dir)

    # get the data from csv file and remove duplicate lines
    # even though every observation is on a new line, it's possible that we ask a liveboard multiple times for the same train
    # in that case, the delay, cancelation, platfrom etc might be updated, We only want to look at the most recent status we got from a train
    data_path = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/transformed_data/transformed.csv'

    df = pd.read_csv(data_path, delimiter=';', header=0)
    df.drop_duplicates(subset=['timestamp', 'stationId', 'destId', 'departureTime', 'vehicleName'], keep='last',
                       inplace=True)

    # generate statistics of the data
    make_plot(find_late_departures(df, 10), 'Stations with Late Departure Time', 'Total Amount of Minutes of Delay', 'Station Name', 'late_departures')
    make_plot(find_late_arrivals(df, 10), 'Stations with Late Arrival Time', 'Total Amount of Minutes of Delay', 'Station Name', 'late_arrivals')
    make_plot(find_late_trains(df, 10), 'Trains with Late Arrival Time', 'Total Amount of Minutes of Delay', 'Train Name', 'late_trains')
    make_plot(find_most_cancels_station(df, 10), 'Stations with Highest Amount of Canceled Trains', 'Amount of Cancelations', 'Station Name',
              'cancelations_at_departure')
    make_plot(find_most_cancels_train(df, 10), 'Trains That Have Most Often Been Canceled', 'Amount of cancelations',
              'Vehicle Name',
              'train_cancelations')

if __name__ == "__main__":
    main()
