# Belgian Railway Statistics

Some information about delays and cancelations from {starttime} until {endtime}.

## Delays

### Top {n_late_dep} stations with late departures

| Station Name | Total Amount of Delay in Minutes |
| ------------ | -------------------------------- |
{table_late_dep}

<img src="../plots/{img_late_dep}" alt="late_departures" style="height:800px;"/>

### Top {n_late_arr} stations with late arrivals

| Station Name | Total Amount of Delay in Minutes |
| ------------ | -------------------------------- |
{table_late_arr}

<img src="../plots/{img_late_arr}" alt="late_arrivals" style="height:800px;"/>

### Top {n_late_tr} trains with late departures

| Train Name   | Total Amount of Delay in Minutes |
| ------------ | -------------------------------- |
{table_late_tr}

<img src="../plots/{img_late_tr}" alt="late_arrivals" style="height:800px;"/>

## Cancelations

### Top {n_can_dep} stations with cancelations at departure

| Station Name | Total Amount of Cancelations |
| ------------ | ---------------------------- |
{table_can_dep}

<img src="../plots/{img_can_dep}" alt="cancels_at_station" style="height:800px;"/>

### Top {n_can_tr} trains with cancelations

| Train Name | Total Amount of Cancelations |
| ---------- | ---------------------------- |
{table_can_tr}

<img src="../plots/{img_can_tr}" alt="cancels_at_station" style="height:800px;"/>