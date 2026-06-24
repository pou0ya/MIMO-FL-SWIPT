%DOCUMENT filename="plot_energy_vs_global_accuracy.m"
function plot_energy_vs_global_accuracy(params, all_channels, opt_vars)

    % Create directory structure if it doesn't exist
    if ~exist('Results/Saved Files', 'dir')
        mkdir('Results/Saved Files');
    end
    
    % Handle case when called without arguments (for replotting)
    if nargin == 0
        % Load base parameters for replotting
        params = initialize_system_parameters();
        [all_channels, ~] = generate_channel_realizations(params);
        opt_vars = initialize_optimization_variables(params);
    end
    
    %===================================================================
    % Figure 1: Energy vs Global Accuracy for Different Numbers of Antennas
    %===================================================================
    data_file_antennas = 'Results/Saved Files/energy_vs_global_accuracy_antennas_data.mat';
    
    if exist(data_file_antennas, 'file')
        load(data_file_antennas, 'omega_range', 'E_vs_omega_A16', 'E_vs_omega_A32', 'E_vs_omega_A64', 'E_vs_omega_A128', 'A_range');
    else
        fprintf('\n--- Computing energy vs global accuracy for different antenna configurations ---\n');
        A_range = [16, 32, 64, 128];
        omega_range = logspace(-3, -1, 15);
        E_vs_omega_all = zeros(length(A_range), length(omega_range));
        
        for a_idx = 1:length(A_range)
            A_temp = A_range(a_idx);
            fprintf('Computing for A = %d...\n', A_temp);
            
            params_temp = params;
            params_temp.A = A_temp;
            
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            E_eff_total = calculate_total_energy(params_temp, all_channels_temp, opt_vars_temp);
            
            for idx = 1:length(omega_range)
                omega_test = omega_range(idx);
                scaling_factor = log(1/omega_test) / log(1/params_temp.omega_target);
                E_vs_omega_all(a_idx, idx) = E_eff_total * scaling_factor;
            end
        end
        
        E_vs_omega_A16 = E_vs_omega_all(1, :);
        E_vs_omega_A32 = E_vs_omega_all(2, :);
        E_vs_omega_A64 = E_vs_omega_all(3, :);
        E_vs_omega_A128 = E_vs_omega_all(4, :);
        
        save(data_file_antennas, 'omega_range', 'E_vs_omega_A16', 'E_vs_omega_A32', 'E_vs_omega_A64', 'E_vs_omega_A128', 'A_range');
    end
    
    figure();
    hold on;
    semilogx(omega_range, E_vs_omega_A16, '-o', 'LineStyle','-', 'LineWidth', 1.5, 'Color', 'b');
    semilogx(omega_range, E_vs_omega_A32, '--s', 'LineStyle','-.', 'LineWidth', 1.5, 'Color', 'b');
    semilogx(omega_range, E_vs_omega_A64, '-^', 'LineStyle',':', 'LineWidth', 1.5, 'Color', 'b');
    semilogx(omega_range, E_vs_omega_A128, '--d', 'LineStyle','--', 'LineWidth', 1.5, 'Color', 'b');
    hold off;
    grid on;
    xlabel('Global Accuracy Target', 'Interpreter', 'latex', 'FontSize',12);
    ylabel('Total Energy Consumption (J)', 'Interpreter', 'latex', 'FontSize',12);
    legend('A = 16', 'A = 32', 'A = 64', 'A = 128', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
    
    %===================================================================
    % Figure 2: Energy vs Global Accuracy for Different Numbers of Users
    %===================================================================
    data_file_users = 'Results/Saved Files/energy_vs_global_accuracy_users_data.mat';
    
    if exist(data_file_users, 'file')
        load(data_file_users, 'omega_range', 'E_vs_omega_D2', 'E_vs_omega_D4', 'E_vs_omega_D6', 'E_vs_omega_D8', 'E_vs_omega_D10', 'D_range');
    else
        fprintf('\n--- Computing energy vs global accuracy for different user configurations ---\n');
        D_range = [2, 4, 6, 8, 10];
        omega_range = logspace(-3, -1, 15);
        E_vs_omega_all = zeros(length(D_range), length(omega_range));
        
        for d_idx = 1:length(D_range)
            D_temp = D_range(d_idx);
            fprintf('Computing for D = %d...\n', D_temp);
            
            params_temp = params;
            params_temp.D = D_temp;
            params_temp.u_max = 10^(-10/10)/1000 * ones(D_temp,1);
            params_temp.E_BA = 15 * ones(D_temp,1);
            params_temp.f_min = 1e9 * ones(D_temp,1);
            params_temp.f_max = 3e9 * ones(D_temp,1);
            
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            E_eff_total = calculate_total_energy(params_temp, all_channels_temp, opt_vars_temp);
            
            for idx = 1:length(omega_range)
                omega_test = omega_range(idx);
                scaling_factor = log(1/omega_test) / log(1/params_temp.omega_target);
                E_vs_omega_all(d_idx, idx) = E_eff_total * scaling_factor;
            end
        end
        
        E_vs_omega_D2 = E_vs_omega_all(1, :);
        E_vs_omega_D4 = E_vs_omega_all(2, :);
        E_vs_omega_D6 = E_vs_omega_all(3, :);
        E_vs_omega_D8 = E_vs_omega_all(4, :);
        E_vs_omega_D10 = E_vs_omega_all(5, :);
        
        save(data_file_users, 'omega_range', 'E_vs_omega_D2', 'E_vs_omega_D4', 'E_vs_omega_D6', 'E_vs_omega_D8', 'E_vs_omega_D10', 'D_range');
    end
    
    figure('Position', [100, 100, 900, 600]);
    hold on;
    semilogx(omega_range, E_vs_omega_D2, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    semilogx(omega_range, E_vs_omega_D4, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
    semilogx(omega_range, E_vs_omega_D6, 'g-d', 'LineWidth', 2, 'MarkerSize', 6);
    semilogx(omega_range, E_vs_omega_D8, 'm-^', 'LineWidth', 2, 'MarkerSize', 6);
    semilogx(omega_range, E_vs_omega_D10, 'c-v', 'LineWidth', 2, 'MarkerSize', 6);
    hold off;
    grid on;
    xlabel('Global Accuracy Target (ω)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Total Energy Consumption (J)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Energy vs Global Accuracy for Different Numbers of Users', 'FontSize', 16);
    legend('D = 2', 'D = 4', 'D = 6', 'D = 8', 'D = 10', 'Location', 'best');
    set(gca, 'FontSize', 12);
    
    fprintf('Plot 6: Energy vs Global Accuracy - Generated (2 figures)\n');
end