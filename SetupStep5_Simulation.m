function [mse]= SetupStep5_Simulation(parameters, control)

InitialPosition = SRD_get('InitialPosition');

Handler_State = SRD_get_handler__state('InitialPosition', InitialPosition, ...
    'InitialVelocity', zeros(size(InitialPosition)));

Handler_IK_Solution = SRD_get('Handler_IK_Solution');

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Handler_dynamics_generalized_coordinates_model = SRD_get('Handler_dynamics_generalized_coordinates_model');
Handler_dynamics_Linearized_Model = SRD_get('Handler_dynamics_Linearized_Model');


Handler_dynamics_GC_model_evaluator = SRD_get_handler__dynamics_GC_model_evaluator(...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
    'Handler_State', Handler_State, ...
    'UsePinv', true);

Handler_Constraints_Model = SRD_get('Handler_Constraints_Model');
% 
Handler_dynamics_Linear_model_evaluator = SRD_get_handler__dynamics_Linear_model_evaluator(...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_dynamics_Linearized_Model', Handler_dynamics_Linearized_Model, ...
    'Handler_State', Handler_State, ...
    'Handler_Controller', [], ...
    'ToEvaluate_c', false);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %

dt = 0.001;
tf = Handler_IK_Solution.TimeExpiration;
% tf = 0;

Handler_Simulation = SRD_get_handler__Simulation(...
    'TimeLog', 0:dt:tf);

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Handler_Desired_State = SRD_get_handler__desired_state_static(...
%     'static_q',  InitialPosition, ...
%     'dof_robot', Handler_dynamics_generalized_coordinates_model.dof_configuration_space_robot);

Handler_Desired_State = SRD_get_handler__desired_state(...
    'Handler_ControlInput', Handler_IK_Solution, ...
    'Handler_Simulation',   Handler_Simulation);

Handler_State_StateSpace = SRD_get_handler__StateConverter_GenCoord2StateSpace(...
    'Handler_State', Handler_State);

Handler_Desired_State_StateSpace = SRD_get_handler__StateConverter_GenCoord2StateSpace(...
    'Handler_State', Handler_Desired_State);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Handler_InverseDynamics = SRD_get_handler__InverseDynamics_Vanilla__desired_trajectory(...
    'Handler_ControlInput', Handler_Desired_State, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation);

Handler_InverseDynamics = SRD_get_handler__InverseDynamicsConstrained_QR(...
    'Handler_ControlInput', Handler_Desired_State, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
    'Handler_Constraints_Model', Handler_Constraints_Model, ...
    'Handler_Simulation', Handler_Simulation);

Handler_ComputedTorqueController = SRD_get_handler__ComputedTorqueController(...
    'Handler_State', Handler_State, ...
    'Handler_ControlInput', Handler_Desired_State, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation, ...
    'Handler_InverseDynamics', Handler_InverseDynamics, ...
    'Kp', parameters.Kp*eye(Handler_Desired_State.dof_robot), ...
    'Kd', parameters.Kd*eye(Handler_Desired_State.dof_robot));

Handler_NestedQP = SRD_get_handler__NestedQP(...
    'Handler_State', Handler_State, ...
    'Handler_ControlInput', Handler_Desired_State, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation, ...
    'Handler_Constraints_Model', Handler_Constraints_Model, ...
    'Handler_InnerController', Handler_ComputedTorqueController);


% Handler_LQR = SRD_get_handler__LQR_Controller(...
%     'Handler_State_StateSpace', Handler_State_StateSpace, ...
%     'Handler_ControlInput_StateSpace', Handler_Desired_State_StateSpace, ...
%     'Handler_dynamics_Linearized_Model', Handler_dynamics_Linear_model_evaluator, ...
%     'Handler_Simulation', Handler_Simulation, ...
%     'Handler_InverseDynamics', Handler_InverseDynamics, ...
%     'Q', 10*eye(Handler_dynamics_Linear_model_evaluator.dof_robot_StateSpace), ...
%     'R', 1*eye(Handler_dynamics_Linear_model_evaluator.dof_control));

Handler_LQR = SRD_get_handler__Constrained_LQR_Controller(...
    'Handler_State', Handler_State, ...
    'Handler_State_StateSpace', Handler_State_StateSpace, ...
    'Handler_Constraints_Model', Handler_Constraints_Model, ...
    'Handler_ControlInput_StateSpace', Handler_Desired_State_StateSpace, ...
    'Handler_dynamics_Linearized_Model', Handler_dynamics_Linear_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation, ...
    'Handler_InverseDynamics', Handler_InverseDynamics, ...
    'Q', 10*eye(Handler_dynamics_Linear_model_evaluator.dof_robot_StateSpace), ...
    'R', 1*eye(Handler_dynamics_Linear_model_evaluator.dof_control));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %
if control == "CTC"
    MainController = Handler_ComputedTorqueController;
elseif control == "CLQR"
    MainController = Handler_LQR;
else
    MainController = Handler_NestedQP;
end

Handler_dynamics_Linear_model_evaluator.Handler_Controller = Handler_InverseDynamics;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %


Handler_solver_Taylor = SRD_get_handler__solver_Taylor(...
    'Handler_State', Handler_State, ...
    'Handler_Controller', MainController, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation);

% Handler_solver_ODE = SRD_get_handler__solver_ODE(...
%     'Handler_State', Handler_State, ...
%     'Handler_Controller', Handler_ComputedTorqueController, ...
%     'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_generalized_coordinates_model, ...
%     'Handler_Simulation', Handler_Simulation);

Handler_solver_TaylorConstrained = SRD_get_handler__solver_TaylorConstrained(...
    'Handler_State', Handler_State, ...
    'Handler_Controller', MainController, ...
    'Handler_dynamics_generalized_coordinates_model', Handler_dynamics_GC_model_evaluator, ...
    'Handler_Simulation', Handler_Simulation, ...
    'Handler_Constraints_Model', Handler_Constraints_Model);

% %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Handler_State_Logger_vanilla = SRD_get_handler__State_Logger__vanilla(...
    'Handler_State', Handler_State, ...
    'Handler_Simulation', Handler_Simulation, ...
    'ToLogAcceleration',  false);


Handler_SimulationTickDisplay = SRD_get_handler__SimulationTickDisplay(...
    'Handler_Simulation', Handler_Simulation, ...
    'DisplayOneTickIn', 100);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %


Handler_Simulation.PreprocessingHandlersArray = {Handler_Desired_State, Handler_State_StateSpace, Handler_Desired_State_StateSpace, ...
    Handler_dynamics_GC_model_evaluator};
% Handler_Simulation.ControllerArray = {Handler_InverseDynamics, MainController};
if control == "CTC"
    Handler_Simulation.ControllerArray = {Handler_InverseDynamics, Handler_ComputedTorqueController};
elseif control == "CLQR"
    Handler_Simulation.ControllerArray = {Handler_InverseDynamics, Handler_dynamics_Linear_model_evaluator, Handler_LQR};
else
    Handler_Simulation.ControllerArray = {Handler_InverseDynamics, Handler_NestedQP};
end
% Handler_Simulation.ControllerArray = {Handler_InverseDynamics, Handler_ComputedTorqueController};
% Handler_Simulation.ControllerArray = {Handler_InverseDynamics, Handler_dynamics_Linear_model_evaluator, Handler_LQR};


% Handler_Simulation.SolverArray = {Handler_solver_Taylor};
Handler_Simulation.SolverArray = {Handler_solver_TaylorConstrained};

Handler_Simulation.LoggerArray = {Handler_State_Logger_vanilla, Handler_SimulationTickDisplay};

Handler_Simulation.Simulate();

desired = Handler_Desired_State;
output = Handler_State_Logger_vanilla;
N = length(Handler_State_Logger_vanilla.Log.q);
n_joints=Handler_Desired_State.dof_robot;
answer = zeros(n_joints,1);
for ii=1:n_joints
    answer(ii,1)=norm(output.Log.q(1:end-1,ii)-desired.q(ii));
end
mse = sum(answer)/N;

% SRD_save(Handler_State_Logger_vanilla, 'Handler_State_Logger_vanilla');
% SRD_save(Handler_Desired_State, 'Handler_Desired_State');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Color', 'w', 'Name', 'Positions');

subplot(1, 2, 1)
SRDgraphic_PlotGeneric(Handler_Simulation.TimeLog, Handler_State_Logger_vanilla.Log.q, ...
    'NewFigure', false, 'FigureName', 'Generic', ...
    'LableVariable', 'q', 'Title', []);

subplot(1, 2, 2)
SRDgraphic_PlotGeneric(Handler_Simulation.TimeLog, Handler_State_Logger_vanilla.Log.v, ...
    'NewFigure', false, 'FigureName', 'Generic', ...
    'LableVariable', 'v', 'Title', []);

drawnow;

end



