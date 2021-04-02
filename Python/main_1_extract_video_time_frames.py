#!/usr/bin/env python

# this script can extract time frame into jpg images

import csv
import cv2
import glob
import os
import pandas as pd
import math
from subprocess import call
import settings
import function_list as ff
cg = settings.Experiment() 

def extract_timeframes(main_path,movie_path,excel_file):
    """After we have all of our videos split between train and test, and
    all nested within folders representing their classes, we need to
    make a data file that we can reference when training our RNN(s).
    This will let us keep track of image sequences and other parts
    of the training process.

    We'll first need to extract images from each of the videos. We'll
    need to record the following data in the file:

    [train|test] or batch, class, filename, nb frames

    Extracting can be done with ffmpeg:
    `ffmpeg -i video.mpg image-%04d.jpg`
    """
    data =[]

    # create image folder
    image_folder = os.path.join(main_path,'images')
    ff.make_folder([image_folder])

    # find all the movies
    excel_file = pd.read_excel(excel_file)
    movie_list = excel_file['video_name']

    # extract time frames from each movie:
    for i in range(0,excel_file.shape[0]):
        case = excel_file.iloc[i]
        print(i, case['video_name'])

        # set the file name for images
        file_name = case['video_name']
        file_name_sep = file_name.split('.') # remove .avi
        file_name_no_ext = file_name_sep[0]
        if len(file_name_sep) > 1:
            for ii in range(1,len(file_name_sep)-1):
                file_name_no_ext += '.'
                file_name_no_ext += file_name_sep[ii]
        save_folder = os.path.join(image_folder,file_name_no_ext)
        ff.make_folder([save_folder])

        src = os.path.join(movie_path,file_name)
        if os.path.isfile(src) == 0:
            ValueError('no movie file')

        if os.path.isfile(os.path.join(save_folder,file_name_no_ext+'-0001.jpg')) == 0:
            cap = cv2.VideoCapture(src)
            count = 1
            frameRate = 1
            while(cap.isOpened()):
                frameId = cap.get(1) # current frame number
                ret, frame = cap.read()
                            
                if (ret != True):
                    break
                if (frameId % math.floor(frameRate) == 0):
                    if count < 10:
                        number = '000'+str(count)
                    if count >=10:
                        number = '00'+str(count)

                dest = os.path.join(save_folder,file_name_no_ext+'-'+number+'.jpg')
                cv2.imwrite(dest,frame)
                count += 1
            cap.release()
            # call(["ffmpeg", "-i", src, dest]) % this will cause some error (not extract exact 20 frames) in some avis
            
            
        # Now get how many frames it is.
        nb_frames = len(ff.find_all_target_files(['*.jpg'],save_folder))
        data.append([case['video_name'],file_name_no_ext,nb_frames])

    print('done extraction')
    data_df = pd.DataFrame(data,columns = ['video_name','video_name_no_ext','nb_frames'])
    data_file = pd.merge(excel_file,data_df,on = "video_name")
    data_file.to_excel(os.path.join(cg.nas_main_dir,'data_file.xlsx'),index=False)


def main():
    """
    Extract images from videos and build a new file that we
    can use as our data input file. It can have format:

    [train|test], class, filename, nb frames
    """
    main_path = cg.local_dir
    movie_path = os.path.join(main_path,'original_movie')
    excel_file = os.path.join(cg.nas_main_dir,'movie_list_w_classes.xlsx')
    extract_timeframes(main_path,movie_path,excel_file)

if __name__ == '__main__':
    main()
