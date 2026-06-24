function [opt_vars, objective_history] = run_hierarchical_optimization(params, all_channels, opt_vars, max_outer_iter)
% VERSION WITH SLACK VARIABLES: Ensures initial feasibility
% Gradually tightens constraints across iterations

    if nargin < 4
        max_outer_iter = params.max_outer_iter;
    end
    
    % Extract parameters
    D = params.D;
    A = params.A;
    num_realizations = params.num_realizations;
    max_sca_iter = params.max_sca_iter;
    sca_tol = params.sca_tol;
    cd_tol = params.cd_tol;
    
    X_UL = params.X_UL;
    X_DL = params.X_DL;
    Q_d = params.Q_d;
    Z_d = params.Z_d;
    upsilon = params.upsilon;
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
    
    % Extract optimization variables
    rho_k = opt_vars.rho_k;
    vartheta_k = opt_vars.vartheta_k;
    f_k = opt_vars.f_k;
    b_DL_k = opt_vars.b_DL_k;
    r_UL_k = opt_vars.r_UL_k;
    r_DL_k = opt_vars.r_DL_k;
    tau_k = opt_vars.tau_k;
    
    %-------------------------------------------------------------------
    % Pre-compute MMSE Beamformers
    %-------------------------------------------------------------------
    fprintf('========== Pre-computing MMSE Beamformers ==========\n');
    Q_mmse_all = cell(num_realizations, 1);
    for r = 1:num_realizations
        C = all_channels{r};
        Q_mmse_all{r} = (C * C' + delta_n_sq * eye(A)) \ C;
    end
    fprintf('MMSE beamformers ready\n\n');
    
    objective_history = [];
    
    fprintf('========== Starting Optimization with Slack Variables ==========\n\n');
    
    %-------------------------------------------------------------------
    % Hierarchical Optimization Loop
    %-------------------------------------------------------------------
    for outer_iter = 1:max_outer_iter
        
        fprintf('=== Outer Iteration %d ===\n', outer_iter);
        
        % CRITICAL: Adaptive slack penalty (tightens over iterations)
        % Start with large slack, gradually reduce
        slack_penalty = 1000 * (1.1 ^ outer_iter);  % Exponentially increasing penalty
        
        %---------------------------------------------------------------
        % Short-Term Subproblem: SCA Loop
        %---------------------------------------------------------------
        for sca_iter = 1:max_sca_iter
            
            cvx_begin quiet
                
                variable rho_var(D)
                variable vartheta_var(D)
                variable f_var(D)
                variable b_DL_var(A) complex
                variable r_UL_var(D)
                variable r_DL_var(D)
                variable slack_var(D)  % SLACK VARIABLES for energy constraint
                
                obj_sum = 0;
                
                % Objective: Energy + PENALTY for slack
                for r = 1:num_realizations
                    C = all_channels{r};
                    
                    for d = 1:D
                        c_d = C(:, d);
                        N_tau_d = varrho * log(1 / tau_k(d));
                        
                        % Uplink energy (linearized)
                        E_UL_k = u_max(d) * vartheta_k(d) * X_UL / r_UL_k(d);
                        grad_vartheta = u_max(d) * X_UL / r_UL_k(d);
                        grad_r_ul = -u_max(d) * vartheta_k(d) * X_UL / (r_UL_k(d)^2);
                        E_UL = E_UL_k + grad_vartheta * (vartheta_var(d) - vartheta_k(d)) + ...
                               grad_r_ul * (r_UL_var(d) - r_UL_k(d));
                        
                        % Computation energy (linearized)
                        coeff_cm = (upsilon/2) * N_tau_d * Z_d * Q_d;
                        E_CM = coeff_cm * (f_k(d)^2 + 2*f_k(d)*(f_var(d) - f_k(d)));
                        
                        % Harvested energy (linearized)
                        P_recv_k = abs(c_d' * b_DL_k)^2;
                        t_DL_k = X_DL / r_DL_k(d);
                        E_HA_k = mu_efficiency * (1 - rho_k(d)) * P_recv_k * t_DL_k;
                        
                        grad_rho_ha = -mu_efficiency * P_recv_k * t_DL_k;
                        grad_b_ha = mu_efficiency * (1 - rho_k(d)) * t_DL_k * 2 * (c_d * conj(c_d' * b_DL_k));
                        grad_r_dl = mu_efficiency * (1 - rho_k(d)) * P_recv_k * (-X_DL / r_DL_k(d)^2);
                        
                        E_HA = E_HA_k + grad_rho_ha * (rho_var(d) - rho_k(d)) + ...
                               real(grad_b_ha' * (b_DL_var - b_DL_k)) + ...
                               grad_r_dl * (r_DL_var(d) - r_DL_k(d));
                        
                        E_net = E_UL + E_CM - E_HA;
                        obj_sum = obj_sum + E_net / (1 - tau_k(d));
                    end
                end
                
                % Add slack penalty to objective
                minimize( obj_sum / num_realizations + slack_penalty * sum(slack_var) )
                
                subject to
                
                % Basic bounds
                0 <= rho_var <= 1;  
                0 <= vartheta_var <= 1;
                f_min <= f_var <= f_max;
                1e3 <= r_UL_var <= 5e6;
                1e5 <= r_DL_var <= 5e6;
                slack_var >= 0;  % Slack must be non-negative
                
                % C1: BS power constraint
                norm(b_DL_var) <= sqrt(P_DL_max);
                
                % C5: Uplink rate constraints (RELAXED with small margin)
                for r = 1:num_realizations
                    C = all_channels{r};
                    Q_mmse = Q_mmse_all{r};
                    
                    for d = 1:D
                        c_d = C(:, d);
                        q_d = Q_mmse(:, d);
                        
                        signal_gain = abs(c_d' * q_d)^2;
                        noise_power = norm(q_d)^2 * delta_n_sq;
                        
                        interf_power = 0;
                        for m = 1:D
                            if m ~= d
                                c_m = C(:, m);
                                interf_power = interf_power + u_max(m) * vartheta_k(m) * abs(c_m' * q_d)^2;
                            end
                        end
                        
                        SINR_k = (u_max(d) * vartheta_k(d) * signal_gain) / (interf_power + noise_power + 1e-10);
                        
                        if SINR_k > 1e-8
                            rate_k = B_bandwidth * log2(1 + SINR_k);
                            grad_SINR = u_max(d) * signal_gain / (interf_power + noise_power + 1e-10);
                            grad_rate = (B_bandwidth / (log(2) * (1 + SINR_k))) * grad_SINR;
                            
                            % Relax by 10% to avoid numerical issues
                            r_UL_var(d) <= 0.9 * (rate_k + grad_rate * (vartheta_var(d) - vartheta_k(d)));
                        else
                            r_UL_var(d) <= 1e5;
                        end
                    end
                end
                
                % C6: Downlink rate constraints (RELAXED)
                for r = 1:num_realizations
                    C = all_channels{r};
                    for d = 1:D
                        c_d = C(:, d);
                        P_recv_k = abs(c_d' * b_DL_k)^2;
                        
                        SNR_k = (rho_k(d) * P_recv_k) / (rho_k(d) * delta_n_sq + kappa_sq + 1e-15);
                        
                        if SNR_k > 1e-8
                            rate_k = B_bandwidth * log2(1 + SNR_k);
                            
                            denom = rho_k(d) * delta_n_sq + kappa_sq + 1e-15;
                            grad_rho = (P_recv_k * kappa_sq) / (denom^2);
                            grad_b = 2 * rho_k(d) / denom * (c_d * conj(c_d' * b_DL_k));
                            grad_rate_rho = (B_bandwidth / (log(2) * (1 + SNR_k))) * grad_rho;
                            grad_rate_b = (B_bandwidth / (log(2) * (1 + SNR_k))) * grad_b;
                            
                            % Relax by 10%
                            r_DL_var(d) <= 0.9 * (rate_k + grad_rate_rho * (rho_var(d) - rho_k(d)) + ...
                                           real(grad_rate_b' * (b_DL_var - b_DL_k)));
                        else
                            r_DL_var(d) <= 1e6;
                        end
                    end
                end
                
                % C7: Energy feasibility WITH SLACK
                for d = 1:D
                    E_consumed_avg = 0;
                    E_harvested_avg = 0;
                    
                    for r = 1:num_realizations
                        C = all_channels{r};
                        c_d = C(:, d);
                        N_tau_d = varrho * log(1 / tau_k(d));
                        
                        % Uplink
                        E_UL_k = u_max(d) * vartheta_k(d) * X_UL / r_UL_k(d);
                        grad_vartheta_ul = u_max(d) * X_UL / r_UL_k(d);
                        grad_r_ul = -u_max(d) * vartheta_k(d) * X_UL / (r_UL_k(d)^2);
                        E_UL_lin = E_UL_k + grad_vartheta_ul * (vartheta_var(d) - vartheta_k(d)) + ...
                                   grad_r_ul * (r_UL_var(d) - r_UL_k(d));
                        
                        % Computation
                        coeff_cm = (upsilon/2) * N_tau_d * Z_d * Q_d;
                        E_CM_lin = coeff_cm * (f_k(d)^2 + 2*f_k(d)*(f_var(d) - f_k(d)));
                        
                        % Harvested
                        P_recv_k = abs(c_d' * b_DL_k)^2;
                        t_DL_k = X_DL / r_DL_k(d);
                        E_HA_k = mu_efficiency * (1 - rho_k(d)) * P_recv_k * t_DL_k;
                        
                        grad_rho_ha = -mu_efficiency * P_recv_k * t_DL_k;
                        grad_b_ha = mu_efficiency * (1 - rho_k(d)) * t_DL_k * 2 * (c_d * conj(c_d' * b_DL_k));
                        grad_r_dl_ha = mu_efficiency * (1 - rho_k(d)) * P_recv_k * (-X_DL / r_DL_k(d)^2);
                        
                        E_HA_lin = E_HA_k + grad_rho_ha * (rho_var(d) - rho_k(d)) + ...
                                   real(grad_b_ha' * (b_DL_var - b_DL_k)) + ...
                                   grad_r_dl_ha * (r_DL_var(d) - r_DL_k(d));
                        
                        E_consumed_avg = E_consumed_avg + (E_UL_lin + E_CM_lin) / num_realizations;
                        E_harvested_avg = E_harvested_avg + E_HA_lin / num_realizations;
                    end
                    
                    % Energy feasibility WITH SLACK
                    E_consumed_avg <= E_BA(d) + E_harvested_avg + slack_var(d);
                end
                
            cvx_end
            
            % Check status
            if strcmp(cvx_status, 'Solved') || strcmp(cvx_status, 'Inaccurate/Solved')
                current_obj = cvx_optval;
                
                rho_prev = rho_k;
                vartheta_prev = vartheta_k;
                f_prev = f_k;
                b_DL_prev = b_DL_k;
                r_UL_prev = r_UL_k;
                r_DL_prev = r_DL_k;
                
                rho_k = rho_var;
                vartheta_k = vartheta_var;
                f_k = f_var;
                r_UL_k = r_UL_var;
                r_DL_k = r_DL_var;
                b_DL_k = b_DL_var;
                
                change = norm([rho_k - rho_prev; vartheta_k - vartheta_prev; ...
                              f_k - f_prev; r_UL_k - r_UL_prev; r_DL_k - r_DL_prev]);
                
                % Show slack usage
                max_slack = max(slack_var);
                total_slack = sum(slack_var);
                
                if sca_iter <= 5 || mod(sca_iter, 10) == 0
                    fprintf('  SCA iter %d: Obj=%.6f J, Change=%.6e, Slack(max/total)=%.3e/%.3e\n', ...
                            sca_iter, cvx_optval, change, max_slack, total_slack);
                end
                
                if change < sca_tol
                    fprintf('  SCA converged! Final slack usage: max=%.3e, total=%.3e\n', max_slack, total_slack);
                    break;
                end
            else
                fprintf('  SCA iter %d: CVX %s\n', sca_iter, cvx_status);
                fprintf('  âš  Even with slack variables, problem is infeasible!\n');
                fprintf('  This suggests parameters are EXTREMELY incompatible.\n');
                fprintf('  Try AGGRESSIVE_FIX parameters!\n');
                break;
            end
        end
        
        %---------------------------------------------------------------
        % Long-Term: CD for tau (same as before)
        %---------------------------------------------------------------
        if strcmp(cvx_status, 'Solved') || strcmp(cvx_status, 'Inaccurate/Solved')
            tau_prev = tau_k;
            
            a_d = zeros(D, 1);
            b_d = zeros(D, 1);
            
            for r = 1:num_realizations
                C = all_channels{r};
                for d = 1:D
                    E_UL = u_max(d) * vartheta_k(d) * X_UL / r_UL_k(d);
                    c_d = C(:, d);
                    P_recv = abs(c_d' * b_DL_k)^2;
                    t_DL = X_DL / r_DL_k(d);
                    E_HA = mu_efficiency * (1 - rho_k(d)) * P_recv * t_DL;
                    
                    a_d(d) = a_d(d) + (E_UL - E_HA) / num_realizations;
                    b_d(d) = b_d(d) + ((upsilon/2) * Z_d * Q_d * f_k(d)^2 * varrho) / num_realizations;
                end
            end
            
            for cd_iter = 1:50
                max_change = 0;
                for d = 1:D
                    tau_d = tau_k(d);
                    
                    tau_lower = max(tau_min, 1e-5);
                    tau_upper = min(tau_max, 0.2);
                    
                    numerator = a_d(d) + b_d(d) * log(1/tau_d);
                    denominator = 1 - tau_d;
                    
                    d_num = -b_d(d) / tau_d;
                    d_den = -1;
                    grad = (d_num * denominator - numerator * d_den) / (denominator^2);
                    
                    if abs(grad) < 0.1
                        step_size = 0.005;
                    elseif abs(grad) < 1
                        step_size = 0.002;
                    else
                        step_size = 0.001;
                    end
                    
                    tau_new = tau_d - step_size * grad;
                    tau_new = max(tau_lower, min(tau_upper, tau_new));
                    
                    change_d = abs(tau_new - tau_d);
                    max_change = max(max_change, change_d);
                    
                    tau_k(d) = tau_new;
                end
                
                if max_change < cd_tol
                    break;
                end
            end
        end
        
        if strcmp(cvx_status, 'Solved') || strcmp(cvx_status, 'Inaccurate/Solved')
            objective_history(end+1) = cvx_optval; %#ok<AGROW>
        else
            fprintf('\n*** FAILED at outer iteration %d ***\n', outer_iter);
            break;
        end
        
        if outer_iter > 5 && length(objective_history) >= 2
            recent_change = abs(objective_history(end) - objective_history(end-1));
            if recent_change < 1e-5
                fprintf('\n*** CONVERGED at iteration %d ***\n', outer_iter);
                break;
            end
        end
    end
    
    % Store results
    opt_vars.rho_k = rho_k;
    opt_vars.vartheta_k = vartheta_k;
    opt_vars.f_k = f_k;
    opt_vars.b_DL_k = b_DL_k;
    opt_vars.r_UL_k = r_UL_k;
    opt_vars.r_DL_k = r_DL_k;
    opt_vars.tau_k = tau_k;
    
end