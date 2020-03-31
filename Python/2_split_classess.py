#!/usr/bin/env python

'''this script splits classess, which are normal EF>=70 and abnormal EF<=30 in synthetic global EF functions'''
'''It will return an excel file saving all files and their classes'''

import glob
import os
import os.path
import numpy as np
import settings
import function_list as ff
cg = settings.Experiment() 


movie_folder = os.path.join(cg.nas_main_dir,'movie')
movie_list = ff.find_all_target_files(['*.avi'],movie_folder)
print(movie_list.shape)
#np.random.shuffle(movie_list)

train_list = np.load(os.path.join(cg.nas_main_dir,'train_patient_list.npy'),allow_pickle=True)
test_list = np.load(os.path.join(cg.nas_main_dir,'test_patient_list.npy'),allow_pickle=True)
print(train_list,train_list.shape)

# save all video name + their classes into an excel file
result = ()
count = 0
for m in movie_list:
    parts = m.split(os.path.sep)
    full_name = parts[len(parts)-1]
    

    ef = float(full_name.split('_')[-1].split('%')[0])
    patient_id = full_name.split('_')[-2]
    if full_name.split('_')[1] == 'tavr':
        patient_class = full_name.split('_')[0] + '_' + full_name.split('_')[1] + '_1'
    else:
        patient_class = full_name.split('_')[0] + '_' + full_name.split('_')[1]
    
    if ef <= 30:
        n = 'abnormal'
    elif ef >= 70:
        n = 'normal'
    else:
        print('Error EF!')
    # check whether it's in train or test
    patient_name = patient_class+'_'+patient_id
    mask = np.isin(patient_name, train_list)
    if mask == True:
        group = 'train'
        
    else:
        group = 'test'
        count += 1

    result_list = [group,n,full_name,ef,patient_class,patient_id]
    result = (*result,result_list)

xlsx_path = os.path.join(cg.nas_main_dir,'movie_class_list.xlsx')
ff.xlsx_save(xlsx_path,result,[('group',1),('class',1),('video_name',1),('EF',1),('patient_class',1),('patient_id',1)],list(range(0,6)))

   
print(count)


    