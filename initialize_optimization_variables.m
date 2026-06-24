function opt_vars = initialize_optimization_variables(params)
% FIXED VERSION: Better initialization to ensure initial feasibility

    opt_vars = struct();
    
    % CRITICAL FIX 1: Start with MORE power splitting to ID (less to EH)
    % This increases downlink rate capacity
    opt_vars.rho_k = 0.7 * ones(params.D, 1);  % INCREASED from 0.5 to 0.7
    
    % CRITICAL FIX 2: Start with LOWER transmit power to conserve energy
    opt_vars.vartheta_k = 0.2 * ones(params.D, 1);  % REDUCED from 0.3 to 0.2
    
    % CRITICAL FIX 3: Start with LOWER CPU frequency to reduce computation energy
    opt_vars.f_k = 1.5e9 * ones(params.D, 1);  % REDUCED from 2e9 to 1.5e9
    
    % CRITICAL FIX 4: Initialize beamformer with FULL power (not 50%)
    opt_vars.b_DL_k = sqrt(params.P_DL_max / params.A) * ...
                      (randn(params.A,1) + 1i*randn(params.A,1))/sqrt(2);
    opt_vars.b_DL_k = opt_vars.b_DL_k / norm(opt_vars.b_DL_k) * sqrt(params.P_DL_max);
    % Now using 100% of max power, not 50%!
    
    % CRITICAL FIX 5: Start with HIGHER rates (more realistic)
    opt_vars.r_UL_k = 1e5 * ones(params.D, 1);  % INCREASED from 1e4 to 1e5
    opt_vars.r_DL_k = 2e6 * ones(params.D, 1);  % INCREASED from 1e6 to 2e6
    
    % CRITICAL FIX 6: Start with RELAXED accuracy (less computation needed)
    opt_vars.tau_k = 0.05 * ones(params.D, 1);  % INCREASED from 0.01 to 0.05
    
    fprintf('========== Improved Initialization ==========\n');
    fprintf('Initial beamformer power: %.2f W (max: %.2f W) - NOW USING 100%%!\n', ...
            norm(opt_vars.b_DL_k)^2, params.P_DL_max);
    fprintf('\nInitial parameters:\n');
    fprintf('  rho (power split): %.2f (MORE to information decoding)\n', opt_vars.rho_k(1));
    fprintf('  vartheta (UL power): %.2f (REDUCED to save energy)\n', opt_vars.vartheta_k(1));
    fprintf('  f (CPU freq): %.2f GHz (REDUCED to save energy)\n', opt_vars.f_k(1)/1e9);
    fprintf('  r_UL: %.2e bps (INCREASED for realism)\n', opt_vars.r_UL_k(1));
    fprintf('  r_DL: %.2e bps (INCREASED for realism)\n', opt_vars.r_DL_k(1));
    fprintf('  tau (accuracy): %.3f (RELAXED to reduce computation)\n', opt_vars.tau_k(1));
    
    % Compute initial energy balance
    fprintf('\n--- Initial Energy Balance Check ---\n');
    for d = 1:min(3, params.D)
        % Uplink energy
        E_UL = params.u_max(d) * opt_vars.vartheta_k(d) * params.X_UL / opt_vars.r_UL_k(d);
        
        % Computation energy
        N_tau = params.varrho * log(1 / opt_vars.tau_k(d));
        E_CM = (params.upsilon/2) * N_tau * params.Z_d * params.Q_d * opt_vars.f_k(d)^2;
        
        % Consumed
        E_consumed = E_UL + E_CM;
        
        fprintf('Device %d: E_UL=%.3e, E_CM=%.3e, Total=%.3e J\n', ...
                d, E_UL, E_CM, E_consumed);
    end
    
    fprintf('Available battery: %.1f J\n', params.E_BA(1));
    fprintf('(Harvested energy will be computed during optimization)\n');
    fprintf('=============================================\n\n');
    
end