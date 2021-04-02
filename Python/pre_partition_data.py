#!/usr/bin/env python

# this script partition the dataset into 5 batches. The partition is made based on patient, not each movie in this project.

import os
import numpy as np
import settings
import function_list as ff
import pandas as pd
from sklearn.model_selection import train_test_split
cg = settings.Experiment() 

np.random.seed(0)

# if no csv_file, run pre_assign_classes.py
csv_file = pd.read_excel(os.path.join(cg.nas_main_dir,'movie_list_w_classes.xlsx'))
if 'batch' in csv_file.columns:
    print('already done partition')
else:
    patient_id_list = np.unique(csv_file['patient_id'])
    patient_list = []
    for p in patient_id_list:
        d = csv_file[csv_file['patient_id'] == p].iloc[0]
        patient_list.append([d['patient_class'],p])


    np.random.shuffle(patient_list)
    a = np.array_split(patient_list,cg.num_partitions) # into 5 batches

    ff.make_folder([os.path.join(cg.nas_main_dir,'partitions')])
    for i in range(0,cg.num_partitions):
        np.save(os.path.join(cg.nas_main_dir,'partitions','batch_'+str(i)+'.npy'),a[i])


    # change the excel file
    batch_list = []
    for j in range(0,csv_file.shape[0]):
        case = csv_file.iloc[j]
        for batch in range(0,cg.num_partitions):
            if np.isin(case['patient_id'],a[batch]) == 1:
                batch_list.append([batch,case['video_name']])
    batch_df = pd.DataFrame(batch_list,columns = ['batch','video_name'])

    # merge two dataframe
    result = pd.merge(batch_df,csv_file,on="video_name")
    result.to_excel(os.path.join(cg.nas_main_dir,'movie_list_w_classes.xlsx'),index=False)





    




