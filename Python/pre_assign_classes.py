#!/usr/bin/env python

'''this script assigned classes to each movie, which are normal EF>=X and abnormal EF<=Y in synthetic global EF functions'''
'''It will return an excel file saving all files and their classes'''

import glob
import os
import os.path
import numpy as np
import settings
import pandas as pd
import function_list as ff
cg = settings.Experiment() 


movie_folder = os.path.join(cg.nas_main_dir,'movie')
movie_list = ff.find_all_target_files(['*.avi'],movie_folder)
print(movie_list.shape)


# save all video name + their classes into an excel file
result = []
for m in movie_list:
    parts = m.split(os.path.sep)
    full_name = parts[len(parts)-1]

    ef = float(full_name.split('_')[-1].split('%')[0])
    patient_id = full_name.split('_')[-2]
    if full_name.split('_')[1] == 'tavr':
        patient_class = full_name.split('_')[0] + '_' + full_name.split('_')[1] + '_1'
    else:
        patient_class = full_name.split('_')[0] + '_' + full_name.split('_')[1]
    
    if ef <= 40:
        n = 'abnormal'
    elif ef >= 50:
        n = 'normal'
    else:
        print('Error EF!')


    result.append([n,full_name,ef,patient_class,patient_id])


column_list = ['class','video_name','EF','patient_class','patient_id']
df = pd.DataFrame(result,columns = column_list)
df.to_excel(os.path.join(cg.nas_main_dir,'movie_list_w_classes.xlsx'),index = False)




    