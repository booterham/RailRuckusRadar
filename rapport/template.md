# Belgian Railway Statistics

Some information about delays and cancellations from {starttime} until {endtime} generated on {curtime}.

## Density map of all departures per station

![](../plots/full_map.png)

## Delays

### Absolute

#### Top {n_late_dep} stations with late departures

{lorem}

| Station Name | Total Amount of Delay in Minutes |
| ------------ | -------------------------------- |
{table_late_dep}

![](../plots/{img_late_dep})

#### Top {n_late_arr} stations with late arrivals

{lorem}

| Station Name | Total Amount of Delay in Minutes |
| ------------ | -------------------------------- |
{table_late_arr}

![](../plots/{img_late_arr})

#### Top {n_late_tr} trains with late departures

{lorem}

| Train Name | Total Amount of Delay in Minutes |
| ---------- | -------------------------------- |
{table_late_tr}

![](../plots/{img_late_tr})

### Relative

#### Top {n_rel_late_dep} stations with late departures compared to amount of departing trains

{lorem}

| Station Name | Percentage of Trains that were Delayed |
| ------------ | -------------------------------------- |
{table_rel_late_dep}

![](../plots/{img_rel_late_dep})

#### Top {n_rel_late_arr} stations with late arrivals compared to amount of arriving trains

{lorem}

| Station Name | Percentage of Trains that were Delayed |
| ------------ | -------------------------------------- |
{table_rel_late_arr}

![](../plots/{img_rel_late_arr})

#### Top {n_rel_late_tr} trains with late departures

{lorem}

| Train Name | Percentage of Trips on which the Train was Delayed |
| ---------- | -------------------------------------------------- |
{table_rel_late_tr}

![](../plots/{img_rel_late_tr})

## Cancellations

### Absolute

#### Top {n_can_dep} stations with cancellations at departure

{lorem}

| Station Name | Total Amount of Cancellations |
| ------------ | ----------------------------- |
{table_can_dep}

![](../plots/{img_can_dep})

#### Top {n_can_tr} trains with cancellations

{lorem}

| Train Name | Total Amount of Cancellations |
| ---------- | ----------------------------- |
{table_can_tr}

![](../plots/{img_can_tr})

### Relative

#### Top {n_rel_can_dep} stations with cancellations at departure

{lorem}

| Station Name | Percentage of Trains that were Cancelled |
| ------------ | ---------------------------------------- |
{table_rel_can_dep}

![](../plots/{img_rel_can_dep})

#### Top {n_rel_can_tr} trains with cancellations

{lorem}

| Train Name | Percentage of Trips that were Cancelled |
| ---------- | --------------------------------------- |
{table_rel_can_tr}

![](../plots/{img_rel_can_tr})
