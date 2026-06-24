function display_final_results(params, all_channels, opt_vars)

    fprintf('\n========== FINAL RESULTS ==========\n\n');
    
    % Extract parameters
    D = params.D;
    num_realizations = params.num_realizations;
    X_UL = params.X_UL;
    X_DL = params.X_DL;
    Q_d = params.Q_d;
    Z_d = params.Z_d;
    upsilon = params.upsilon;
    varrho = params.varrho;
    mu_efficiency = params.mu_efficiency;
    u_max = params.u_max;
    
    % Extract optimized variables
    rho_k = opt_vars.rho_k;
    vartheta_k = opt_vars.vartheta_k;
    f_k = opt_vars.f_k;
    b_DL_k = opt_vars.b_DL_k;
    r_UL_k = opt_vars.r_UL_k;
    r_DL_k = opt_vars.r_DL_k;
    tau_k = opt_vars.tau_k;
    
    % Initialize energy arrays
    E_eff_total = 0;
    E_UL_avg = zeros(D, 1);
    E_CM_avg = zeros(D, 1);
    E_HA_avg = zeros(D, 1);
    
    % Calculate energy consumption for each device
    for r = 1:num_realizations
        C = all_channels{r};
        for d = 1:D
            % Uplink transmission energy
            E_UL = u_max(d) * vartheta_k(d) * X_UL / r_UL_k(d);
            
            % Computation energy
            N_tau = varrho * log(1 / tau_k(d));
            E_CM = (upsilon/2) * N_tau * Z_d * Q_d * f_k(d)^2;
            
            % Harvested energy
            c_d = C(:, d);
            P_recv = abs(c_d' * b_DL_k)^2;
            t_DL = X_DL / r_DL_k(d);
            E_HA = mu_efficiency * (1 - rho_k(d)) * P_recv * t_DL;
            
            % Accumulate average energy per device
            E_UL_avg(d) = E_UL_avg(d) + E_UL / num_realizations;
            E_CM_avg(d) = E_CM_avg(d) + E_CM / num_realizations;
            E_HA_avg(d) = E_HA_avg(d) + E_HA / num_realizations;
            
            % Calculate net energy and accumulate effective total
            E_net = E_UL + E_CM - E_HA;
            E_eff_total = E_eff_total + (E_net / (1 - tau_k(d))) / num_realizations;
        end
    end
    
    % Display ergodic effective energy
    fprintf('Ergodic Effective Energy: %.6f J\n\n', E_eff_total);
    
    % Display detailed results table
    fprintf('Device |   ρ    |   ϑ    | f(GHz) |   τ     | E_UL   | E_CM   | E_HA   | r_UL | r_DL\n');
    fprintf('-------|--------|--------|--------|---------|--------|--------|--------|------|------\n');
    for d = 1:D
        fprintf('  %2d   | %.4f | %.4f | %.4f | %.6f | %.4f | %.4f | %.4f | %.2f | %.2f\n', ...
            d, rho_k(d), vartheta_k(d), f_k(d)/1e9, tau_k(d), ...
            E_UL_avg(d), E_CM_avg(d), E_HA_avg(d), r_UL_k(d)/1e6, r_DL_k(d)/1e6);
    end
    
    % Additional summary statistics
    fprintf('\n--- Summary Statistics ---\n');
    fprintf('Total Uplink Energy:       %.6f J\n', sum(E_UL_avg));
    fprintf('Total Computation Energy:  %.6f J\n', sum(E_CM_avg));
    fprintf('Total Harvested Energy:    %.6f J\n', sum(E_HA_avg));
    fprintf('Net Energy Consumption:    %.6f J\n', sum(E_UL_avg) + sum(E_CM_avg) - sum(E_HA_avg));
    fprintf('Average per device:        %.6f J\n', E_eff_total / D);
    
    % Display beamformer information
    fprintf('\n--- Beamformer Information ---\n');
    fprintf('Beamformer power:          %.4f W (%.2f%% of max)\n', ...
            norm(b_DL_k)^2, 100*norm(b_DL_k)^2/params.P_DL_max);
    fprintf('Maximum BS power:          %.4f W\n', params.P_DL_max);
    
end