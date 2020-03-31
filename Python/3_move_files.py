#!/usr/bin/env python

"""
After transferring all files to octomore local, we run this to move all the movie files into
the appropriate train/test folders.

Should only run this file once!
"""
import os
import os.path
import shutil
import numpy as np
import settings
import function_list as ff
cg = settings.Experiment()



def get_train_test_lists(main_path):
    '''get train and test list by npy file'''
    test_patient_list = np.load(os.path.join(main_path,'test_patient_list.npy'),allow_pickle = True)
    train_patient_list = np.load(os.path.join(main_path,'train_patient_list.npy'),allow_pickle = True)

    test_list = []
    for p in test_patient_list:
        l = ff.find_all_target_files([p+'*'],os.path.join(main_path,'raw_movie'))
        for ll in l:
            test_list.append(ll)

    train_list = []
    for p in train_patient_list:
        l = ff.find_all_target_files([p+'*'],os.path.join(main_path,'raw_movie'))
        for ll in l:
            train_list.append(ll)

    # Set the groups in a dictionary.
    file_groups = {
        'train': train_list,
        'test': test_list
    }

    return file_groups

def copy_files(main_path,file_groups):
    
    # make main folder for train and test folder
    train_folder = os.path.join(main_path,'train')
    test_folder = os.path.join(main_path,'test')
    ff.make_folder([train_folder,test_folder])

    # Do each of our groups.
    for group, videos in file_groups.items():
        
        # Do each of our videos.
        for video in videos:
           
            # Get the parts.
            parts = video.split(os.path.sep)
            filename = parts[len(parts)-1]
            print(filename)
            ef = float(filename.split('_')[-1].split('%')[0])

            if ef <= 30:
                classname = 'abnormal'
            elif ef >= 70:
                classname = 'normal'
            else:
                print('Error EF!')

            # Check if this class exists.
            if not os.path.exists(os.path.join(main_path,group, classname)):
                print("Creating folder for %s/%s" % (group, classname))
                os.makedirs(os.path.join(main_path,group, classname))
            

            # Check if we have already moved this file, or at least that it
            # exists to move.
            if os.path.exists(os.path.join(main_path,group,classname,filename)):
                print(" find %s in the destination. Skipping." % (filename))
                continue

            if not os.path.exists(os.path.join(main_path,group,classname,filename)):
                print(" can't find %s in the destination. copy it to %s." % (filename,classname))
                # copy the file
                destination = os.path.join(main_path,group,classname,filename)
                shutil.copyfile(video,destination)
    print('done copy')
    

def main():
    """
    Go through each of our train/test text files and move the videos
    to the right place.
    """
    main_path = os.path.join(cg.oct_main_dir)
    # Get the videos in groups so we can move them.
    
    group_lists = get_train_test_lists(main_path)

    # Move the files.
    copy_files(main_path,group_lists)

if __name__ == '__main__':
    main()
