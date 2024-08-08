#!/usr/bin/env python3
import csv
import datetime
import math

import matplotlib.pyplot as plt
import os
import shutil
from pathlib import Path
import pandas as pd


def find_begin_and_endtime(data_path):
    with open(data_path) as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')
        next(csv_reader)  # skip header
        values = [int(row[12]) for row in csv_reader if row[12]]
        begintime = datetime.datetime.fromtimestamp(min(values), datetime.UTC).__str__().replace('+00:00', '')
        endtime = datetime.datetime.fromtimestamp(max(values), datetime.UTC).__str__().replace('+00:00', '')
        return [begintime, endtime]


def get_top_n(df, key_col, value_col, n):
    return df.groupby(key_col, as_index=False)[value_col].sum().sort_values(by=value_col, ascending=False).head(n)


def rel_get_top_n(df, key_col, value_col, n):
    df_dropped_na = df.dropna(subset=['destID'])
    df_grouped_dep = df_dropped_na.groupby(key_col, as_index=False)[key_col].value_counts()
    count_df = pd.merge(df, df_grouped_dep, on=key_col)[
        [key_col, 'count']].drop_duplicates()
    late_dep = get_count_of(df, key_col, value_col)
    rel_df = pd.merge(late_dep, count_df, how='left', on=key_col)
    rel_df[value_col + '_percentage'] = round(rel_df[value_col + '_count'] / rel_df['count'],
                                              2)
    rel_df = rel_df.sort_values(by=[value_col + '_percentage', 'count'], ascending=False).head(n)
    return rel_df


def get_count_of(df, key_col, value_col):
    df = df.dropna(subset=[value_col])
    df = df.loc[df[value_col] != 0]
    df = df[key_col].value_counts().reset_index()
    df.columns = [key_col, value_col + "_count"]
    return df


# depID;depLocX;depLocY;depName;delay;canceled;left;isExtra;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy

def abs_find_late_departures(df, i):
    top_n_late_departures = get_top_n(df, 'depName', 'delay', i)
    top_n_late_departures['delay'] = top_n_late_departures['delay'] / 60
    return top_n_late_departures


def rel_find_late_departures(df, n):
    return rel_get_top_n(df, 'depName', 'delay', n)


def abs_find_late_arrivals(df, i):
    top_n_late_arrivals = get_top_n(df, 'destName', 'delay', i)
    top_n_late_arrivals['delay'] = top_n_late_arrivals['delay'] / 60
    return top_n_late_arrivals


def rel_find_late_arrivals(df, n):
    return rel_get_top_n(df, 'destName', 'delay', n)


def abs_find_late_trains(df, i):
    top_n_late_arrivals = get_top_n(df, 'vehicleID', 'delay', i)
    top_n_late_arrivals['delay'] = top_n_late_arrivals['delay'] / 60
    return top_n_late_arrivals


def rel_find_late_trains(df, n):
    rel_get_top_n(df, 'vehicleID', 'delay', n)


def abs_find_most_cancels_station(df, i):
    return get_top_n(df, 'depName', 'canceled', i)


def rel_find_most_cancels_station(df, i):
    return rel_get_top_n(df, 'depName', 'canceled', i)


def abs_find_most_cancels_train(df, i):
    return get_top_n(df, 'vehicleID', 'canceled', i)


def rel_find_most_cancels_train(df, i):
    return rel_get_top_n(df, 'vehicleID', 'canceled', i)


def abs_find_most_busy_trains(df, i):
    return get_top_n(df, 'vehicleID', 'occupancy', i)


def analyse(df, title, yax, xax, filename):
    # check if list contains elements
    if len(df) == 0:
        return None

    # set params for plot
    indices = [i + 1 for i in range(len(df))]
    column_height = df.iloc[:, 1].tolist()
    column_name = df.iloc[:, 0].tolist()

    plt.bar(indices, column_height, tick_label=column_name,
            width=0.8, color=['pink', 'lightblue', 'lightgreen', 'orange', 'hotpink'])

    plt.xlabel(xax)
    plt.ylabel(yax)
    plt.title('Top ' + str(len(df)) + ' ' + title)

    plt.gcf().set_size_inches(len(df) + 2, 10)
    plt.gcf().autofmt_xdate()

    # save plot in plots directory
    img_dir = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/plots/'
    img_path = ''.join([img_dir, 'top', str(len(df)), '_', filename])
    plt.savefig(img_path)
    plt.clf()

    # write the info to a csv
    file_path = ''.join([img_dir, 'top', str(len(df)), '_', filename, '.csv'])
    f = open(file_path, "x")
    csv_info = [[column_name[i], column_height[i]] for i in range(len(df))]
    for i in csv_info:
        f.write(str(i) + "\n")
    f.close()


def main():
    pd.set_option('display.max_columns', None)  # easier to debug if we can see all columns
    pd.set_option('display.max_rows', None)  # easier to debug if we can see all rows

    # remove pre-existing directory with plots to create new ones
    img_dir = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/plots/'
    if os.path.isdir(img_dir):
        shutil.rmtree(img_dir)
    # make the plot dir
    os.mkdir(img_dir)

    # get the data from csv file and remove duplicate lines even though every observation is on a new line,
    # it's possible that we ask a live board multiple times for the same train in that case, the delay, cancellation,
    # platform, etc. might be updated, We only want to look at the most recent status we got from a train
    data_path = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/transformed_data/transformed.csv'

    df = pd.read_csv(data_path, delimiter=';', header=0, index_col=False)
    df.drop_duplicates(subset=['depID', 'depName', 'destID', 'depTime'], keep='last',
                       inplace=True)

    # statistics, absolutely
    analyse(abs_find_late_departures(df, 10), 'Stations with Late Departure Time', 'Total Amount of Delay in Minutes',
            'Station Name', 'late_departures')
    analyse(abs_find_late_arrivals(df, 10), 'Stations with Late Arrival Time', 'Total Amount of Delay in Minutes',
            'Station Name', 'late_arrivals')
    analyse(abs_find_late_trains(df, 10), 'Trains with Late Arrival Time', 'Total Amount of Delay in Minutes',
            'Train Name',
            'late_trains')
    analyse(abs_find_most_cancels_station(df, 10), 'Stations with Highest Amount of Canceled Trains',
            'Amount of Cancellations', 'Station Name',
            'cancellations_at_departure')
    analyse(abs_find_most_cancels_train(df, 10), 'Trains That Have Most Often Been Canceled', 'Amount of cancellations',
            'Vehicle Name',
            'train_cancellations')

    # statistics, relatively

    rel_find_late_departures(df, 10)

    rel_find_late_arrivals(df, 10)

    rel_find_late_trains(df, 10)

    rel_find_most_cancels_station(df, 10)

    rel_find_most_cancels_train(df, 10)

    # testing some stuff

    print(rel_get_top_n(df, 'vehicleID', 'occupancy', 10))

    # save info about the time range
    f = open(''.join([img_dir, "dates.txt"]), "x")
    for date in find_begin_and_endtime(data_path):
        f.write(date + '\n')
    f.close()


if __name__ == "__main__":
    main()
