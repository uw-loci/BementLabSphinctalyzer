gca;
ylab=str2num(get(gca,'YTickLabel'));
set(gca,'YTickLabels',ylab.*100);
ylabel('Percent Above Background');