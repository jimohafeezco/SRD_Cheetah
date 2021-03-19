% close all; clear classes; clc
function [xx_cost, uu_cost, time_elapsed] = Table_Simulation(dynamics,controller,s_d,n_sample, count)

InitialPosition = SRD_get('InitialPosition');

random= normrnd(0,s_d,[18,n_sample]);

InitialPositionDistribution= random+InitialPosition;

Handler_IK_Solution = SRD_get('Handler_IK_Solution');

% Handler_Time = SRDHandler_Time();
% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Handler_dynamics_generalized_coordinates_model = SRD_get('Handler_dynamics_generalized_coordinates_model');
Handler_dynamics_Linearized_Model = SRD_get('Handler_dynamics_Linearized_Model');
Handler_Constraints_Model = SRD_get('Handler_Constraints_Model');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tf = Handler_IK_Solution.TimeExpiration;
% tf = 0.2;
time_table = 0:0.02:tf;

n = Handler_dynamics_generalized_coordinates_model.dof_configuration_space_robot;

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model

tic

switch(dynamics)
    
    case  "vaniila_dynamics"
        [A_table, B_table, c_table, x_table, u_table, dx_table] = ...
        SRD_LinearModel_GenerateTable('Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
        'Handler_dynamics_Linearized_Model', Handler_dynamics_Linearized_Model, ...
        'Handler_IK_Solution', Handler_IK_Solution, ...
        'TimeTable', time_table);
    
    case "qr_decomposed"
        [A_table, B_table, c_table, x_table, u_table, dx_table] = ...
        SRD_LinearModel_GenerateTableQR('Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
        'Handler_dynamics_Linearized_Model', Handler_dynamics_Linearized_Model, ...
        'Handler_IK_Solution', Handler_IK_Solution, ...
        'Handler_Constraints_Model',Handler_Constraints_Model,...
        'TimeTable', time_table);
    
end


[N_table, G_table, F_table] = SRD_ConstraintsModel_GenerateTable(...
    'Handler_Constraints_Model', Handler_Constraints_Model, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
    'x_table', x_table, ...
    'new_dimentions', []);
% n_constrained = size(N_table, 2);

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Controllers
%
switch(controller)
    
    case "ctc"
        K_table = SRD_CTC_GenerateTable('Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
        'Handler_IK_Solution', Handler_IK_Solution, ...
        'Kp', 600*eye(n), 'Kd', 500*eye(n), 'TimeTable', time_table);
    case "clqr"  
        Q = 100*eye(2 * n);
        R = 0.01*eye(Handler_dynamics_generalized_coordinates_model.dof_control);
        Count = size(A_table, 3);
        K_table = SRD_CLQR_GenerateTable(A_table, B_table, repmat(Q, [1, 1, Count]), repmat(R, [1, 1, Count]), N_table);
end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[AA_table, cc_table] = SRD_CloseLoop_GenerateTable(A_table, B_table, c_table, K_table, x_table, u_table);

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ode_fnc_handle = SRD_get_ode_fnc_from_ClosedLoopLinearSystem(AA_table, cc_table, time_table);

ode_fnc_handle = SRD_get_ode_fnc_from_ClosedLoopConstrainedLinearSystem...
    (AA_table, cc_table, G_table, F_table, time_table);

cost_array = zeros(n_sample,2);
for i=1:n_sample
   
       InitialPosition = InitialPositionDistribution(:,i);
       
       x0 = [InitialPosition; zeros(size(InitialPosition))];
       [~, solution_tape] = ode45(ode_fnc_handle, time_table, x0);

       error = solution_tape'-x_table;

       x_cost = max(vecnorm(error'));

       uu_fd= zeros(n, size(time_table,2));
       
       for j=1: length(time_table)
           
            uu_fd(:,j)= K_table(:,:,j)* error(:,j); 
       end
       
       u_cost = max(vecnorm(uu_fd'));

       cost_array(i,:) = [x_cost, u_cost]; 
       
       if count ==2
       disp(['progress:',num2str(25+(i*100)/(n_sample*4)),'%']);           
       elseif count ==3
       disp(['progress:',num2str(50+(i*100)/(n_sample*4)),'%']);           
       elseif count ==4
       disp(['progress:',num2str(75+(i*100)/(n_sample*4)),'%']);
       else
       disp(['progress:',num2str((i*100)/(n_sample*4)),'%']);
       end
end

time_elapsed= toc;
% cost_array
xx_cost= mean(x_cost);
uu_cost= mean(u_cost);


% uu_cost
% cost_final = norm(cost,1)+norm(error,1);
% 
% figure('Color', 'w', 'Name', 'Positions');
% 
% subplot(1, 2, 1)
% SRDgraphic_PlotGeneric(time_table, solution_tape(:,1:n), ...
%     'NewFigure', false, 'FigureName', 'Generic', ...
%     'LableVariable', 'q', 'Title', ["position"]);
% 
% subplot(1, 2, 2)
% SRDgraphic_PlotGeneric(time_table, solution_tape(:,n+1:n*2), ...
%     'NewFigure', false, 'FigureName', 'Generic', ...
%     'LableVariable', 'v', 'Title', ["velocity"]);
% drawnow;


% 
% ToAnimate = false;
% LinkArray = SRD_get('LinkArray');
% Chain = SRD_Chain(LinkArray);
% %  
% SymbolicEngine = SRDSymbolicEngine('LinkArray', LinkArray, 'Casadi', true);
% SymbolicEngine.InitializeLinkArray();
% 
% 
% 
% if ToAnimate
% % figure();
% SRD__make_default_scene('Default')
% DrawRobot_function = SRD_DrawRobot_get_function('DrawRobot_Type', 'STL', ... %'Default' or 'STL' or 'Custom'
%     'DrawRobot_Custom_handle', [], ...
%     'Function_Type', 'DrawGivenPosition', ... %'DrawGivenPosition' or 'DrawInitialPosition'  or 'DrawCurrentPosition'
%     'Chain', Chain ...
%     ); %use default visualscheck ur ema 
% 
% SRD__animate__vanilla('TimeLog', time_table, ...
%     'PositionLog', solution_tape, ...
%     'AnimationTimeLog', 0:10*0.01:tf, ...
%     'DrawRobot_function', DrawRobot_function, ...
%     'NewFigure', true, ...
%     'FigureName', 'Animation', ...
%     'FileName_visuals_config', []);
% end
% 

end