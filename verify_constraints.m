function verify_constraints(params, all_channels, opt_vars)

    fprintf('\n========== CONSTRAINT VERIFICATION ==========\n\n');
    
    % Extract parameters
    D = params.D;
    A = params.A;
    num_realizations = params.num_realizations;
    P_DL_max = params.P_DL_max;
    u_max = params.u_max;
    delta_n_sq = params.delta_n_sq;
    kappa_sq = params.kappa_sq;
    mu_efficiency = params.mu_efficiency;
    varrho = params.varrho;
    E_BA = params.E_BA;
    B_bandwidth = params.B_bandwidth;
    f_min = params.f_min;
    f_max = params.f_max;
    tau_min = params.tau_min;
    tau_max = params.tau_max;
    X_UL = params.X_UL;
    X_DL = params.X_DL;
    Q_d = params.Q_d;
    Z_d = params.Z_d;
    upsilon = params.upsilon;
    
    % Extract optimized variables
    rho_k = opt_vars.rho_k;
    vartheta_k = opt_vars.vartheta_k;
    f_k = opt_vars.f_k;
    b_DL_k = opt_vars.b_DL_k;
    r_UL_k = opt_vars.r_UL_k;
    r_DL_k = opt_vars.r_DL_k;
    tau_k = opt_vars.tau_k;
    
    % Initialize violation tracking
    violation_count = 0;
    max_violation = 0;
    tolerance = 1e-4;
    
    % Calculate average energy components for C7
    E_UL_avg = zeros(D, 1);
    E_CM_avg = zeros(D, 1);
    E_HA_avg = zeros(D, 1);
    
    for r = 1:num_realizations
        C = all_channels{r};
        for d = 1:D
            % Uplink energy
            E_UL = u_max(d) * vartheta_k(d) * X_UL / r_UL_k(d);
            
            % Computation energy
            N_tau = varrho * log(1 / tau_k(d));
            E_CM = (upsilon/2) * N_tau * Z_d * Q_d * f_k(d)^2;
            
            % Harvested energy
            c_d = C(:, d);
            P_recv = abs(c_d' * b_DL_k)^2;
            t_DL = X_DL / r_DL_k(d);
            E_HA = mu_efficiency * (1 - rho_k(d)) * P_recv * t_DL;
            
            E_UL_avg(d) = E_UL_avg(d) + E_UL / num_realizations;
            E_CM_avg(d) = E_CM_avg(d) + E_CM / num_realizations;
            E_HA_avg(d) = E_HA_avg(d) + E_HA / num_realizations;
        end
    end
    
    %-------------------------------------------------------------------
    % C1: BS Downlink Power Constraint
    %-------------------------------------------------------------------
    fprintf('C1: BS Downlink Power Constraint\n');
    P_BS = norm(b_DL_k)^2;
    C1_violation = max(0, P_BS - P_DL_max);
    max_violation = max(max_violation, C1_violation);
    
    if C1_violation > tolerance
        fprintf('  [VIOLATED] ||b||^2 = %.4f W > P_DL_max = %.4f W (violation: %.6e W)\n', ...
            P_BS, P_DL_max, C1_violation);
        violation_count = violation_count + 1;
    else
        fprintf('  [OK] ||b||^2 = %.4f W <= P_DL_max = %.4f W\n', P_BS, P_DL_max);
    end
    
    %-------------------------------------------------------------------
    % C2: UE Power Adjustment Coefficient Bounds
    %-------------------------------------------------------------------
    fprintf('\nC2: UE Power Adjustment Coefficient (ϑ) Bounds\n');
    for d = 1:D
        C2_low = max(0, -vartheta_k(d));
        C2_high = max(0, vartheta_k(d) - 1);
        C2_violation = C2_low + C2_high;
        max_violation = max(max_violation, C2_violation);
        
        if C2_violation > tolerance
            fprintf('  [VIOLATED] Device %d: ϑ = %.6f not in [0, 1] (violation: %.6e)\n', ...
                d, vartheta_k(d), C2_violation);
            violation_count = violation_count + 1;
        else
            fprintf('  [OK] Device %d: 0 <= ϑ = %.6f <= 1\n', d, vartheta_k(d));
        end
    end
    
    %-------------------------------------------------------------------
    % C3: CPU Frequency Bounds
    %-------------------------------------------------------------------
    fprintf('\nC3: CPU Frequency Bounds\n');
    for d = 1:D
        C3_low = max(0, f_min(d) - f_k(d));
        C3_high = max(0, f_k(d) - f_max(d));
        C3_violation = C3_low + C3_high;
        max_violation = max(max_violation, C3_violation);
        
        if C3_violation > tolerance
            fprintf('  [VIOLATED] Device %d: f = %.4f GHz not in [%.2f, %.2f] GHz (violation: %.6e Hz)\n', ...
                d, f_k(d)/1e9, f_min(d)/1e9, f_max(d)/1e9, C3_violation);
            violation_count = violation_count + 1;
        else
            fprintf('  [OK] Device %d: %.2f <= f = %.4f <= %.2f GHz\n', ...
                d, f_min(d)/1e9, f_k(d)/1e9, f_max(d)/1e9);
        end
    end
    
    %-------------------------------------------------------------------
    % C4: Power-Splitting Ratio Bounds
    %-------------------------------------------------------------------
    fprintf('\nC4: Power-Splitting Ratio (ρ) Bounds\n');
    for d = 1:D
        C4_low = max(0, -rho_k(d));
        C4_high = max(0, rho_k(d) - 1);
        C4_violation = C4_low + C4_high;
        max_violation = max(max_violation, C4_violation);
        
        if C4_violation > tolerance
            fprintf('  [VIOLATED] Device %d: ρ = %.6f not in [0, 1] (violation: %.6e)\n', ...
                d, rho_k(d), C4_violation);
            violation_count = violation_count + 1;
        else
            fprintf('  [OK] Device %d: 0 <= ρ = %.6f <= 1\n', d, rho_k(d));
        end
    end
    
    %-------------------------------------------------------------------
    % C5: Uplink Rate Constraint
    %-------------------------------------------------------------------
    fprintf('\nC5: Uplink Rate Constraints (r_UL <= R_UL)\n');
    for r = 1:num_realizations
        C = all_channels{r};
        Q_mmse = (C*C' + delta_n_sq*eye(A))^(-1) * C;
        
        for d = 1:D
            c_d = C(:, d);
            q_d = Q_mmse(:, d);
            
            % Compute SINR
            signal_power = u_max(d) * vartheta_k(d) * abs(c_d' * q_d)^2;
            
            % Interference from other UEs
            interference = 0;
            for m = 1:D
                if m ~= d
                    c_m = C(:, m);
                    interference = interference + u_max(m) * vartheta_k(m) * abs(c_m' * q_d)^2;
                end
            end
            
            noise_power = norm(q_d)^2 * delta_n_sq;
            SINR_UL = signal_power / (interference + noise_power);
            R_UL_achievable = B_bandwidth * log2(1 + SINR_UL);
            
            C5_violation = max(0, r_UL_k(d) - R_UL_achievable);
            max_violation = max(max_violation, C5_violation);
            
            if r == 1  % Only print for first realization
                if C5_violation > tolerance * 1e6  % Scale for rate units
                    fprintf('  [VIOLATED] Device %d: r_UL = %.4f Mbps > R_UL = %.4f Mbps (violation: %.4f kbps)\n', ...
                        d, r_UL_k(d)/1e6, R_UL_achievable/1e6, C5_violation/1e3);
                    violation_count = violation_count + 1;
                else
                    fprintf('  [OK] Device %d: r_UL = %.4f <= R_UL = %.4f Mbps (SINR = %.2f dB)\n', ...
                        d, r_UL_k(d)/1e6, R_UL_achievable/1e6, 10*log10(SINR_UL));
                end
            end
        end
    end
    
    %-------------------------------------------------------------------
    % C6: Downlink Rate Constraint
    %-------------------------------------------------------------------
    fprintf('\nC6: Downlink Rate Constraints (r_DL <= R_DL)\n');
    for r = 1:num_realizations
        C = all_channels{r};
        
        for d = 1:D
            c_d = C(:, d);
            P_recv = abs(c_d' * b_DL_k)^2;
            
            % Downlink SNR
            SNR_DL = (rho_k(d) * P_recv) / (rho_k(d) * delta_n_sq + kappa_sq);
            R_DL_achievable = B_bandwidth * log2(1 + SNR_DL);
            
            C6_violation = max(0, r_DL_k(d) - R_DL_achievable);
            max_violation = max(max_violation, C6_violation);
            
            if r == 1  % Only print for first realization
                if C6_violation > tolerance * 1e6  % Scale for rate units
                    fprintf('  [VIOLATED] Device %d: r_DL = %.4f Mbps > R_DL = %.4f Mbps (violation: %.4f kbps)\n', ...
                        d, r_DL_k(d)/1e6, R_DL_achievable/1e6, C6_violation/1e3);
                    violation_count = violation_count + 1;
                else
                    fprintf('  [OK] Device %d: r_DL = %.4f <= R_DL = %.4f Mbps (SNR = %.2f dB)\n', ...
                        d, r_DL_k(d)/1e6, R_DL_achievable/1e6, 10*log10(SNR_DL));
                end
            end
        end
    end
    
    %-------------------------------------------------------------------
    % C7: Energy Feasibility Constraint
    %-------------------------------------------------------------------
    fprintf('\nC7: Energy Feasibility (E_UL + E_CM <= E_BA + E_HA)\n');
    for d = 1:D
        E_consumed = E_UL_avg(d) + E_CM_avg(d);
        E_available = E_BA(d) + E_HA_avg(d);
        C7_violation = max(0, E_consumed - E_available);
        max_violation = max(max_violation, C7_violation);
        
        if C7_violation > tolerance
            fprintf('  [VIOLATED] Device %d: E_consumed = %.6f J > E_available = %.6f J (deficit: %.6f J)\n', ...
                d, E_consumed, E_available, C7_violation);
            fprintf('             Details: E_UL=%.6f + E_CM=%.6f vs E_BA=%.6f + E_HA=%.6f\n', ...
                E_UL_avg(d), E_CM_avg(d), E_BA(d), E_HA_avg(d));
            violation_count = violation_count + 1;
        else
            E_surplus = E_available - E_consumed;
            fprintf('  [OK] Device %d: E_consumed = %.6f <= E_available = %.6f J (surplus: %.6f J)\n', ...
                d, E_consumed, E_available, E_surplus);
            fprintf('       Details: (UL: %.6f + CM: %.6f) <= (BA: %.6f + HA: %.6f)\n', ...
                E_UL_avg(d), E_CM_avg(d), E_BA(d), E_HA_avg(d));
        end
    end
    
    %-------------------------------------------------------------------
    % C8: Local Accuracy Bounds
    %-------------------------------------------------------------------
    fprintf('\nC8: Local Accuracy (τ) Bounds\n');
    for d = 1:D
        C8_low = max(0, tau_min - tau_k(d));
        C8_high = max(0, tau_k(d) - tau_max);
        C8_violation = C8_low + C8_high;
        max_violation = max(max_violation, C8_violation);
        
        if C8_violation > tolerance
            fprintf('  [VIOLATED] Device %d: τ = %.6f not in [%.6f, %.6f] (violation: %.6e)\n', ...
                d, tau_k(d), tau_min, tau_max, C8_violation);
            violation_count = violation_count + 1;
        else
            fprintf('  [OK] Device %d: %.6f <= τ = %.6f <= %.6f\n', ...
                d, tau_min, tau_k(d), tau_max);
        end
    end
    
    %-------------------------------------------------------------------
    % Summary
    %-------------------------------------------------------------------
    fprintf('\n========== CONSTRAINT SUMMARY ==========\n');
    fprintf('Total constraints checked: 8 categories\n');
    fprintf('Constraints violated: %d\n', violation_count);
    fprintf('Maximum violation magnitude: %.6e\n', max_violation);
    
    if violation_count == 0
        fprintf('Status: ALL CONSTRAINTS SATISFIED ✓\n');
    else
        fprintf('Status: %d CONSTRAINT(S) VIOLATED ✗\n', violation_count);
    end
    
end