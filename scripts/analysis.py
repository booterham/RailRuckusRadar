#!/usr/bin/env python3
import csv
import datetime
import matplotlib.pyplot as plt
import os
import shutil


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


def find_most(name, val, i):
    with open('../transformed_data/transformed.csv') as csvfile:
        csv_reader = csv.reader(csvfile, delimiter=';')
        delay_dict = {}
        next(csv_reader)  # skip header
        for row in csv_reader:
            if row[val] != "0":
                if row[name] in delay_dict:
                    delay_dict[row[name]] = delay_dict[row[name]] + int(row[val])
                else:
                    delay_dict[row[name]] = int(row[val])
    # looking for top n. if n is bigger than list size, return full list
    if len(delay_dict.items()) < i:
        return sorted(delay_dict.items(), key=lambda x: x[1], reverse=True)
    return sorted(delay_dict.items(), key=lambda x: x[1], reverse=True)[:i]


def find_late_departures(i):
    return [[x[0], x[1] / 60] for x in find_most(2, 4, i)]


def find_late_arrivals(i):
    return [[x[0], x[1] / 60] for x in find_most(9, 4, i)]


def find_late_trains(i):
    return [[x[0], x[1] / 60] for x in find_most(11, 4, i)]


def find_most_cancels(i):
    return find_most(2, 5, 10)


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

    plt.gcf().set_size_inches(len(arr), 10)
    plt.gcf().autofmt_xdate()

    # save plot in plots directory
    path = ''.join(['../plots/', 'top', str(len(arr)), '_', filename])
    plt.savefig(path)
    plt.clf()


def main():
    # remove pre existing directory with plots to create new ones
    if os.path.isdir('../plots/'):
        shutil.rmtree('../plots/')
    # make the plot dir
    os.mkdir('../plots/')
    # generate statistics of the data
    make_plot(find_late_departures(10), 'Late Departures', 'Minutes of delay', 'Station', 'late_departures')
    make_plot(find_late_arrivals(10), 'Late Arrivals', 'Minutes of delay', 'Station', 'late_arrivals')
    make_plot(find_late_trains(10), 'Late Trains', 'Minutes of delay', 'Train', 'late_trains')
    make_plot(find_most_cancels(10), 'Stations with most canceled trains', 'Amount of cancelations', 'Station',
              'most_cancelations')


if __name__ == "__main__":
    main()
