#!/usr/bin/env python

'''this script transfers video files from NAS drive to octomore'''

import glob
import os
import os.path
import numpy as np
import shutil
import settings
import function_list as ff
cg = settings.Experiment() 

nas_movie_folder = os.path.join(cg.nas_main_dir,'movie')
movie_list = ff.find_all_target_files(['*avi'],nas_movie_folder)
print(movie_list.shape)

# make folder in octomore
local_folder = os.path.join(cg.local_dir,'original_movie')
ff.make_folder([local_folder])

# copy to octomore
for m in movie_list:
    if os.path.exists(os.path.join(local_folder,os.path.basename(m))):
        print(" find %s in the destination. Skipping." % (os.path.basename(m)))
        continue
    else:
        shutil.copyfile(m,os.path.join(local_folder,os.path.basename(m)))

# check whether the transfer is completed
l = ff.find_all_target_files(['*.avi'],local_folder)
print(l.shape)
