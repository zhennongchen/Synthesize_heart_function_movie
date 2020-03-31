"""
After copying all the files using the 3_move_file, we run this one to extract
the images from the videos and also create a data file we can use
for training and testing later.
"""
import csv
import cv2
import math
import glob
import os
import os.path
from subprocess import call
import settings
import function_list as ff
cg = settings.Experiment() 

def extract_files(main_path):
    """After we have all of our videos split between train and test, and
    all nested within folders representing their classes, we need to
    make a data file that we can reference when training our RNN(s).
    This will let us keep track of image sequences and other parts
    of the training process.

    We'll first need to extract images from each of the videos. We'll
    need to record the following data in the file:

    [train|test], class, filename, nb frames

    Extracting can be done with ffmpeg:
    `ffmpeg -i video.mpg image-%04d.jpg`
    """
    data_file = []
    folders = ['train', 'test']

    # create image folder
    train_image_f = os.path.join(main_path,'train_image')
    test_image_f = os.path.join(main_path,'test_image')
    ff.make_folder([train_image_f,test_image_f])

    for folder in folders:
        class_folders = glob.glob(os.path.join(main_path,folder, '*'))
        
        for vid_class in class_folders:
           
            class_files = glob.glob(os.path.join(vid_class, '*.avi'))

            for video_path in class_files:
                # Get the parts of the file.
                
                video_parts = get_video_parts(video_path,full_length=True)

                train_or_test, classname, filename_no_ext, filename = video_parts
                print(train_or_test,classname,filename_no_ext,filename)

                # check whether the folder to save images has been created
                if not os.path.exists(os.path.join(main_path,train_or_test+'_image', classname)):
                    print("Creating folder for %s/%s" % (train_or_test+'_image', classname))
                    os.makedirs(os.path.join(main_path,train_or_test+'_image', classname))

                # Only extract if we haven't done it yet. Otherwise, just get
                # the info.

                if not check_already_extracted(video_parts,main_path):
                    #Now extract it.
                    print("%s not exist, extract"%filename)
                    src = os.path.join(main_path,train_or_test, classname, filename)

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
                                n = '000'+str(count)
                            if count >=10:
                                n = '00'+str(count)

                        dest = os.path.join(main_path,train_or_test+'_image',classname,filename_no_ext+'-'+n+'.jpg')
                        cv2.imwrite(dest,frame)
                        count += 1
                    cap.release()
                    # call(["ffmpeg", "-i", src, dest]) % this will cause some error (not extract exact 20 frames) in some avis


                
                # Now get how many frames it is.
                nb_frames = get_nb_frames_for_video(video_parts,main_path)

                data_file.append([train_or_test, classname, filename_no_ext, nb_frames])
                
                print("Generated %d frames for class %s, filename %s" % (nb_frames, classname, filename_no_ext))
                

    excel_file = os.path.join(main_path,'data_file.csv')
    with open(excel_file, 'w') as fout:
         writer = csv.writer(fout)
         writer.writerows(data_file)

    print("Extracted and wrote %d video files." % (len(data_file)))


def get_nb_frames_for_video(video_parts,main_path):
    """Given video parts of an (assumed) already extracted video, return
    the number of frames that were extracted."""
    train_or_test, classname, filename_no_ext, _ = video_parts
    generated_files = glob.glob(os.path.join(main_path,train_or_test+'_image', classname,
                                filename_no_ext + '-*.jpg'))
    return len(generated_files)

def get_video_parts(video_path,full_length=True):
    """Given a full path to a video, return its parts."""
    parts = video_path.split(os.path.sep)
    if full_length == False:
        filename = parts[2]
        filename_no_ext = filename.split('.')[0]
        classname = parts[1]
        train_or_test = parts[0]
    else:
        filename = parts[-1]
        if filename.count('.') == 2:
            filename_no_ext = filename.split('.')[0] + '.' + filename.split('.')[1].split('%')[0]
        elif filename.count('.') == 1:   # in case the EF is an integer
            filename_no_ext = filename.split('.')[0].split('%')[0]
        else:
            print('Error on dot number!!')
        classname = parts[-2]
        train_or_test = parts[-3]
    return train_or_test, classname, filename_no_ext, filename

def check_already_extracted(video_parts,main_path):
    """Check to see if we created the -0001 frame of this file."""
    train_or_test, classname, filename_no_ext, _ = video_parts
    return bool(os.path.exists(os.path.join(main_path,train_or_test+'_image', classname,
                               filename_no_ext + '-0001.jpg')))

def main():
    """
    Extract images from videos and build a new file that we
    can use as our data input file. It can have format:

    [train|test], class, filename, nb frames
    """
    main_path = os.path.join(cg.oct_main_dir)
    extract_files(main_path)

if __name__ == '__main__':
    main()
