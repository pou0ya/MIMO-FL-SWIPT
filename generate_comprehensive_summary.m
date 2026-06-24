function generate_comprehensive_summary()
%GENERATE_COMPREHENSIVE_SUMMARY Generates a comprehensive summary report
% This function reads all saved simulation data and creates a unified 
% summary document containing results for all configurations tested.

    fprintf('\n========== GENERATING COMPREHENSIVE SUMMARY ==========\n\n');
    
    % Create output directory
    if ~exist('Results/Summary', 'dir')
        mkdir('Results/Summary');
    end
    
    % Initialize summary structure
    summary = struct();
    
    %===================================================================
    % 1. Load Base Configuration Results
    %===================================================================
    fprintf('Loading base configuration results...\n');
    params = initialize_system_parameters();
    summary.base_config.D = params.D;
    summary.base_config.A = params.A;
    summary.base_config.num_realizations = params.num_realizations;
    summary.base_config.omega_target = params.omega_target;
    summary.base_config.mu_efficiency = params.mu_efficiency;
    
    %===================================================================
    % 2. Load Energy vs Users Data
    %===================================================================
    fprintf('Loading energy vs users data...\n');
    data_file = 'Results/Saved Files/energy_vs_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'D_range', 'E_vs_D_with_SWIPT', 'E_vs_D_without_SWIPT');
        summary.energy_vs_users.D_range = D_range;
        summary.energy_vs_users.with_SWIPT = E_vs_D_with_SWIPT;
        summary.energy_vs_users.without_SWIPT = E_vs_D_without_SWIPT;
        summary.energy_vs_users.energy_saving = ...
            ((E_vs_D_without_SWIPT - E_vs_D_with_SWIPT) ./ E_vs_D_without_SWIPT) * 100;
    else
        fprintf('  WARNING: Energy vs users data not found!\n');
    end
    
    %===================================================================
    % 3. Load Energy vs Antennas Data
    %===================================================================
    fprintf('Loading energy vs antennas data...\n');
    data_file = 'Results/Saved Files/energy_vs_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'A_range', 'D_values', 'E_matrix_with_SWIPT', 'E_matrix_without_SWIPT');
        summary.energy_vs_antennas.A_range = A_range;
        summary.energy_vs_antennas.D_values = D_values;
        summary.energy_vs_antennas.with_SWIPT = E_matrix_with_SWIPT;
        summary.energy_vs_antennas.without_SWIPT = E_matrix_without_SWIPT;
        summary.energy_vs_antennas.energy_saving = ...
            ((E_matrix_without_SWIPT - E_matrix_with_SWIPT) ./ E_matrix_without_SWIPT) * 100;
    else
        fprintf('  WARNING: Energy vs antennas data not found!\n');
    end
    
    %===================================================================
    % 4. Load Convergence Data
    %===================================================================
    fprintf('Loading convergence data...\n');
    
    % Convergence vs Antennas
    data_file = 'Results/Saved Files/convergence_vs_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'obj_hist_A16', 'obj_hist_A32', 'obj_hist_A64', 'obj_hist_A128', 'A_range');
        summary.convergence.antennas.A_range = A_range;
        summary.convergence.antennas.A16 = obj_hist_A16;
        summary.convergence.antennas.A32 = obj_hist_A32;
        summary.convergence.antennas.A64 = obj_hist_A64;
        summary.convergence.antennas.A128 = obj_hist_A128;
        
        % Calculate convergence iterations
        summary.convergence.antennas.iters_A16 = length(obj_hist_A16);
        summary.convergence.antennas.iters_A32 = length(obj_hist_A32);
        summary.convergence.antennas.iters_A64 = length(obj_hist_A64);
        summary.convergence.antennas.iters_A128 = length(obj_hist_A128);
    end
    
    % Convergence vs Users
    data_file = 'Results/Saved Files/convergence_vs_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'obj_hist_D2', 'obj_hist_D4', 'obj_hist_D6', 'obj_hist_D8', 'obj_hist_D10', 'D_range');
        summary.convergence.users.D_range = D_range;
        summary.convergence.users.D2 = obj_hist_D2;
        summary.convergence.users.D4 = obj_hist_D4;
        summary.convergence.users.D6 = obj_hist_D6;
        summary.convergence.users.D8 = obj_hist_D8;
        summary.convergence.users.D10 = obj_hist_D10;
        
        % Calculate convergence iterations
        summary.convergence.users.iters_D2 = length(obj_hist_D2);
        summary.convergence.users.iters_D4 = length(obj_hist_D4);
        summary.convergence.users.iters_D6 = length(obj_hist_D6);
        summary.convergence.users.iters_D8 = length(obj_hist_D8);
        summary.convergence.users.iters_D10 = length(obj_hist_D10);
    end
    
    %===================================================================
    % 5. Load Energy vs Local Accuracy (Tau)
    %===================================================================
    fprintf('Loading energy vs tau data...\n');
    
    % Tau vs Antennas
    data_file = 'Results/Saved Files/energy_vs_tau_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'tau_range', 'E_vs_tau_A16', 'E_vs_tau_A32', 'E_vs_tau_A64', 'E_vs_tau_A128');
        summary.energy_vs_tau.antennas.tau_range = tau_range;
        summary.energy_vs_tau.antennas.A16 = E_vs_tau_A16;
        summary.energy_vs_tau.antennas.A32 = E_vs_tau_A32;
        summary.energy_vs_tau.antennas.A64 = E_vs_tau_A64;
        summary.energy_vs_tau.antennas.A128 = E_vs_tau_A128;
    end
    
    % Tau vs Users
    data_file = 'Results/Saved Files/energy_vs_tau_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'tau_range', 'E_vs_tau_D2', 'E_vs_tau_D4', 'E_vs_tau_D6', 'E_vs_tau_D8', 'E_vs_tau_D10');
        summary.energy_vs_tau.users.tau_range = tau_range;
        summary.energy_vs_tau.users.D2 = E_vs_tau_D2;
        summary.energy_vs_tau.users.D4 = E_vs_tau_D4;
        summary.energy_vs_tau.users.D6 = E_vs_tau_D6;
        summary.energy_vs_tau.users.D8 = E_vs_tau_D8;
        summary.energy_vs_tau.users.D10 = E_vs_tau_D10;
    end
    
    %===================================================================
    % 6. Load Energy vs CPU Frequency
    %===================================================================
    fprintf('Loading energy vs frequency data...\n');
    
    % Frequency vs Antennas
    data_file = 'Results/Saved Files/energy_vs_frequency_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'f_range', 'E_vs_f_A16', 'E_vs_f_A32', 'E_vs_f_A64', 'E_vs_f_A128');
        summary.energy_vs_frequency.antennas.f_range = f_range;
        summary.energy_vs_frequency.antennas.A16 = E_vs_f_A16;
        summary.energy_vs_frequency.antennas.A32 = E_vs_f_A32;
        summary.energy_vs_frequency.antennas.A64 = E_vs_f_A64;
        summary.energy_vs_frequency.antennas.A128 = E_vs_f_A128;
    end
    
    % Frequency vs Users
    data_file = 'Results/Saved Files/energy_vs_frequency_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'f_range', 'E_vs_f_D2', 'E_vs_f_D4', 'E_vs_f_D6', 'E_vs_f_D8', 'E_vs_f_D10');
        summary.energy_vs_frequency.users.f_range = f_range;
        summary.energy_vs_frequency.users.D2 = E_vs_f_D2;
        summary.energy_vs_frequency.users.D4 = E_vs_f_D4;
        summary.energy_vs_frequency.users.D6 = E_vs_f_D6;
        summary.energy_vs_frequency.users.D8 = E_vs_f_D8;
        summary.energy_vs_frequency.users.D10 = E_vs_f_D10;
    end
    
    %===================================================================
    % 7. Load Energy vs Global Accuracy
    %===================================================================
    fprintf('Loading energy vs global accuracy data...\n');
    
    % Global accuracy vs Antennas
    data_file = 'Results/Saved Files/energy_vs_global_accuracy_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'omega_range', 'E_vs_omega_A16', 'E_vs_omega_A32', 'E_vs_omega_A64', 'E_vs_omega_A128');
        summary.energy_vs_global_accuracy.antennas.omega_range = omega_range;
        summary.energy_vs_global_accuracy.antennas.A16 = E_vs_omega_A16;
        summary.energy_vs_global_accuracy.antennas.A32 = E_vs_omega_A32;
        summary.energy_vs_global_accuracy.antennas.A64 = E_vs_omega_A64;
        summary.energy_vs_global_accuracy.antennas.A128 = E_vs_omega_A128;
    end
    
    % Global accuracy vs Users
    data_file = 'Results/Saved Files/energy_vs_global_accuracy_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'omega_range', 'E_vs_omega_D2', 'E_vs_omega_D4', 'E_vs_omega_D6', 'E_vs_omega_D8', 'E_vs_omega_D10');
        summary.energy_vs_global_accuracy.users.omega_range = omega_range;
        summary.energy_vs_global_accuracy.users.D2 = E_vs_omega_D2;
        summary.energy_vs_global_accuracy.users.D4 = E_vs_omega_D4;
        summary.energy_vs_global_accuracy.users.D6 = E_vs_omega_D6;
        summary.energy_vs_global_accuracy.users.D8 = E_vs_omega_D8;
        summary.energy_vs_global_accuracy.users.D10 = E_vs_omega_D10;
    end
    
    %===================================================================
    % 8. Load Energy vs Harvesting Efficiency
    %===================================================================
    fprintf('Loading energy vs harvesting efficiency data...\n');
    
    % Harvesting vs Antennas
    data_file = 'Results/Saved Files/energy_vs_harvesting_antennas_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'mu_range', 'E_vs_mu_A16', 'E_vs_mu_A32', 'E_vs_mu_A64', 'E_vs_mu_A128');
        summary.energy_vs_harvesting.antennas.mu_range = mu_range;
        summary.energy_vs_harvesting.antennas.A16 = E_vs_mu_A16;
        summary.energy_vs_harvesting.antennas.A32 = E_vs_mu_A32;
        summary.energy_vs_harvesting.antennas.A64 = E_vs_mu_A64;
        summary.energy_vs_harvesting.antennas.A128 = E_vs_mu_A128;
    end
    
    % Harvesting vs Users
    data_file = 'Results/Saved Files/energy_vs_harvesting_users_data.mat';
    if exist(data_file, 'file')
        load(data_file, 'mu_range', 'E_vs_mu_D2', 'E_vs_mu_D4', 'E_vs_mu_D6', 'E_vs_mu_D8', 'E_vs_mu_D10');
        summary.energy_vs_harvesting.users.mu_range = mu_range;
        summary.energy_vs_harvesting.users.D2 = E_vs_mu_D2;
        summary.energy_vs_harvesting.users.D4 = E_vs_mu_D4;
        summary.energy_vs_harvesting.users.D6 = E_vs_mu_D6;
        summary.energy_vs_harvesting.users.D8 = E_vs_mu_D8;
        summary.energy_vs_harvesting.users.D10 = E_vs_mu_D10;
    end
    
    %===================================================================
    % 9. Save Summary Data
    %===================================================================
    fprintf('Saving comprehensive summary data...\n');
    save('Results/Summary/comprehensive_summary.mat', 'summary');
    
    %===================================================================
    % 10. Generate Text Report
    %===================================================================
    fprintf('Generating text report...\n');
    generate_text_report(summary);
    
    %===================================================================
    % 11. Generate Excel Report
    %===================================================================
    fprintf('Generating Excel report...\n');
    generate_excel_report(summary);
    
    fprintf('\n========== COMPREHENSIVE SUMMARY GENERATED ==========\n');
    fprintf('Location: Results/Summary/\n');
    fprintf('Files generated:\n');
    fprintf('  - comprehensive_summary.mat (MATLAB data)\n');
    fprintf('  - comprehensive_summary.txt (Text report)\n');
    fprintf('  - comprehensive_summary.xlsx (Excel report)\n\n');
    
end

%=======================================================================
% Helper Function: Generate Text Report
%=======================================================================
function generate_text_report(summary)
    
    fid = fopen('Results/Summary/comprehensive_summary.txt', 'w');
    
    fprintf(fid, '========================================================================\n');
    fprintf(fid, '          COMPREHENSIVE SIMULATION RESULTS SUMMARY REPORT\n');
    fprintf(fid, '       Energy-Efficient Federated Learning with SWIPT-MIMO\n');
    fprintf(fid, '========================================================================\n\n');
    
    % Base Configuration
    fprintf(fid, '1. BASE CONFIGURATION\n');
    fprintf(fid, '   -------------------------------------------------------------------\n');
    fprintf(fid, '   Number of Users (D):              %d\n', summary.base_config.D);
    fprintf(fid, '   Number of BS Antennas (A):        %d\n', summary.base_config.A);
    fprintf(fid, '   Number of Realizations:           %d\n', summary.base_config.num_realizations);
    fprintf(fid, '   Target Global Accuracy (ω):       %.4f\n', summary.base_config.omega_target);
    fprintf(fid, '   Harvesting Efficiency (μ):        %.2f\n\n', summary.base_config.mu_efficiency);
    
    % Energy vs Users
    if isfield(summary, 'energy_vs_users')
        fprintf(fid, '2. ENERGY CONSUMPTION vs NUMBER OF USERS\n');
        fprintf(fid, '   -------------------------------------------------------------------\n');
        fprintf(fid, '   D  | With SWIPT (J) | Without SWIPT (J) | Energy Saving (%%)\n');
        fprintf(fid, '   ---|----------------|-------------------|-------------------\n');
        for i = 1:length(summary.energy_vs_users.D_range)
            fprintf(fid, '   %-2d | %14.6f | %17.6f | %17.2f\n', ...
                summary.energy_vs_users.D_range(i), ...
                summary.energy_vs_users.with_SWIPT(i), ...
                summary.energy_vs_users.without_SWIPT(i), ...
                summary.energy_vs_users.energy_saving(i));
        end
        fprintf(fid, '\n');
    end
    
    % Energy vs Antennas (for multiple D values)
    if isfield(summary, 'energy_vs_antennas')
        fprintf(fid, '3. ENERGY CONSUMPTION vs NUMBER OF ANTENNAS\n');
        fprintf(fid, '   -------------------------------------------------------------------\n');
        for d_idx = 1:length(summary.energy_vs_antennas.D_values)
            D_val = summary.energy_vs_antennas.D_values(d_idx);
            fprintf(fid, '   For D = %d:\n', D_val);
            fprintf(fid, '   A   | With SWIPT (J) | Without SWIPT (J) | Energy Saving (%%)\n');
            fprintf(fid, '   ----|----------------|-------------------|-------------------\n');
            for a_idx = 1:length(summary.energy_vs_antennas.A_range)
                fprintf(fid, '   %-3d | %14.6f | %17.6f | %17.2f\n', ...
                    summary.energy_vs_antennas.A_range(a_idx), ...
                    summary.energy_vs_antennas.with_SWIPT(d_idx, a_idx), ...
                    summary.energy_vs_antennas.without_SWIPT(d_idx, a_idx), ...
                    summary.energy_vs_antennas.energy_saving(d_idx, a_idx));
            end
            fprintf(fid, '\n');
        end
    end
    
    % Convergence Results
    if isfield(summary, 'convergence')
        fprintf(fid, '4. CONVERGENCE ANALYSIS\n');
        fprintf(fid, '   -------------------------------------------------------------------\n');
        
        if isfield(summary.convergence, 'antennas')
            fprintf(fid, '   a) Convergence Iterations vs Number of Antennas:\n');
            fprintf(fid, '      A = 16:  %d iterations\n', summary.convergence.antennas.iters_A16);
            fprintf(fid, '      A = 32:  %d iterations\n', summary.convergence.antennas.iters_A32);
            fprintf(fid, '      A = 64:  %d iterations\n', summary.convergence.antennas.iters_A64);
            fprintf(fid, '      A = 128: %d iterations\n\n', summary.convergence.antennas.iters_A128);
        end
        
        if isfield(summary.convergence, 'users')
            fprintf(fid, '   b) Convergence Iterations vs Number of Users:\n');
            fprintf(fid, '      D = 2:  %d iterations\n', summary.convergence.users.iters_D2);
            fprintf(fid, '      D = 4:  %d iterations\n', summary.convergence.users.iters_D4);
            fprintf(fid, '      D = 6:  %d iterations\n', summary.convergence.users.iters_D6);
            fprintf(fid, '      D = 8:  %d iterations\n', summary.convergence.users.iters_D8);
            fprintf(fid, '      D = 10: %d iterations\n\n', summary.convergence.users.iters_D10);
        end
    end
    
    % Key Findings Summary
    fprintf(fid, '5. KEY FINDINGS\n');
    fprintf(fid, '   -------------------------------------------------------------------\n');
    if isfield(summary, 'energy_vs_users')
        avg_saving = mean(summary.energy_vs_users.energy_saving);
        fprintf(fid, '   • Average energy saving with SWIPT: %.2f%%\n', avg_saving);
        fprintf(fid, '   • Maximum energy saving: %.2f%% (at D=%d)\n', ...
            max(summary.energy_vs_users.energy_saving), ...
            summary.energy_vs_users.D_range(find(summary.energy_vs_users.energy_saving == max(summary.energy_vs_users.energy_saving), 1)));
    end
    
    if isfield(summary, 'energy_vs_antennas')
        all_savings = summary.energy_vs_antennas.energy_saving(:);
        fprintf(fid, '   • Overall average energy saving: %.2f%%\n', mean(all_savings));
        fprintf(fid, '   • Best configuration energy saving: %.2f%%\n', max(all_savings));
    end
    
    fprintf(fid, '\n========================================================================\n');
    fprintf(fid, '                          END OF REPORT\n');
    fprintf(fid, '========================================================================\n');
    
    fclose(fid);
    
end

%=======================================================================
% Helper Function: Generate Excel Report
%=======================================================================
function generate_excel_report(summary)
    
    filename = 'Results/Summary/comprehensive_summary.xlsx';
    
    % Sheet 1: Base Configuration
    sheet1_data = {
        'Parameter', 'Value';
        'Number of Users (D)', summary.base_config.D;
        'Number of BS Antennas (A)', summary.base_config.A;
        'Number of Realizations', summary.base_config.num_realizations;
        'Target Global Accuracy (ω)', summary.base_config.omega_target;
        'Harvesting Efficiency (μ)', summary.base_config.mu_efficiency;
    };
    writecell(sheet1_data, filename, 'Sheet', 'Configuration');
    
    % Sheet 2: Energy vs Users
    if isfield(summary, 'energy_vs_users')
        sheet2_data = {'D', 'With SWIPT (J)', 'Without SWIPT (J)', 'Energy Saving (%)'};
        for i = 1:length(summary.energy_vs_users.D_range)
            sheet2_data = [sheet2_data; {
                summary.energy_vs_users.D_range(i), ...
                summary.energy_vs_users.with_SWIPT(i), ...
                summary.energy_vs_users.without_SWIPT(i), ...
                summary.energy_vs_users.energy_saving(i)
            }];
        end
        writecell(sheet2_data, filename, 'Sheet', 'Energy_vs_Users');
    end
    
    % Sheet 3: Energy vs Antennas
    if isfield(summary, 'energy_vs_antennas')
        sheet3_data = {'D', 'A', 'With SWIPT (J)', 'Without SWIPT (J)', 'Energy Saving (%)'};
        for d_idx = 1:length(summary.energy_vs_antennas.D_values)
            for a_idx = 1:length(summary.energy_vs_antennas.A_range)
                sheet3_data = [sheet3_data; {
                    summary.energy_vs_antennas.D_values(d_idx), ...
                    summary.energy_vs_antennas.A_range(a_idx), ...
                    summary.energy_vs_antennas.with_SWIPT(d_idx, a_idx), ...
                    summary.energy_vs_antennas.without_SWIPT(d_idx, a_idx), ...
                    summary.energy_vs_antennas.energy_saving(d_idx, a_idx)
                }];
            end
        end
        writecell(sheet3_data, filename, 'Sheet', 'Energy_vs_Antennas');
    end
    
    % Sheet 4: Convergence
    if isfield(summary, 'convergence')
        if isfield(summary.convergence, 'antennas')
            sheet4_data = {'A', 'Iterations'};
            sheet4_data = [sheet4_data; {16, summary.convergence.antennas.iters_A16}];
            sheet4_data = [sheet4_data; {32, summary.convergence.antennas.iters_A32}];
            sheet4_data = [sheet4_data; {64, summary.convergence.antennas.iters_A64}];
            sheet4_data = [sheet4_data; {128, summary.convergence.antennas.iters_A128}];
            writecell(sheet4_data, filename, 'Sheet', 'Convergence_Antennas');
        end
        
        if isfield(summary.convergence, 'users')
            sheet5_data = {'D', 'Iterations'};
            sheet5_data = [sheet5_data; {2, summary.convergence.users.iters_D2}];
            sheet5_data = [sheet5_data; {4, summary.convergence.users.iters_D4}];
            sheet5_data = [sheet5_data; {6, summary.convergence.users.iters_D6}];
            sheet5_data = [sheet5_data; {8, summary.convergence.users.iters_D8}];
            sheet5_data = [sheet5_data; {10, summary.convergence.users.iters_D10}];
            writecell(sheet5_data, filename, 'Sheet', 'Convergence_Users');
        end
    end
    
end