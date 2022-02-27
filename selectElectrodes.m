function [data_electrode] = selectElectrodes(subject)

data = load(strcat('../EEGdata/',subject));

data_order = [12,9,6,13,11,7,5,3,2,1,8,4];

imp = getfield(data,'seg1','imp');
imp = imp(data_order);
imp(isnan(imp)) = 15; 
data_electrode = data_order(find(imp<10,1));    

disp(strcat("Choosen subject is: ",subject));
disp(strcat("Choosen electrode is (data): ",num2str(data_electrode)));
end