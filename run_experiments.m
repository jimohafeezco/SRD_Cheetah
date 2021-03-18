% sigma is standard deviation of the distribution we are sampling from
sigmas= [0.0001, 0.001, 0.01, 0.1];

% n_sample is size of distribution== number of experiments with different
% start point

n_sample=2;

result =zeros(4,length(sigmas),2);

xx_cost = zeros(4,length(sigmas));
uu_cost = zeros(4,length(sigmas));


for i=1:length(sigmas)    
    [xx_cost(1,i),uu_cost(1,i)]=Table_Simulation("vaniila_dynamics","ctc",sigmas(1),n_sample);
    [xx_cost(2,i),uu_cost(2,i)]=Table_Simulation("qr_decomposed","ctc",sigmas(i),n_sample);
%     [xx_cost(3,i),uu_cost(3,i)]=Table_Simulation("vaniila_dynamics","clqr",sigmas(i),n_sample);
%     [xx_cost(4,i),uu_cost(4,i)]=Table_Simulation("qr_decomposed","clqr",sigmas(i),n_sample);
end

xx_metric= array2table(xx_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
uu_metric= array2table(uu_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});

save('cheetah_experiment.mat','xx_metric','uu_metric')
