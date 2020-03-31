"""
Train on images split into directories. This assumes we've split
our videos into frames and moved them to their respective folders.

Based on:
https://keras.io/preprocessing/image/
and
https://keras.io/applications/
"""
import argparse
import numpy as np
import os
from keras.applications.inception_v3 import InceptionV3
from keras.optimizers import SGD    # Stochastic gradient descent: use 1 example for gradient descent in each iteration
from keras.preprocessing.image import ImageDataGenerator
from keras.models import Model
from keras.layers import Dense, GlobalAveragePooling2D
from keras.callbacks import ModelCheckpoint, TensorBoard, EarlyStopping,CSVLogger
from data import DataSet
import os.path
import settings
import function_list as ff
cg = settings.Experiment() 

data = DataSet()
main_folder = os.path.join(cg.oct_main_dir,'UCF101')

os.makedirs(os.path.join(main_folder,'checkpoints','inception'),exist_ok=True)
model_name = 'inception'
# Helper: Save the model.
checkpointer = ModelCheckpoint(
    filepath=os.path.join(main_folder, 'checkpoints', model_name,model_name+'.hdf5'),
    monitor='val_loss',
    verbose=1,
    save_best_only=True)

# Helper: save the log
csv_logger = CSVLogger(os.path.join(main_folder, 'logs', model_name + '-' + 'training-log' + '.csv'))

# Helper: Stop when we stop learning.
#early_stopper = EarlyStopping(patience=10)

# Helper: TensorBoard
#tensorboard = TensorBoard(log_dir=os.path.join('data', 'logs'))

def get_generators():
    ''' look at the tutorial about imagedatagenerator.flow_from_directory: https://medium.com/@vijayabhaskar96/tutorial-image-classification-with-keras-flow-from-directory-and-generators-95f75ebe5720'''
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        shear_range=0.2,
        horizontal_flip=True,
        rotation_range=10.,
        width_shift_range=0.2,
        height_shift_range=0.2)

    test_datagen = ImageDataGenerator(rescale=1./255)

    train_generator = train_datagen.flow_from_directory(
        os.path.join(main_folder, 'train_image'),
        target_size=(299, 299), # the size of my input images, every image will be resized to this size
        color_mode = 'rgb', # if black and white than set to "greyscale"
        batch_size=32,
        classes=data.classes,
        class_mode='categorical')

    validation_generator = test_datagen.flow_from_directory(
        os.path.join(main_folder,'test_image'),
        target_size=(299, 299),
        batch_size=32,
        color_mode = 'rgb',
        classes=data.classes,
        class_mode='categorical')

    return train_generator, validation_generator

def get_model(weights='imagenet'):
    # create the base pre-trained model
    base_model = InceptionV3(weights=weights, include_top=False)

    # add a global spatial average pooling layer
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    # let's add a fully-connected layer
    x = Dense(1024, activation='relu')(x)
    # and a logistic layer
    predictions = Dense(len(data.classes), activation='softmax')(x)

    # this is the model we will train
    model = Model(inputs=base_model.input, outputs=predictions)
    return model

def freeze_all_but_top(model):
    """Used to train just the top layers of the model, which are layers we add (one fully-connected layer and aone logistic layer)"""
    # first: train only the top layers (which were randomly initialized)
    # i.e. freeze all convolutional InceptionV3 layers
    for layer in model.layers[:-2]:
        layer.trainable = False

    # compile the model (should be done *after* setting layers to non-trainable)
    model.compile(optimizer='rmsprop', loss='categorical_crossentropy', metrics=['accuracy'])

    return model

def freeze_all_but_mid_and_top(model):
    """After we fine-tune the dense layers, train deeper. 
        total layer number = 313"""
    # we chose to train the top 2 inception blocks, i.e. we will freeze
    # the first 172 layers and unfreeze the rest:
    for layer in model.layers[:172]:
        layer.trainable = False
    for layer in model.layers[172:]:
        layer.trainable = True

    # we need to recompile the model for these modifications to take effect
    # we use SGD with a low learning rate
    model.compile(
        optimizer=SGD(lr=0.0001, momentum=0.9), # 0.9 is a default momentum used in SGD
        loss='categorical_crossentropy',
        metrics=['accuracy', 'top_k_categorical_accuracy'])

    return model

def train_model(model, nb_epoch, generators, callbacks=[]):
    train_generator, validation_generator = generators
    hist = model.fit_generator(
        train_generator,
        steps_per_epoch=100,
        validation_data=validation_generator,
        validation_steps=10,
        epochs=nb_epoch,
        callbacks=callbacks)
    
    return model,hist

def main(weights_file):
    model = get_model()
    generators = get_generators()

    if weights_file is None:
        print("Loading network from ImageNet weights.")
        # Get and train the top layers.
        model = freeze_all_but_top(model)
        model,_ = train_model(model, 10, generators)
    else:
        print("Loading saved model: %s." % weights_file)
        model.load_weights(weights_file)

    # Get and train the mid layers.
    model = freeze_all_but_mid_and_top(model)
    model,hist = train_model(model,200,generators,[checkpointer,csv_logger])
    
    # # save history of training
    # train_acc_list = np.asarray(hist.history['acc'])
    # train_top_acc_list = np.asarray(hist.history['top_k_categorical_accuracy'])
    # val_acc_list = np.asarray(hist.history['val_acc'])
    # val_top_acc_list = np.asarray(hist.history['val_top_k_categorical_accuracy'])
    # val_loss_list = np.asarray(hist.history['val_loss'])

    # np.save(os.path.join(main_folder,'checkpoints','inception',model_name+'_train_acc'),train_acc_list)
    # np.save(os.path.join(main_folder,'checkpoints','inception',model_name+'_train_top_5_acc'),train_top_acc_list)
    # np.save(os.path.join(main_folder,'checkpoints','inception',model_name+'_val_acc'),val_acc_list)
    # np.save(os.path.join(main_folder,'checkpoints','inception',model_name+'_val_top_5_acc'),val_top_acc_list)
    # np.save(os.path.join(main_folder,'checkpoints','inception',model_name+'_val_loss'),val_loss_list)
  

if __name__ == '__main__':
    weights_file = None
    main(weights_file)

    
