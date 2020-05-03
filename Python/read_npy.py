import os.path
import settings
import function_list as ff
import numpy as np
cg = settings.Experiment() 

main_folder = os.path.join(cg.oct_main_dir)
#main_folder = "/Experiment/Documents/Video_Data/UCF101/"

a_list = ff.find_all_target_files(['*'],os.path.join(main_folder,'sequences'))

# for a in a_list:
#     r = np.load(a,allow_pickle = True)
#     shape = r.shape
#     if shape[0] != 20 or shape[1] != 2048:
#         print(a,shape)

for a in a_list:
    r = np.load(a,allow_pickle = True)
    shape = r.shape
    a1 = r[0]
    a2 = r[9]
    aa = np.concatenate((a1,a2)).reshape(2,a1.shape[0])
    print(aa.shape)

    break
