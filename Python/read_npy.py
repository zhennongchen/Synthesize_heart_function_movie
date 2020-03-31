import os.path
import settings
import function_list as ff
import numpy as np
cg = settings.Experiment() 

main_folder = os.path.join(cg.oct_main_dir)
#main_folder = "/Experiment/Documents/Video_Data/UCF101/"

a_list = ff.find_all_target_files(['*'],os.path.join(main_folder,'sequences'))

for a in a_list:
    r = np.load(a,allow_pickle = True)
    shape = r.shape
    if shape[0] != 20 or shape[1] != 2048:
        print(a,shape)
#a = np.load(os.path.join(main_folder,'sequences/ucsd_bivent_CVC1707030901_10.69-20-features.npy'),allow_pickle=True)
#print(a.shape)
