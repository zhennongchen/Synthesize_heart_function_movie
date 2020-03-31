"""
Train our RNN on extracted features or images.
"""
from keras.callbacks import TensorBoard, ModelCheckpoint, EarlyStopping, CSVLogger
from models import ResearchModels
from data import DataSet
import time
import os.path
import os
import settings
import function_list as ff
cg = settings.Experiment() 
main_folder = os.path.join(cg.oct_main_dir)

# calculate the number of training data
data = DataSet(seq_length = 20,class_limit = None)
training_num = 0
for d in data.data:
    if d[0] == 'train':
        training_num += 1



def train(data_type, seq_length, model, saved_model=None,
          class_limit=None, image_shape=None,
          load_to_memory=False, batch_size=32, nb_epoch=100):
    print('trainig_num is ', training_num)
    # Helper: Save the model.
    checkpointer = ModelCheckpoint(
        filepath=os.path.join(main_folder, 'checkpoints',model, model + '-{epoch:03d}.hdf5'),
        #filepath=os.path.join(main_folder, 'checkpoints',model, model + '-' + data_type + \
            #'.{epoch:03d}-{val_loss:.3f}.hdf5'),
        monitor='val_acc',
        verbose=1,
        save_best_only=True)

    # # Helper: TensorBoard
    # tb = TensorBoard(log_dir=os.path.join('data', 'logs', model))

    # # Helper: Stop when we stop learning.
    # early_stopper = EarlyStopping(patience=5)

    # Helper: Save results.
    #timestamp = time.time()
    csv_logger = CSVLogger(os.path.join(main_folder, 'logs', model + '-' + 'training-log' + '.csv'))

    # Get the data and process it.
    if image_shape is None:
        data = DataSet(
            seq_length=seq_length,
            class_limit=class_limit
        )
    else:
        data = DataSet(
            seq_length=seq_length,
            class_limit=class_limit,
            image_shape=image_shape
        )

    # Get samples per epoch.
    # Multiply by 0.7 to attempt to guess how much of data.data is the train set.
    #steps_per_epoch = (len(data.data) * 0.7) // batch_size
    steps_per_epoch = training_num // batch_size
    print('step is: %d'%steps_per_epoch)

    if load_to_memory:
        # Get data.
        X, y = data.get_all_sequences_in_memory('train', data_type)
        X_test, y_test = data.get_all_sequences_in_memory('test', data_type)
    else:
       
        # Get generators.
        generator = data.frame_generator(batch_size, 'train', data_type)
        val_generator = data.frame_generator(batch_size, 'test', data_type)

    # Get the model.
    rm = ResearchModels(len(data.classes), model, seq_length, saved_model)

    # Fit!
    if load_to_memory:
        # Use standard fit.
        hist = rm.model.fit(
            X,
            y,
            batch_size=batch_size,
            validation_data=(X_test, y_test),
            verbose=1,
            callbacks=[csv_logger],
            epochs=nb_epoch)
    else:
        # Use fit generator.
        
        hist = rm.model.fit_generator(
            generator=generator,
            steps_per_epoch=steps_per_epoch, # in each epoch all the training data are evaluated
            epochs=nb_epoch,
            verbose=1,
            callbacks=[csv_logger, checkpointer],
            validation_data=val_generator,
            validation_steps=40,
            workers=4) # if you see that GPU is idling and waiting for batches, try to increase the amout of workers
    return hist

def main():
    """These are the main training settings. Set each before running
    this file."""
    # model can be one of lstm, lrcn, mlp, conv_3d, c3d
    model = 'lstm'
    saved_model = None  # None or weights file
    class_limit = None  # int, can be 1-101 or None
    seq_length = 20
    load_to_memory = False  # pre-load the sequences into memory
    batch_size = 32
    nb_epoch = 100

    folder_name = os.path.join(main_folder,'checkpoints',model)
    os.makedirs(folder_name,exist_ok=True)

    # Chose images or features and image shape based on network.
    if model in ['conv_3d', 'c3d', 'lrcn']:
        data_type = 'images'
        image_shape = (80, 80, 3)
    elif model in ['lstm', 'mlp']:
        data_type = 'features'
        image_shape = None
    else:
        raise ValueError("Invalid model. See train.py for options.")
    
    print('start_to_train')
    hist = train(data_type, seq_length, model, saved_model=saved_model,
          class_limit=class_limit, image_shape=image_shape,
          load_to_memory=load_to_memory, batch_size=batch_size, nb_epoch=nb_epoch)
    

if __name__ == '__main__':
    main()
