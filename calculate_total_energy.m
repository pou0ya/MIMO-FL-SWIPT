function E_eff_total = calculate_total_energy(params, all_channels, opt_vars)

    E_eff_total = 0;
    
    for r = 1:params.num_realizations
        C = all_channels{r};
        for d = 1:params.D
            % Uplink energy
            E_UL = params.u_max(d) * opt_vars.vartheta_k(d) * params.X_UL / opt_vars.r_UL_k(d);
            
            % Computation energy
            N_tau = params.varrho * log(1 / opt_vars.tau_k(d));
            E_CM = (params.upsilon/2) * N_tau * params.Z_d * params.Q_d * opt_vars.f_k(d)^2;
            
            % Harvested energy
            c_d = C(:, d);
            P_recv = abs(c_d' * opt_vars.b_DL_k)^2;
            t_DL = params.X_DL / opt_vars.r_DL_k(d);
            E_HA = params.mu_efficiency * (1 - opt_vars.rho_k(d)) * P_recv * t_DL;
            
            % Net energy and accumulate
            E_net = E_UL + E_CM - E_HA;
            E_eff_total = E_eff_total + (E_net / (1 - opt_vars.tau_k(d))) / params.num_realizations;
        end
    end
    
end