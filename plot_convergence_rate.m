%DOCUMENT filename="plot_convergence_rate.m"
function plot_convergence_rate(objective_history)

    % Create directory structure if it doesn't exist
    if ~exist('Results/Saved Files', 'dir')
        mkdir('Results/Saved Files');
    end
    
    data_file = 'Results/Saved Files/convergence_rate_data.mat';
    
    % Save the passed objective history only if provided
    if nargin > 0 && ~isempty(objective_history)
        save(data_file, 'objective_history');
    end
    
    %===================================================================
    % Figure 1: Convergence with Different Numbers of Antennas
    %===================================================================
    data_file_antennas = 'Results/Saved Files/convergence_vs_antennas_data.mat';
    
    if exist(data_file_antennas, 'file')
        load(data_file_antennas, 'obj_hist_A16', 'obj_hist_A32', 'obj_hist_A64', 'obj_hist_A128', 'A_range');
    else
        fprintf('\n--- Computing convergence for different antenna configurations ---\n');
        A_range = [16, 32, 64, 128];
        obj_histories = cell(length(A_range), 1);
        
        for a_idx = 1:length(A_range)
            A_temp = A_range(a_idx);
            fprintf('Running for A = %d...\n', A_temp);
            
            % Load base parameters
            params_temp = initialize_system_parameters();
            params_temp.A = A_temp;
            
            % Generate channels and optimize
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [~, obj_hist_temp] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 20);
            
            obj_histories{a_idx} = obj_hist_temp;
        end
        
        obj_hist_A16 = obj_histories{1};
        obj_hist_A32 = obj_histories{2};
        obj_hist_A64 = obj_histories{3};
        obj_hist_A128 = obj_histories{4};
        
        save(data_file_antennas, 'obj_hist_A16', 'obj_hist_A32', 'obj_hist_A64', 'obj_hist_A128', 'A_range');
    end
    
    figure();
    hold on;
    plot(1:length(obj_hist_A16), obj_hist_A16, '-o', 'LineStyle','-', 'LineWidth', 1.5, 'Color', 'b');
    plot(1:length(obj_hist_A32), obj_hist_A32, '--s', 'LineStyle','-.', 'LineWidth', 1.5, 'Color', 'b');
    plot(1:length(obj_hist_A64), obj_hist_A64, '-^', 'LineStyle',':', 'LineWidth', 1.5, 'Color', 'b');
    plot(1:length(obj_hist_A128), obj_hist_A128, '--d', 'LineStyle','--', 'LineWidth', 1.5, 'Color', 'b');
    hold off;
    grid on;
    xlabel('Iteration', 'Interpreter', 'latex', 'FontSize',12);
    xticks(1:1:15)
    ylabel('Energy Consumption (J)', 'Interpreter', 'latex', 'FontSize',12);
    legend('A = 16', 'A = 32', 'A = 64', 'A = 128', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
    
    %===================================================================
    % Figure 2: Convergence with Different Numbers of Users
    %===================================================================
    data_file_users = 'Results/Saved Files/convergence_vs_users_data.mat';
    
    if exist(data_file_users, 'file')
        load(data_file_users, 'obj_hist_D2', 'obj_hist_D4', 'obj_hist_D6', 'obj_hist_D8', 'obj_hist_D10', 'D_range');
    else
        fprintf('\n--- Computing convergence for different user configurations ---\n');
        D_range = [2, 4, 6, 8, 10];
        obj_histories = cell(length(D_range), 1);
        
        for d_idx = 1:length(D_range)
            D_temp = D_range(d_idx);
            fprintf('Running for D = %d...\n', D_temp);
            
            % Load base parameters
            params_temp = initialize_system_parameters();
            params_temp.D = D_temp;
            params_temp.u_max = 10^(-10/10)/1000 * ones(D_temp,1);
            params_temp.E_BA = 15 * ones(D_temp,1);
            params_temp.f_min = 1e9 * ones(D_temp,1);
            params_temp.f_max = 3e9 * ones(D_temp,1);
            
            % Generate channels and optimize
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [~, obj_hist_temp] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 20);
            
            obj_histories{d_idx} = obj_hist_temp;
        end
        
        obj_hist_D2 = obj_histories{1};
        obj_hist_D4 = obj_histories{2};
        obj_hist_D6 = obj_histories{3};
        obj_hist_D8 = obj_histories{4};
        obj_hist_D10 = obj_histories{5};
        
        save(data_file_users, 'obj_hist_D2', 'obj_hist_D4', 'obj_hist_D6', 'obj_hist_D8', 'obj_hist_D10', 'D_range');
    end
    
    figure('Position', [100, 100, 900, 600]);
    hold on;
    plot(1:length(obj_hist_D2), obj_hist_D2, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    plot(1:length(obj_hist_D4), obj_hist_D4, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
    plot(1:length(obj_hist_D6), obj_hist_D6, 'g-d', 'LineWidth', 2, 'MarkerSize', 6);
    plot(1:length(obj_hist_D8), obj_hist_D8, 'm-^', 'LineWidth', 2, 'MarkerSize', 6);
    plot(1:length(obj_hist_D10), obj_hist_D10, 'c-v', 'LineWidth', 2, 'MarkerSize', 6);
    hold off;
    grid on;
    xlabel('Outer Iteration', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Effective Energy Consumption (J)', 'FontSize', 14, 'FontWeight', 'bold');
    legend('D = 2', 'D = 4', 'D = 6', 'D = 8', 'D = 10', 'Location', 'best');
    set(gca, 'FontSize', 12);
    
    fprintf('Plot 1: Convergence Rate - Generated (2 figures)\n');
end