%DOCUMENT filename="plot_energy_vs_harvesting.m"
function plot_energy_vs_harvesting(params, all_channels, opt_vars)

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
    % Figure 1: Energy vs Harvesting Coefficient for Different Numbers of Antennas
    %===================================================================
    data_file_antennas = 'Results/Saved Files/energy_vs_harvesting_antennas_data.mat';
    
    if exist(data_file_antennas, 'file')
        load(data_file_antennas, 'mu_range', 'E_vs_mu_A16', 'E_vs_mu_A32', 'E_vs_mu_A64', 'E_vs_mu_A128', 'A_range');
    else
        fprintf('\n--- Computing energy vs harvesting coefficient for different antenna configurations ---\n');
        A_range = [16, 32, 64, 128];
        mu_range = linspace(0.1, 0.95, 20);  % Harvesting efficiency from 10% to 95%
        E_vs_mu_all = zeros(length(A_range), length(mu_range));
        
        for a_idx = 1:length(A_range)
            A_temp = A_range(a_idx);
            fprintf('Computing for A = %d...\n', A_temp);
            
            params_temp = params;
            params_temp.A = A_temp;
            
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            for idx = 1:length(mu_range)
                mu_test = mu_range(idx);
                E_temp = 0;
                
                for r = 1:params_temp.num_realizations
                    C = all_channels_temp{r};
                    for d = 1:params_temp.D
                        % Uplink energy
                        E_UL = params_temp.u_max(d) * opt_vars_temp.vartheta_k(d) * params_temp.X_UL / opt_vars_temp.r_UL_k(d);
                        
                        % Computation energy
                        N_tau = params_temp.varrho * log(1 / opt_vars_temp.tau_k(d));
                        E_CM = (params_temp.upsilon/2) * N_tau * params_temp.Z_d * params_temp.Q_d * opt_vars_temp.f_k(d)^2;
                        
                        % Harvested energy with test efficiency
                        c_d = C(:, d);
                        P_recv = abs(c_d' * opt_vars_temp.b_DL_k)^2;
                        t_DL = params_temp.X_DL / opt_vars_temp.r_DL_k(d);
                        E_HA = mu_test * (1 - opt_vars_temp.rho_k(d)) * P_recv * t_DL;
                        
                        % Effective energy
                        E_net = E_UL + E_CM - E_HA;
                        E_temp = E_temp + (E_net / (1 - opt_vars_temp.tau_k(d))) / params_temp.num_realizations;
                    end
                end
                E_vs_mu_all(a_idx, idx) = E_temp;
            end
        end
        
        E_vs_mu_A16 = E_vs_mu_all(1, :);
        E_vs_mu_A32 = E_vs_mu_all(2, :);
        E_vs_mu_A64 = E_vs_mu_all(3, :);
        E_vs_mu_A128 = E_vs_mu_all(4, :);
        
        save(data_file_antennas, 'mu_range', 'E_vs_mu_A16', 'E_vs_mu_A32', 'E_vs_mu_A64', 'E_vs_mu_A128', 'A_range');
    end
    
    figure();
    hold on;
    plot(mu_range, E_vs_mu_A16, '-o', 'LineStyle','-', 'LineWidth', 1.5, 'Color', 'b');
    plot(mu_range, E_vs_mu_A32, '--s', 'LineStyle','-.', 'LineWidth', 1.5, 'Color', 'b');
    plot(mu_range, E_vs_mu_A64, '-^', 'LineStyle',':', 'LineWidth', 1.5, 'Color', 'b');
    plot(mu_range, E_vs_mu_A128, '--d', 'LineStyle','--', 'LineWidth', 1.5, 'Color', 'b');
    hold off;
    grid on;
    xlabel('Energy Harvesting Efficiency', 'Interpreter', 'latex', 'FontSize',12);
    ylabel('Energy Consumption (J)', 'Interpreter', 'latex', 'FontSize',12);
    legend('A = 16', 'A = 32', 'A = 64', 'A = 128', 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);
    
    %===================================================================
    % Figure 2: Energy vs Harvesting Coefficient for Different Numbers of Users
    %===================================================================
    data_file_users = 'Results/Saved Files/energy_vs_harvesting_users_data.mat';
    
    if exist(data_file_users, 'file')
        load(data_file_users, 'mu_range', 'E_vs_mu_D2', 'E_vs_mu_D4', 'E_vs_mu_D6', 'E_vs_mu_D8', 'E_vs_mu_D10', 'D_range');
    else
        fprintf('\n--- Computing energy vs harvesting coefficient for different user configurations ---\n');
        D_range = [2, 4, 6, 8, 10];
        mu_range = linspace(0.1, 0.95, 20);  % Harvesting efficiency from 10% to 95%
        E_vs_mu_all = zeros(length(D_range), length(mu_range));
        
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
            
            for idx = 1:length(mu_range)
                mu_test = mu_range(idx);
                E_temp = 0;
                
                for r = 1:params_temp.num_realizations
                    C = all_channels_temp{r};
                    for d = 1:params_temp.D
                        % Uplink energy
                        E_UL = params_temp.u_max(d) * opt_vars_temp.vartheta_k(d) * params_temp.X_UL / opt_vars_temp.r_UL_k(d);
                        
                        % Computation energy
                        N_tau = params_temp.varrho * log(1 / opt_vars_temp.tau_k(d));
                        E_CM = (params_temp.upsilon/2) * N_tau * params_temp.Z_d * params_temp.Q_d * opt_vars_temp.f_k(d)^2;
                        
                        % Harvested energy with test efficiency
                        c_d = C(:, d);
                        P_recv = abs(c_d' * opt_vars_temp.b_DL_k)^2;
                        t_DL = params_temp.X_DL / opt_vars_temp.r_DL_k(d);
                        E_HA = mu_test * (1 - opt_vars_temp.rho_k(d)) * P_recv * t_DL;
                        
                        % Effective energy
                        E_net = E_UL + E_CM - E_HA;
                        E_temp = E_temp + (E_net / (1 - opt_vars_temp.tau_k(d))) / params_temp.num_realizations;
                    end
                end
                E_vs_mu_all(d_idx, idx) = E_temp;
            end
        end
        
        E_vs_mu_D2 = E_vs_mu_all(1, :);
        E_vs_mu_D4 = E_vs_mu_all(2, :);
        E_vs_mu_D6 = E_vs_mu_all(3, :);
        E_vs_mu_D8 = E_vs_mu_all(4, :);
        E_vs_mu_D10 = E_vs_mu_all(5, :);
        
        save(data_file_users, 'mu_range', 'E_vs_mu_D2', 'E_vs_mu_D4', 'E_vs_mu_D6', 'E_vs_mu_D8', 'E_vs_mu_D10', 'D_range');
    end
    
    figure('Position', [100, 100, 900, 600]);
    hold on;
    plot(mu_range, E_vs_mu_D2, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    plot(mu_range, E_vs_mu_D4, 'r-s', 'LineWidth', 2, 'MarkerSize', 6);
    plot(mu_range, E_vs_mu_D6, 'g-d', 'LineWidth', 2, 'MarkerSize', 6);
    plot(mu_range, E_vs_mu_D8, 'm-^', 'LineWidth', 2, 'MarkerSize', 6);
    plot(mu_range, E_vs_mu_D10, 'c-v', 'LineWidth', 2, 'MarkerSize', 6);
    hold off;
    grid on;
    xlabel('Energy Harvesting Efficiency (μ)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Effective Energy Consumption (J)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Energy Consumption vs Harvesting Efficiency for Different Numbers of Users', 'FontSize', 16);
    legend('D = 2', 'D = 4', 'D = 6', 'D = 8', 'D = 10', 'Location', 'best');
    set(gca, 'FontSize', 12);
    
    fprintf('Plot 7: Energy vs Harvesting Efficiency - Generated (2 figures)\n');
end