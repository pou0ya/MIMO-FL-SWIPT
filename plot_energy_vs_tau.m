%DOCUMENT filename="plot_energy_vs_tau.m"
function plot_energy_vs_tau(params, all_channels, opt_vars)

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
    % Figure 1: Energy vs Tau for Different Numbers of Antennas
    %===================================================================
    data_file_antennas = 'Results/Saved Files/energy_vs_tau_antennas_data.mat';
    
    if exist(data_file_antennas, 'file')
        load(data_file_antennas, 'tau_range', 'E_vs_tau_A16', 'E_vs_tau_A32', 'E_vs_tau_A64', 'E_vs_tau_A128', 'A_range');
    else
        fprintf('\n--- Computing energy vs tau for different antenna configurations ---\n');
        A_range = [16, 32, 64, 128];
        tau_range = linspace(params.tau_min, params.tau_max, 20);
        E_vs_tau_all = zeros(length(A_range), length(tau_range));
        
        for a_idx = 1:length(A_range)
            A_temp = A_range(a_idx);
            fprintf('Computing for A = %d...\n', A_temp);
            
            params_temp = params;
            params_temp.A = A_temp;
            
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            for idx = 1:length(tau_range)
                tau_test = tau_range(idx);
                E_temp = 0;
                
                for r = 1:params_temp.num_realizations
                    C = all_channels_temp{r};
                    for d = 1:params_temp.D
                        E_UL = params_temp.u_max(d) * opt_vars_temp.vartheta_k(d) * params_temp.X_UL / opt_vars_temp.r_UL_k(d);
                        N_tau = params_temp.varrho * log(1 / tau_test);
                        E_CM = (params_temp.upsilon/2) * N_tau * params_temp.Z_d * params_temp.Q_d * opt_vars_temp.f_k(d)^2;
                        
                        c_d = C(:, d);
                        P_recv = abs(c_d' * opt_vars_temp.b_DL_k)^2;
                        t_DL = params_temp.X_DL / opt_vars_temp.r_DL_k(d);
                        E_HA = params_temp.mu_efficiency * (1 - opt_vars_temp.rho_k(d)) * P_recv * t_DL;
                        
                        E_net = E_UL + E_CM - E_HA;
                        E_temp = E_temp + (E_net / (1 - tau_test)) / params_temp.num_realizations;
                    end
                end
                E_vs_tau_all(a_idx, idx) = E_temp;
            end
        end
        
        E_vs_tau_A16 = E_vs_tau_all(1, :);
        E_vs_tau_A32 = E_vs_tau_all(2, :);
        E_vs_tau_A64 = E_vs_tau_all(3, :);
        E_vs_tau_A128 = E_vs_tau_all(4, :);
        
        save(data_file_antennas, 'tau_range', 'E_vs_tau_A16', 'E_vs_tau_A32', 'E_vs_tau_A64', 'E_vs_tau_A128', 'A_range');
    end
    
    figure();
    hold on;
    plot(tau_range, E_vs_tau_A16, '-o', 'LineStyle','-', 'LineWidth', 1.5, 'Color', 'b');
    plot(tau_range, E_vs_tau_A32, '--s', 'LineStyle','-.', 'LineWidth', 1.5, 'Color', 'b');
    plot(tau_range, E_vs_tau_A64, '-^', 'LineStyle',':', 'LineWidth', 1.5, 'Color', 'b');
    plot(tau_range, E_vs_tau_A128, '--d', 'LineStyle','--', 'LineWidth', 1.5, 'Color', 'b');
    hold off;
    grid on;
    xlabel('Local Accuracy', 'Interpreter', 'latex', 'FontSize',12);
    ylabel('Energy Consumption (J)', 'Interpreter', 'latex', 'FontSize',12);
    legend('A = 16', 'A = 32', 'A = 64', 'A = 128', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
    
    %===================================================================
    % Figure 2: Energy vs Tau for Different Numbers of Users
    %===================================================================
    data_file_users = 'Results/Saved Files/energy_vs_tau_users_data.mat';
    
    if exist(data_file_users, 'file')
        load(data_file_users, 'tau_range', 'E_vs_tau_D2', 'E_vs_tau_D4', 'E_vs_tau_D6', 'E_vs_tau_D8', 'E_vs_tau_D10', 'D_range');
    else
        fprintf('\n--- Computing energy vs tau for different user configurations ---\n');
        D_range = [2, 4, 6, 8, 10];
        tau_range = linspace(params.tau_min, params.tau_max, 20);
        E_vs_tau_all = zeros(length(D_range), length(tau_range));
        
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
            
            for idx = 1:length(tau_range)
                tau_test = tau_range(idx);
                E_temp = 0;
                
                for r = 1:params_temp.num_realizations
                    C = all_channels_temp{r};
                    for d = 1:params_temp.D
                        E_UL = params_temp.u_max(d) * opt_vars_temp.vartheta_k(d) * params_temp.X_UL / opt_vars_temp.r_UL_k(d);
                        N_tau = params_temp.varrho * log(1 / tau_test);
                        E_CM = (params_temp.upsilon/2) * N_tau * params_temp.Z_d * params_temp.Q_d * opt_vars_temp.f_k(d)^2;
                        
                        c_d = C(:, d);
                        P_recv = abs(c_d' * opt_vars_temp.b_DL_k)^2;
                        t_DL = params_temp.X_DL / opt_vars_temp.r_DL_k(d);
                        E_HA = params_temp.mu_efficiency * (1 - opt_vars_temp.rho_k(d)) * P_recv * t_DL;
                        
                        E_net = E_UL + E_CM - E_HA;
                        E_temp = E_temp + (E_net / (1 - tau_test)) / params_temp.num_realizations;
                    end
                end
                E_vs_tau_all(d_idx, idx) = E_temp;
            end
        end
        
        E_vs_tau_D2 = E_vs_tau_all(1, :);
        E_vs_tau_D4 = E_vs_tau_all(2, :);
        E_vs_tau_D6 = E_vs_tau_all(3, :);
        E_vs_tau_D8 = E_vs_tau_all(4, :);
        E_vs_tau_D10 = E_vs_tau_all(5, :);
        
        save(data_file_users, 'tau_range', 'E_vs_tau_D2', 'E_vs_tau_D4', 'E_vs_tau_D6', 'E_vs_tau_D8', 'E_vs_tau_D10', 'D_range');
    end
    
    figure('Position', [100, 100, 900, 600]);
    hold on;
    plot(tau_range, E_vs_tau_D2, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    plot(tau_range, E_vs_tau_D4, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
    plot(tau_range, E_vs_tau_D6, 'g-d', 'LineWidth', 2, 'MarkerSize', 6);
    plot(tau_range, E_vs_tau_D8, 'm-^', 'LineWidth', 2, 'MarkerSize', 6);
    plot(tau_range, E_vs_tau_D10, 'c-v', 'LineWidth', 2, 'MarkerSize', 6);
    hold off;
    grid on;
    xlabel('Local Accuracy (τ)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Effective Energy Consumption (J)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Energy vs Local Accuracy for Different Numbers of Users', 'FontSize', 16);
    legend('D = 2', 'D = 4', 'D = 6', 'D = 8', 'D = 10', 'Location', 'best');
    set(gca, 'FontSize', 12);
    
    fprintf('Plot 2: Energy vs Local Accuracy - Generated (2 figures)\n');
end