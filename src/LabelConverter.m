function CellArrayOut=LabelConverter(arrayIn)
for i=1:size(arrayIn,1)
    CellArrayOut{i}=num2str(arrayIn(i));
end