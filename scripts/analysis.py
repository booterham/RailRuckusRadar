#!/usr/bin/env python3
import csv
import datetime
import matplotlib.ticker as mtick
import os
import shutil
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import plotly.express as px


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
                                              4)
    rel_df = rel_df.sort_values(by=[value_col + '_percentage', 'count'], ascending=False).head(n)
    rel_df[key_col] = rel_df[key_col] + ' (' + rel_df['count'].astype(str) + ")"
    rel_df = rel_df.drop(rel_df.columns[[1, 2]], axis=1)
    return rel_df


def get_count_of(df, key_col, value_col):
    df = df.dropna(subset=[value_col])
    df = df.loc[df[value_col] != 0]
    df = df[key_col].value_counts().reset_index()
    df.columns = [key_col, value_col + "_count"]
    return df


# depID;depLocX;depLocY;depName;delay;cancelled;left;isExtra;destID;destLocX;destLocY;destName;depTime;vehicleID;platformNormal;platform;occupancy

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
    return rel_get_top_n(df, 'vehicleID', 'delay', n)


def abs_find_most_cancels_station(df, i):
    return get_top_n(df, 'depName', 'canceled', i)


def rel_find_most_cancels_station(df, i):
    return rel_get_top_n(df, 'depName', 'canceled', i)


def abs_find_most_cancels_train(df, i):
    return get_top_n(df, 'vehicleID', 'canceled', i)


def rel_find_most_cancels_train(df, i):
    return rel_get_top_n(df, 'vehicleID', 'canceled', i)


def abs_find_most_extra_station(df, i):
    return get_top_n(df, 'depName', 'isExtra', i)


def rel_find_most_extra_station(df, i):
    return rel_get_top_n(df, 'depName', 'isExtra', i)


def abs_find_most_extra_train(df, i):
    return get_top_n(df, 'vehicleID', 'isExtra', i)


def rel_find_most_extra_train(df, i):
    return rel_get_top_n(df, 'vehicleID', 'isExtra', i)


def abs_find_most_busy_trains(df, i):
    return get_top_n(df, 'vehicleID', 'occupancy', i)


def find_busiest_vehicles(df, i):
    return rel_get_top_n(df, 'vehicleID', 'occupancy', i)


# heatmap

def generate_map(df):
    # Ensure we have the necessary columns
    df = df[['depName', 'depLocX', 'depLocY']]
    color_scale = [(0, 'blue'), (1, 'red')]

    # Create a copy of the DataFrame to manipulate
    df_copy = df.copy()

    # Add a count column that shows the number of occurrences of each row
    df_copy['count'] = df_copy.groupby(list(df_copy.columns)).transform('size')

    # Remove duplicate rows, keeping the count column
    df_unique = df_copy.drop_duplicates()

    # Create the scatter mapbox plot
    fig = px.scatter_mapbox(df_unique,
                            lat="depLocY",
                            lon="depLocX",
                            hover_name="depName",
                            color="count",
                            color_continuous_scale=color_scale,
                            size="count",
                            zoom=8,
                            height=700,
                            width=700)

    # Update layout
    fig.update_layout(
        mapbox_style="open-street-map",
        mapbox=dict(
            center=dict(lat=df['depLocY'].mean(), lon=df['depLocX'].mean()),
            zoom=6.5,
            style="open-street-map"
        ),
        margin={"r": 0, "t": 0, "l": 0, "b": 0},
        showlegend=True  # Optionally show legend
    )

    # Save the map
    img_dir = str(
        Path(os.path.dirname(os.path.realpath(__file__))).parent.absolute()) + '/plots/'
    img_path = ''.join([img_dir, 'full_map.png'])
    fig.write_image(img_path)


def analyse(df, plot_title, y_ax_name, x_ax_name, filename):
    # check if list contains elements
    if len(df) == 0:
        return None
    elif (df.iloc[:, 1] == 0).all():
        return None

    # set params for plot
    indices = [i + 1 for i in range(len(df))]
    column_height = df.iloc[:, 1].tolist()
    column_name = df.iloc[:, 0].tolist()

    plt.bar(indices, column_height, tick_label=column_name,
            width=0.8, color=['pink', 'lightblue', 'lightgreen', 'orange', 'hotpink'])
    plt.xlabel(x_ax_name)
    plt.ylabel(y_ax_name)
    plt.title('Top ' + str(len(df)) + ' ' + plot_title)

    plt.gcf().set_size_inches(len(df) + 2, 10)
    plt.gcf().autofmt_xdate()

    # if all values are between 0 and 1, they should be interpreted as percentages
    if df.iloc[:, 1].between(0, 1).all():
        plt.gca().yaxis.set_major_formatter(mtick.PercentFormatter(1))

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
    # pd.set_option('display.max_rows', None)  # easier to debug if we can see all rows

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

    n = 10

    # statistics, absolutely
    analyse(abs_find_late_departures(df, n), 'Stations with Late Departure Time', 'Total Amount of Delay in Minutes',
            'Station Name', 'late_departures')
    analyse(abs_find_late_arrivals(df, n), 'Stations with Late Arrival Time', 'Total Amount of Delay in Minutes',
            'Station Name', 'late_arrivals')
    analyse(abs_find_late_trains(df, n), 'Trains with Late Arrival Time', 'Total Amount of Delay in Minutes',
            'Train Name',
            'late_trains')
    analyse(abs_find_most_cancels_station(df, n), 'Stations with Highest Amount of Cancelled Trains',
            'Amount of Cancellations', 'Station Name',
            'cancellations_at_departure')
    analyse(abs_find_most_cancels_train(df, n), 'Trains That Have Most Often Been Cancelled', 'Amount of cancellations',
            'Vehicle Name',
            'train_cancellations')
    analyse(abs_find_most_extra_station(df, n), 'Stations with Highest Amount of Extra Trains',
            'Amount of Extra Trains', 'Station Name',
            'extra_stations')
    analyse(abs_find_most_extra_train(df, n), 'Trains That Have Most Often Been Extra', 'Amount of Times it was Extra',
            'Vehicle Name',
            'extra_train')

    # statistics, relatively

    analyse(rel_find_late_departures(df, n),
            'Stations with Highest Percentage of Delayed Departing Trains',
            'Percentage of Trains that were Delayed', 'Station Name', 'rel_late_departures')

    analyse(rel_find_late_arrivals(df, n), 'Stations with Highest Percentage of Delayed Arriving Trains',
            'Percentage of Trains that were Delayed', 'Station Name', 'rel_late_arrivals')

    analyse(rel_find_late_trains(df, n), 'Trains with highest Percentage of Late Departure Time',
            'Percentage of Times the Train was Delayed', 'Train ID', 'rel_late_trains')

    analyse(rel_find_most_cancels_station(df, n), 'Stations with Highest Percentage of Cancelled Departing Trains',
            'Percentage of Cancellations', 'Station Name', 'rel_cancellations_at_departure')

    analyse(rel_find_most_cancels_train(df, n), 'Trains with Highest Percentage of Cancellations at Departure',
            'Percentage of Cancellations', 'Vehicle ID', 'rel_train_cancellations')

    analyse(rel_find_most_extra_station(df, n), 'Stations with Highest Percentage of Extra Departing Trains',
            'Percentage of Cancellations', 'Station Name', 'rel_extra_station')

    analyse(rel_find_most_extra_train(df, n), 'Trains with Highest Percentage of Extra Trips',
            'Percentage of Cancellations', 'Vehicle ID', 'rel_extra_train')

    # occupancy

    analyse(find_busiest_vehicles(df, 10), 'Busiest Trains', 'Percentage of occupancy', 'Vehicle ID', 'busiest_trains')

    # testing

    generate_map(df)

    # save info about the time range
    f = open(''.join([img_dir, "dates.txt"]), "x")
    for date in find_begin_and_endtime(data_path):
        f.write(date + '\n')
    f.close()


if __name__ == "__main__":
    main()
