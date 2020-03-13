function [p_class,p_id] = find_patient(patient_list,patient_class,patient_num)

class = patient_list(:,1);
patient_list_in_class = patient_list(class == patient_class,:);
p = patient_list_in_class(patient_num,:);
p_class = convertStringsToChars(p(1));
p_id = convertStringsToChars(p(2));
