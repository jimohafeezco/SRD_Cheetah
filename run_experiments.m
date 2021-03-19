

% sigma is standard deviation of the distribution we are sampling from
sigmas= [0.0001, 0.001, 0.01, 0.1];

% n_sample is the size of distribution== number of experiments with different
% initial positions

n_sample=2;

result = zeros(4,length(sigmas),2);

xx_cost = zeros(4,length(sigmas));
uu_cost = zeros(4,length(sigmas));

time= 0;

for i=1:length(sigmas)  
    
    disp(['starting experiment ',num2str(i), ' of ', num2str(length(sigmas)), ' : sigma= ', num2str(sigmas(i))])
    count=1;
    
    [xx_cost(1,i),uu_cost(1,i), time_elapsed]=Table_Simulation("vaniila_dynamics","ctc",sigmas(1),n_sample, count);
   
    xx_metric= array2table(xx_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    uu_metric= array2table(uu_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    save('cheetah_experiment.mat','xx_metric','uu_metric')
    time =time+ time_elapsed;
    disp(['time elapsed: ', num2str(time/60), ' minutes']);
    
    count=2;
    
    [xx_cost(2,i),uu_cost(2,i), time_elapsed]=Table_Simulation("qr_decomposed","ctc",sigmas(i),n_sample, count);
    
    
    xx_metric= array2table(xx_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    uu_metric= array2table(uu_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    save('cheetah_experiment.mat','xx_metric','uu_metric')
    
    time =time+ time_elapsed;
    disp(['time elapsed: ', num2str(time/60), ' minutes']);

    count=3;
    
    [xx_cost(3,i),uu_cost(3,i), time_elapsed]=Table_Simulation("vaniila_dynamics","clqr",sigmas(i),n_sample, count);
    
    xx_metric= array2table(xx_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    uu_metric= array2table(uu_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    save('cheetah_experiment.mat','xx_metric','uu_metric')
    
    time =time+ time_elapsed;
    disp(['time elapsed: ', num2str(time/60), ' minutes']);
    
    count=4;
    
    [xx_cost(4,i),uu_cost(4,i), time_elapsed]=Table_Simulation("qr_decomposed","clqr",sigmas(i),n_sample, count);
   
    disp(['end of experiment for sigma=', num2str(sigmas(i))]);
    disp(['overall progress ', num2str(i*100/length(sigmas)), ' %', ...
        'time elapsed: ', num2str(time/60), ' minutes'])
    
    xx_metric= array2table(xx_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});
    uu_metric= array2table(uu_cost', 'VariableNames', {'ctc_vanilla', 'ctc_qr','vaniila_clqr','qr_clqr'},'RowNames' , {'0.0001', '0.001','0.01', '0.1'});

    save('cheetah_experiment.mat','xx_metric','uu_metric')
end








% result=load('cheetah_experiment.mat');
% result.xx_metric
% result.uu_metric

%result sample below
%               ctc_vanilla    ctc_qr    vaniila_clqr    qr_clqr
%               ___________    ______    ____________    _______
% 
%     0.0001      32.519       33.521       11.119       11.177 
%     0.001       33.195       33.284       11.193       11.311 
%     0.01        33.227       33.972       11.175       11.294 
%     0.1         33.731       322.66       19.545       17.585 