function thresholds = threshold(percentage,days_percent_decay,time_step)
  time_percent_decay = days_percent_decay.*24./time_step;
  thresholds = (1-percentage/100).^(1./time_percent_decay);
end
