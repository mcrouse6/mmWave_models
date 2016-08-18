import numpy as np
import pandas as pd
from sqlalchemy import create_engine


def load_pathloss(fn, exp_id):
    dat = pd.read_csv(fn,header=None, names=['id', 'x', 'y','z', 'distance', 'pathloss'], skiprows=2, delimiter=' ',
                      index_col=0)
    dat['exp_id'] = exp_id
    return dat

def to_sql(df, table):
    disk_engine = create_engine('sqlite:///ray_tracing.db')
    df.to_sql(table, disk_engine, if_exists='append')


def plot_heatmap(exp_id =1, z=1):
    df = pd.read_sql_query('SELECT * FROM rx_data WHERE exp_id = %d and z = %f' % (exp_id,z), create_engine('sqlite:///ray_tracing.db'))

    plt.figure(figsize=(20,10))
    plt.scatter(df['x'], df['y'], c=df['pathloss'])
    plt.colorbar()
    plt.xlabel('X Position')
    plt.ylabel('Y Position')
    plt.title("Exp: %d - Z: %f" % (exp_id, z))


def import_pathloss(idx):
    data_path = "../../FreeSpaceGrid/FreeSpaceRxGrid (1)/FreeSpaceGrid.pl.t001_01.r%03d.p2m" % (idx)
    dat = load_pathloss(data_path,3)
    to_sql(dat, 'rx_data')

def getRxData(exp_id, z):
    return pd.read_sql_query('SELECT * FROM rx_data WHERE exp_id = %d and z = %f' % (exp_id,z), create_engine('sqlite:///ray_tracing.db'))


def plotPathloss():
    df = getRxData(1,2)
    y = np.median(df['y'].unique())
    plt.figure()
    df_ycons = df[df['y'] == y]
    df_ycons = df_ycons.sort(['x'])
    plt.plot(df_ycons['x'], df_ycons['pathloss'], '-o')

    y = np.min(df['y'].unique())
    df_ycons = df[df['y'] == y]
    df_ycons = df_ycons.sort(['x'])
    plt.plot(df_ycons['x'], df_ycons['pathloss'], '-o')

    y = np.max(df['y'].unique())
    df_ycons = df[df['y'] == y]
    df_ycons = df_ycons.sort(['x'])
    plt.plot(df_ycons['x'], df_ycons['pathloss'], '-o')

    plt.legend(['middle', 'top', 'bottom'])
    plt.xlabel('x position (m)')
    plt.ylabel('path loss (dB)')
