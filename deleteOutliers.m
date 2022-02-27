function [op_OL_removed] =  deleteOutliers(ip_OL)

op_OL_removed = ip_OL;
num_electrodes = size(ip_OL,2);

for i = 1:num_electrodes
  % Compute the median absolute difference
  % median gives really bad values
  if 0
    center_val = mean(ip_OL(:,i));
  else
    center_val = median(ip_OL(:,i));
  end
  % Compute the absolute differences.  It will be a vector.
  deviation = ip_OL(:,i) - center_val;
  absoluteDeviation = abs(deviation);
  
  % Compute the median of the absolute differences
  mad = median(absoluteDeviation);
  
  % Find outliers.  They're outliers if the absolute difference
  % is more than some factor times the mad value.
  
  %This value needs to be fine tuned. four times the mad value seems to
  %generate good plot
  sensitivityFactor = 5;  
  thresholdValue = sensitivityFactor * mad;
  
  % positive deviation outlier indices
  outlierIndexes = deviation > thresholdValue ;
  op_OL_removed(outlierIndexes,i) = center_val + thresholdValue;
  
  % negative deviation outlier indices
  outlierIndexes = deviation < -thresholdValue ;
  op_OL_removed(outlierIndexes,i) = center_val - thresholdValue;
  
  op_OL_removed_mean = mean(op_OL_removed(:,i));
  op_OL_removed(:,i) = op_OL_removed(:,i) - op_OL_removed_mean;
end
end