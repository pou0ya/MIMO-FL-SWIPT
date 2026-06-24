%DOCUMENT filename="plot_energy_vs_users.m"
function plot_energy_vs_users(params)

    fprintf('\n========== Generating Plot 4: Energy vs Number of Users ==========\n');
    
    % Create directory structure if it doesn't exist
    if ~exist('Results/Saved Files', 'dir')
        mkdir('Results/Saved Files');
    end
    
    data_file = 'Results/Saved Files/energy_vs_users_data.mat';
    
    % Check if data file exists and contains the correct variables
    regenerate_data = true;
    if exist(data_file, 'file')
        loaded_data = load(data_file);
        if isfield(loaded_data, 'E_vs_D_with_SWIPT') && isfield(loaded_data, 'E_vs_D_without_SWIPT')
            D_range = loaded_data.D_range;
            E_vs_D_with_SWIPT = loaded_data.E_vs_D_with_SWIPT;
            E_vs_D_without_SWIPT = loaded_data.E_vs_D_without_SWIPT;
            regenerate_data = false;
        else
            fprintf('Old data file detected. Regenerating with baselines...\n');
        end
    end
    
    if regenerate_data
        D_range = [2, 4, 6, 8, 10];
        E_vs_D_with_SWIPT = zeros(size(D_range));
        E_vs_D_without_SWIPT = zeros(size(D_range));
        
        for d_idx = 1:length(D_range)
            D_temp = D_range(d_idx);
            
            % ===== With SWIPT (Proposed) =====
            fprintf('\n--- Running optimization for D = %d WITH SWIPT ---\n', D_temp);
            
            % Create temporary params with varying D
            params_temp = params;
            params_temp.D = D_temp;
            params_temp.u_max = 10^(-10/10)/1000 * ones(D_temp,1);
            params_temp.E_BA = 15 * ones(D_temp,1);
            params_temp.f_min = 1e9 * ones(D_temp,1);
            params_temp.f_max = 3e9 * ones(D_temp,1);
            
            % Generate channels for this configuration
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            
            % Initialize and optimize
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            % Calculate final energy
            E_eff_total = calculate_total_energy(params_temp, all_channels_temp, opt_vars_temp);
            E_vs_D_with_SWIPT(d_idx) = E_eff_total;
            
            fprintf('D = %d WITH SWIPT: Energy = %.6f J\n', D_temp, E_eff_total);
            
            % ===== Without SWIPT =====
            fprintf('\n--- Running optimization for D = %d WITHOUT SWIPT ---\n', D_temp);
            
            % Disable SWIPT by setting harvesting efficiency to 0
            params_temp.mu_efficiency = 0;
            
            % Generate channels for this configuration
            [all_channels_temp, ~] = generate_channel_realizations(params_temp);
            
            % Initialize and optimize
            opt_vars_temp = initialize_optimization_variables(params_temp);
            [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
            
            % Calculate final energy
            E_eff_total = calculate_total_energy(params_temp, all_channels_temp, opt_vars_temp);
            E_vs_D_without_SWIPT(d_idx) = E_eff_total;
            
            fprintf('D = %d WITHOUT SWIPT: Energy = %.6f J\n', D_temp, E_eff_total);
        end
        
        save(data_file, 'D_range', 'E_vs_D_with_SWIPT', 'E_vs_D_without_SWIPT');
    end
    
    % Plot results
    figure('Position', [100, 100, 800, 600]);
    hold on;
    plot(D_range, E_vs_D_with_SWIPT, 'b-o', 'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    plot(D_range, E_vs_D_without_SWIPT, 'r--s', 'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    hold off;
    grid on;
    xlabel('Number of Users (D)', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Effective Energy Consumption (J)', 'FontSize', 14, 'FontWeight', 'bold');
    title('Energy Consumption vs Number of Users', 'FontSize', 16);
    legend('With SWIPT (Proposed)', 'Without SWIPT', 'Location', 'northwest', 'FontSize', 12);
    set(gca, 'FontSize', 12);
    
    fprintf('Plot 4: Energy vs Number of Users - Generated\n');
end