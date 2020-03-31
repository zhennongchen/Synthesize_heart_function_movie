#!/usr/bin/env python

'''this script transfers files from NAS to octomore'''

import glob
import os
import os.path
import numpy as np
import shutil
import settings
import function_list as ff
cg = settings.Experiment() 

nas_movie_folder = os.path.join(cg.nas_main_dir,'movie')
movie_list = ff.find_all_target_files(['*.avi'],nas_movie_folder)


# make folder in octomore
local_folder = os.path.join(cg.oct_main_dir,'raw_movie')
ff.make_folder([local_folder])

# copy to octomore
#for m in movie_list:
    #shutil.copyfile(m,os.path.join(local_folder,os.path.basename(m)))

# check whether the transfer is completed
l = ff.find_all_target_files(['*.avi'],local_folder)
print(l.shape)
