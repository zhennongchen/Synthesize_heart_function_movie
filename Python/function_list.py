import os
import glob as gb
import glob
import numpy as np
import xlsxwriter as xl
import string

# function: find all files under the name * in the main folder, put them into a file list
def find_all_target_files(target_file_name,main_folder):
    F = np.array([])
    for i in target_file_name:
        f = np.array(sorted(gb.glob(os.path.join(main_folder, os.path.normpath(i)))))
        F = np.concatenate((F,f))
    return F

def make_folder(folder_list):
    for i in folder_list:
        os.makedirs(i,exist_ok = True)

# function: excel write
def xlsx_save(filepath,result,par,index_of_par):
    '''par is parameter list such as [('Patient_Class',1),('Patient_ID',1),('Assignment',1)]'''
    workbook = xl.Workbook(filepath)
    sheet = workbook.add_worksheet()
    letter = string.ascii_uppercase

    k = 0
    for i in range(0,len(index_of_par)):
        index = index_of_par[i]
        L = letter[k] + '1'
        P = par[index][0]
        sheet.write(L,P)
        k = k + par[index][1]

    row = 1
    col = 0
    for result_list in result:
        kk = 0
        for i in range(0,len(index_of_par)):
            index = index_of_par[i]
            content = result_list[i]
            if par[index][1] == 1:
                sheet.write(row, col + kk, content)
            else:
                sheet.write_row(row, col + kk, content)
            kk = kk + par[index][1]
        row = row + 1
    workbook.close()