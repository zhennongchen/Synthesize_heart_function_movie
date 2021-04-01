import os

class Experiment():
    
    def __init__(self):
        self.nas_main_dir = os.environ['CG_NAS_MAIN']
        self.nas_patient_dir = os.environ['CG_NAS_PATIENT']
        self.local_dir = os.environ['CG_LOCAL']