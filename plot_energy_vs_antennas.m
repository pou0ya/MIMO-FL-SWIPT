%DOCUMENT filename="plot_energy_vs_antennas.m"
function plot_energy_vs_antennas(params)

    fprintf('\n========== Generating Plot 5: Energy vs Number of Antennas ==========\n');
    
    % Create directory structure if it doesn't exist
    if ~exist('Results/Saved Files', 'dir')
        mkdir('Results/Saved Files');
    end
    
    data_file = 'Results/Saved Files/energy_vs_antennas_data.mat';
    
    % Check if data file exists and contains the correct variables
    regenerate_data = true;
    if exist(data_file, 'file')
        loaded_data = load(data_file);
        if isfield(loaded_data, 'A_range') && isfield(loaded_data, 'D_values') && ...
           isfield(loaded_data, 'E_matrix_with_SWIPT') && isfield(loaded_data, 'E_matrix_without_SWIPT')
            A_range = loaded_data.A_range;
            D_values = loaded_data.D_values;
            E_matrix_with_SWIPT = loaded_data.E_matrix_with_SWIPT;
            E_matrix_without_SWIPT = loaded_data.E_matrix_without_SWIPT;
            regenerate_data = false;
        else
            fprintf('Old data file detected. Regenerating with multiple D baselines...\n');
        end
    end
    
    if regenerate_data
        A_range = [16, 32, 64, 128];
        D_values = [2, 4, 6];
        
        % Initialize energy matrices: rows = D_values, columns = A_range
        E_matrix_with_SWIPT = zeros(length(D_values), length(A_range));
        E_matrix_without_SWIPT = zeros(length(D_values), length(A_range));
        
        for d_idx = 1:length(D_values)
            D_temp = D_values(d_idx);
            
            for a_idx = 1:length(A_range)
                A_temp = A_range(a_idx);
                
                % ===== With SWIPT (Proposed) =====
                fprintf('\n--- Running optimization for D=%d, A=%d WITH SWIPT ---\n', D_temp, A_temp);
                
                % Create temporary params with varying D and A
                params_temp = params;
                params_temp.D = D_temp;
                params_temp.A = A_temp;
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
                E_matrix_with_SWIPT(d_idx, a_idx) = E_eff_total;
                
                fprintf('D=%d, A=%d WITH SWIPT: Energy = %.6f J\n', D_temp, A_temp, E_eff_total);
                
                % ===== Without SWIPT =====
                fprintf('\n--- Running optimization for D=%d, A=%d WITHOUT SWIPT ---\n', D_temp, A_temp);
                
                % Disable SWIPT by setting harvesting efficiency to 0
                params_temp.mu_efficiency = 0;
                
                % Generate channels for this configuration
                [all_channels_temp, ~] = generate_channel_realizations(params_temp);
                
                % Initialize and optimize
                opt_vars_temp = initialize_optimization_variables(params_temp);
                [opt_vars_temp, ~] = run_hierarchical_optimization(params_temp, all_channels_temp, opt_vars_temp, 15);
                
                % Calculate final energy
                E_eff_total = calculate_total_energy(params_temp, all_channels_temp, opt_vars_temp);
                E_matrix_without_SWIPT(d_idx, a_idx) = E_eff_total;
                
                fprintf('D=%d, A=%d WITHOUT SWIPT: Energy = %.6f J\n', D_temp, A_temp, E_eff_total);
            end
        end
        
        save(data_file, 'A_range', 'D_values', 'E_matrix_with_SWIPT', 'E_matrix_without_SWIPT');
        fprintf('Data saved to %s\n', data_file);
    end
    
    % Plot results
    figure();
    hold on;
    
    % Define colors and markers for different D values
    colors = {'b', 'r', 'g'};
    markers_with = {'o', 's', 'd'};
    markers_without = {'^', 'v', 'p'};
    
    % Plot each D value with both SWIPT and without SWIPT
    legend_entries = {};
    for d_idx = 1:length(D_values)
        D_val = D_values(d_idx);
        
        % With SWIPT (solid line)
        plot(A_range, E_matrix_with_SWIPT(d_idx, :), ...
             [colors{d_idx} '-' markers_with{d_idx}], ...
             'LineWidth', 1, 'MarkerSize', 10, ...
             'MarkerFaceColor', colors{d_idx});
        legend_entries{end+1} = sprintf('D=%d, With SWIPT', D_val);
        
        % Without SWIPT (dashed line)
        plot(A_range, E_matrix_without_SWIPT(d_idx, :), ...
             [colors{d_idx} '--' markers_without{d_idx}], ...
             'LineWidth', 1, 'MarkerSize', 10, ...
             'MarkerFaceColor', colors{d_idx});
        legend_entries{end+1} = sprintf('D=%d, Without SWIPT', D_val);
    end
    
    hold off;
    grid on;
    xlabel('Number of BS Antennas', 'Interpreter', 'latex', 'FontSize',12);
    ylabel('Energy Consumption (J)', 'Interpreter', 'latex', 'FontSize',12);
    yticks(0:0.1:0.4)
    ylim([0 0.4])
    xticks(16:16:128)
    xlim([16 128])
    legend(legend_entries, 'Location', 'best', 'Interpreter', 'latex', 'FontSize', 10);   
    fprintf('Plot 5: Energy vs Number of Antennas - Generated\n');
end