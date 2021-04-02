#!/usr/bin/env python

"""
Validate our RNN. Basically just runs a validation generator on
about the same number of videos as we have in our test set.
"""
from keras.callbacks import TensorBoard, ModelCheckpoint, CSVLogger
from util_models import ResearchModels
from util_data import DataSet
import argparse
import pandas as pd
import os
import settings
import numpy as np
import function_list as ff
cg = settings.Experiment() 


def validate(data_type, batch, model,learning_rate,learning_decay,seq_length, saved_model=None,
             class_limit=None, image_shape=None):
    
    # Get the data and process it.
    if image_shape is None:
        data = DataSet(
            validation_batch = batch,
            seq_length=seq_length,
            class_limit=class_limit
        )
    else:
        data = DataSet(
            validation_batch = batch,
            seq_length=seq_length,
            class_limit=class_limit,
            image_shape=image_shape
        )

    if model == 'lstm_regression':
        regression = 1
        sequence_len = 2 
    else:
        regression = 0
        sequence_len = seq_length
    

    _,test_data = data.split_train_test()
    rm = ResearchModels(len(data.classes), model, sequence_len, learning_rate,learning_decay,saved_model)

    final_result_list = []
    for sample in test_data:
        movie_id = sample['video_name']
    
        p_generator = data.predict_generator(sample, data_type,regression)
        predict_output = rm.model.predict_generator(generator=p_generator,steps = 1)
        print(predict_output)

        if regression == 0:  
            if sample['class'] == 'normal':
                truth = 0
            else:
                truth = 1
            if np.argmax(predict_output[0]) == 1: # abnormal = [1,0], normal = [0,1]
                predict = 0
            else:
                predict = 1
        else:
            truth = float(sample['EF'])
            predict = predict_output[0][0]

        
        final_result_list.append([movie_id,truth,predict])
    
    df = pd.DataFrame(final_result_list,columns = ['video_name','truth','predict'])
    save_folder = os.path.join(cg.nas_main_dir,'results')
    ff.make_folder([save_folder])
    df.to_excel(os.path.join(save_folder,model+'-batch'+str(batch)+'-validation.xlsx'),index=False)
    
        
         
    
def main(batch):
    model = 'lstm'
    epoch = '108'
    saved_model = os.path.join(cg.nas_main_dir,'models',model,'batch_'+str(batch), model+'-batch'+str(batch)+'-'+epoch+'.hdf5')
    seq_len = 20
    learning_rate = 1e-4
    learning_decay = 1e-5

    if model == 'conv_3d' or model == 'lrcn':
        data_type = 'images'
        image_shape = (80, 80, 3)
    else:
        data_type = 'features'
        image_shape = None

    validate(data_type, batch, model, learning_rate,learning_decay, seq_length = seq_len,saved_model=saved_model,
             image_shape=image_shape, class_limit=None)

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument('--batch', type=int)
  args = parser.parse_args()

  if args.batch is not None:
    assert(0 <= args.batch < cg.num_partitions)

  main(args.batch)