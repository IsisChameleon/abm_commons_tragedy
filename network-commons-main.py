import pandas as pd
from pathlib import Path
import csv
import matplotlib.pylab as plt
from pandas.plotting import autocorrelation_plot
from pandas.plotting import scatter_matrix

!ls
# you should see you are in the mainfolder

# global parameters related to the structure of the file
# other global variables (like 'path')

col_names_index = ['[run number]','[step]' ]
col_names_parameters = ['nb-villagers', 'LINK-TRANSMISSION-DISTANCE','min-degree', 'adaptive-harvest?',
                       'network-type', 'MIN-RSC-SAVING-PCT', 'wiring-probability',
                       'regrowth-chooser', 'INIT-HARVEST-LEVEL','DECREASE-PCT', 'INCREASE-PCT',
                       'MAX-TURTLE-BACKPACK','HFC-TICKER-MAX','HFC-TICKER-STOP','HFC-TICKER-START',
                        'PRL-TICKER-MAX','PRL-TICKER-STOP','PRL-TICKER-START','FACTOR-DIV',
                        'PERCENT-BEST-LAND','regrowth-chooser','MAX-TURTLE-VISION'
                       ]
col_names_reporters = ['total-resource-reporter','total-patch-regrowth','total-turtle-resource-reporter',
                       'total-quantity-harvested','number-of-hungry-turtles','total-wealth']
col_names_reporters_group = ['group-turtle-resource','group-turtle-wealth','group-turtle-prl',
                             'group-turtle-hfc']
col_names_useless = ['show-link?','debugging-agentset?', 'debugging-agentset-nb','color-chooser',
                     'DEBUG-RATE','DEBUG','TURTLE-PROC-CHOOSER']
experiment_name=""

path = Path()   # sets path to the current directory


#################################
# read file
# please put all your files into /data folder

filepath = path/'data'/'network-commons experiment#1.3  500 turtles BACKPACK 3-table.csv'

# read line 3 for experiment name (--> i== 2)

with open(filepath, "r") as f:
    reader = csv.reader(f, delimiter="\t")
    for i, line in enumerate(reader):
        if i == 2:
            experiment_name = line
            break


# read whole file into a pandas

df = pd.read_csv(filepath, skiprows=6, sep=',',
                usecols=lambda x: x not in col_names_useless )


df.insert(0, 'experiment_name', experiment_name[0])
df.set_index(['experiment_name']+col_names_index, append=False, inplace=True)

df.head()
#################################

print(experiment_name)

#################################

# accessing a column
df.loc[: , 'total-wealth']

df["total-wealth"]

#################################

# accessing 2 columns
df.loc[: , ['total-wealth', 'total-resource-reporter']]

df[["total-wealth", "total-resource-reporter"]]

#################################

# accessing the dataframe for a specific experiment

df.xs('experiment#1.3  500 turtles BACKPACK 3')

###########################################30
# accessing the dataframe for a specific experiment and specific run

df.xs( ('experiment#1.3  500 turtles BACKPACK 3',1) )
###################################################
# accessing the unique values of a dataframe index
# e.g. finding the distinct experiments and runs
# https://stackoverflow.com/questions/24495695/pandas-get-unique-multiindex-level-values-by-label

print(df.index.unique(level='[run number]'))

print(df.index.unique(level='experiment_name'))

for experiment in df.index.unique(level='experiment_name'):
    print("Working with experiment ", experiment)

#############################################

def process_netlogo_experiments_dataframe(df):
    for experiment in df.index.unique(level='experiment_name'):
        print("Processing experiment ", experiment)
        for run_number in df.index.unique(level='[run number]'):
            print("..processing run number ", run_number)
            sliced_df=df.xs( (experiment,run_number) )
            generate_reporters_vs_time(sliced_df, experiment, run_number)
            generate_total_resource_plot(sliced_df, experiment, run_number)
            generate_resource_exchanged_plot(sliced_df, experiment, run_number)
            generate_qty_harvested_vs_regrown_plot(sliced_df, experiment, run_number)
            generate_final_turtle_group_plots(sliced_df, experiment, run_number)



def generate_reporters_vs_time(sdf, experiment, run_number):
    for col_name in col_names_reporters:
        my_plot(sdf, col_name, experiment, run_number)


def my_plot(sdf, col_name: str, experiment: str, run_number: int):
    print('...Graph of {0} vs ticks'.format(col_name))
    sdf.plot(figsize=(15, 6), y = col_name)
    plt.show()
    plt.savefig(path/'data'/'plots'/"{0}_{1}_{2}_vs_ticks.png".format(experiment, run_number, col_name))


def generate_total_resource_plot(sdf, experiment, run_number):
    pass
def generate_resource_exchanged_plot(sdf, experiment, run_number):
    pass
def generate_qty_harvested_vs_regrown_plot(sdf, experiment, run_number):
    pass
def generate_final_turtle_group_plots(sdf, experiment, run_number):
    pass


# Calling the function to generate all sort of plots based on the csv file read

process_netlogo_experiments_dataframe(df)