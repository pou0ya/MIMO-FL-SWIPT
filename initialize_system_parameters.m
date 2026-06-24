function params = initialize_system_parameters()
% AGGRESSIVE FIX: Multiple parameter adjustments to ensure feasibility
% This addresses ALL potential infeasibility sources

    params = struct();
    
    % Network Parameters
    params.D = 8;              % Number of UEs
    params.A = 64;             % Number of BS antennas
    
    % FL Parameters - SIGNIFICANTLY REDUCED COMPUTATIONAL LOAD
    params.X_UL = 5e6;         % Uplink data size (bits) - keep same
    params.X_DL = 5e6;         % Downlink data size (bits) - keep same
    params.Q_d = 10;           % REDUCED from 20 to 10 (50% less computation!)
    params.Z_d = 5e6;          % REDUCED from 10e6 to 5e6 (50% less cycles!)
    params.upsilon = 2e-28;    % Switched capacitance coefficient
    
    % Power Parameters
    params.P_DL_max = 10^(50/10)/1000;  % BS max power: 100 W (50 dBm)
    params.u_max = 10^(-10/10)/1000 * ones(params.D,1);  % UE: 0.1 mW (-10 dBm)
    params.delta_n_sq = 10^(-75/10)/1000;  % Noise variance: -75 dBm
    params.kappa_sq = 10^(-85/10)/1000;    % ID conversion noise: -85 dBm
    
    % SWIPT Parameters - MAXIMUM EFFICIENCY
    params.mu_efficiency = 0.9;  % INCREASED to 0.9 (maximum realistic value)
    
    % FL Accuracy Parameters - RELAXED BOUNDS
    params.varrho = 1;           
    params.omega_target = 1e-2;  
    params.tau_min = 1e-4;       % VERY RELAXED from 1e-6
    params.tau_max = 0.2;        % VERY RELAXED from 0.1
    
    % Battery Energy - INCREASED
    params.E_BA = 25 * ones(params.D,1);  % INCREASED from 15 to 25 J
    
    % Communication Parameters
    params.B_bandwidth = 20e6;   % Bandwidth: 20 MHz
    
    % CPU Frequency Bounds - LOWER to reduce energy
    params.f_min = 0.8e9 * ones(params.D,1);   % REDUCED from 1 GHz
    params.f_max = 2.5e9 * ones(params.D,1);   % REDUCED from 3 GHz
    
    % Channel Model Parameters - CRITICAL: MUCH LOWER PATH LOSS
    params.d0 = 10;             % Reference distance: 10 m
    params.d1 = 50;             % Breakpoint distance: 50 m
    params.L = 100;             % *** REDUCED from 140 to 100 dB ***
                                % This is LOS urban scenario
    params.sigma_sh = 6;        % REDUCED shadowing variance (less random attenuation)
    
    % Simulation Parameters
    params.num_realizations = 1;
    params.max_outer_iter = 20;
    params.max_sca_iter = 30;
    params.sca_tol = 1e-5;
    params.cd_tol = 1e-6;
    
    % Display
    fprintf('========== AGGRESSIVE FIX Parameters ==========\n');
    fprintf('Network: D=%d UEs, A=%d BS antennas\n', params.D, params.A);
    fprintf('Power: BS=%.1f W, UE=%.3f mW\n', params.P_DL_max, params.u_max(1)*1000);
    fprintf('Channel: L=%.0f dB (LOS urban - VERY LOW path loss)\n', params.L);
    fprintf('Energy: mu=%.2f, E_BA=%.0f J per device\n', params.mu_efficiency, params.E_BA(1));
    fprintf('Computation: Q_d=%d, Z_d=%.0e (50%% reduction!)\n', params.Q_d, params.Z_d);
    fprintf('CPU freq: [%.1f, %.1f] GHz (reduced range)\n', params.f_min(1)/1e9, params.f_max(1)/1e9);
    fprintf('Tau bounds: [%.0e, %.2f] (very relaxed)\n', params.tau_min, params.tau_max);
    fprintf('=============================================\n\n');
    
    % Energy budget estimate
    E_CM_typical = (params.upsilon/2) * log(1/0.01) * params.Z_d * params.Q_d * (2e9)^2;
    E_UL_typical = params.u_max(1) * 0.5 * params.X_UL / 1e5;
    fprintf('Estimated energy consumption: %.3f J\n', E_CM_typical + E_UL_typical);
    fprintf('Available battery energy: %.0f J\n', params.E_BA(1));
    fprintf('Required harvested energy: ~%.1f J (for 50%% margin)\n\n', ...
            max(0, (E_CM_typical + E_UL_typical)*1.5 - params.E_BA(1)));
    
end