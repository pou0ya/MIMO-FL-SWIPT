%DOCUMENT filename="main.m"
%=======================================================================
% Energy-Efficient Federated Learning for IoT Networks 
% With massive MIMO-Enabled SWIPT - MAIN SCRIPT
%=======================================================================

clc; clear; close all;
tic;
%-----------------------------------------------------------------------
% System Parameters
%-----------------------------------------------------------------------
params = initialize_system_parameters();

%-----------------------------------------------------------------------
% Pre-generate Channel Realizations
%-----------------------------------------------------------------------
[all_channels, all_alpha] = generate_channel_realizations(params);

%-----------------------------------------------------------------------
% Initialize Variables
%-----------------------------------------------------------------------
opt_vars = initialize_optimization_variables(params);

%-----------------------------------------------------------------------
% Hierarchical Optimization
%-----------------------------------------------------------------------
[opt_vars, objective_history] = run_hierarchical_optimization(params, all_channels, opt_vars);

%-----------------------------------------------------------------------
% Final Results and Constraint Verification
%-----------------------------------------------------------------------
display_final_results(params, all_channels, opt_vars);
verify_constraints(params, all_channels, opt_vars);

%-----------------------------------------------------------------------
% Generate Comprehensive Summary
%-----------------------------------------------------------------------
fprintf('\n========== Generating Comprehensive Summary ==========\n');
generate_comprehensive_summary();

fprintf('\n========== SIMULATION COMPLETED SUCCESSFULLY ==========\n');
fprintf('All results saved in: Results/\n');
fprintf('  - Plots & Data: Results/Saved Files/\n');
fprintf('  - Summary Reports: Results/Summary/\n');
fprintf('    * comprehensive_summary.mat  (MATLAB data)\n');
fprintf('    * comprehensive_summary.txt  (Text report)\n');
fprintf('    * comprehensive_summary.xlsx (Excel report)\n');
fprintf('\n========================================\n');
toc;