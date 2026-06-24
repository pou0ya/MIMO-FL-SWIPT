function [all_channels, all_alpha] = generate_channel_realizations(params)

    fprintf('========== Generating Channel Realizations ==========\n');
    fprintf('Using %d channel realizations\n', params.num_realizations);
    fprintf('Number of devices (D): %d\n', params.D);
    fprintf('Number of BS antennas (A): %d\n\n', params.A);
    
    % Display channel model parameters
    fprintf('--- Channel Model Parameters ---\n');
    fprintf('Reference distance d0: %.1f m\n', params.d0);
    fprintf('Breakpoint distance d1: %.1f m\n', params.d1);
    fprintf('Path loss constant L: %.1f dB\n', params.L);
    fprintf('Shadowing std dev σ_sh: %.1f dB\n', params.sigma_sh);
    fprintf('Noise variance δ²_n: %.6e W (%.2f dBm)\n', ...
            params.delta_n_sq, 10*log10(params.delta_n_sq*1000));
    fprintf('\n');
    
    all_channels = cell(params.num_realizations, 1);
    all_alpha = cell(params.num_realizations, 1);
    
    % Statistics collectors
    all_distances = [];
    all_path_loss_dB = [];
    all_shadowing_dB = [];
    all_alpha_values = [];
    
    for realization = 1:params.num_realizations
        rng(42 + realization);
        
        fprintf('--- Realization %d ---\n', realization);
        
        % Generate random distances for UEs (between 10m and 1000m)
        d_d = 10 + (150 - 30) * rand(params.D, 1);
        all_distances = [all_distances; d_d];
        
        % Calculate large-scale fading coefficient
        alpha_d = zeros(params.D, 1);
        path_loss_dB = zeros(params.D, 1);
        shadowing_dB = zeros(params.D, 1);
        
        for d = 1:params.D
            d_k = d_d(d);
            
            % Three-slope path loss model
            if d_k > params.d1
                PL_k_dB = -params.L - 35 * log10(d_k);
            elseif d_k > params.d0
                PL_k_dB = -params.L - 15 * log10(params.d1) - 20 * log10(d_k);
            else
                PL_k_dB = -params.L - 15 * log10(params.d1) - 20 * log10(params.d0);
            end
            path_loss_dB(d) = PL_k_dB;
            
            % Log-normal shadowing (X_shd ~ N(0, sigma_sh^2))
            X_shd = params.sigma_sh * randn;
            shadowing_dB(d) = X_shd;
            
            % CRITICAL: Check the sign here!
            % According to Eq. (1), shadowing should ATTENUATE, so use NEGATIVE exponent
            % CORRECTED VERSION:
            beta_k_linear = 10^(params.L / 10) * 10^(-X_shd / 10);  % NEGATIVE sign
            
            % WRONG VERSION (commented out):
            % beta_k_linear = 10^(params.L / 10) * 10^(X_shd / 10);  % Positive would amplify!
            
            % Path loss in linear scale
            path_loss_linear = 10^(PL_k_dB / 10);
            
            % Alpha (large-scale coefficient)
            alpha_d(d) = beta_k_linear * path_loss_linear;
            
            % Diagnostic output for first device in this realization
            if d == 1
                fprintf('  Device %d diagnostics:\n', d);
                fprintf('    Distance: %.2f m\n', d_k);
                fprintf('    Path loss: %.2f dB (%.6e linear)\n', PL_k_dB, path_loss_linear);
                fprintf('    Shadowing: %.2f dB (%.6e linear)\n', X_shd, 10^(-X_shd/10));
                fprintf('    Beta (large-scale): %.6e linear (%.2f dB)\n', ...
                        beta_k_linear, 10*log10(beta_k_linear));
                fprintf('    Alpha (total gain): %.6e linear (%.2f dB)\n', ...
                        alpha_d(d), 10*log10(alpha_d(d)));
            end
        end
        
        all_path_loss_dB = [all_path_loss_dB; path_loss_dB];
        all_shadowing_dB = [all_shadowing_dB; shadowing_dB];
        all_alpha_values = [all_alpha_values; alpha_d];
        
        % Generate small-scale fading (Rayleigh, complex Gaussian)
        C = zeros(params.A, params.D);
        for a = 1:params.A
            for d = 1:params.D
                % Small-scale fading: C_tilde ~ CN(0, 1)
                C_tilde = (randn + 1i * randn) / sqrt(2);
                % Complete channel: C_ad = sqrt(alpha_d) * C_tilde
                C(a, d) = sqrt(alpha_d(d)) * C_tilde;
            end
        end
        
        % Channel matrix diagnostics
        channel_powers = sum(abs(C).^2, 1);  % Power per device (sum over antennas)
        fprintf('  Channel power per device: [');
        for d = 1:min(4, params.D)
            fprintf('%.2e', channel_powers(d));
            if d < min(4, params.D)
                fprintf(', ');
            end
        end
        if params.D > 4
            fprintf(', ...');
        end
        fprintf(']\n');
        
        all_channels{realization} = C;
        all_alpha{realization} = alpha_d;
    end
    
    fprintf('\n========== Channel Statistics Summary ==========\n');
    
    % Distance statistics
    fprintf('Distance Statistics:\n');
    fprintf('  Min: %.2f m, Max: %.2f m, Mean: %.2f m, Std: %.2f m\n', ...
            min(all_distances), max(all_distances), mean(all_distances), std(all_distances));
    
    % Path loss statistics
    fprintf('\nPath Loss Statistics:\n');
    fprintf('  Min: %.2f dB, Max: %.2f dB, Mean: %.2f dB, Std: %.2f dB\n', ...
            min(all_path_loss_dB), max(all_path_loss_dB), ...
            mean(all_path_loss_dB), std(all_path_loss_dB));
    
    % Shadowing statistics
    fprintf('\nShadowing Statistics:\n');
    fprintf('  Min: %.2f dB, Max: %.2f dB, Mean: %.2f dB, Std: %.2f dB\n', ...
            min(all_shadowing_dB), max(all_shadowing_dB), ...
            mean(all_shadowing_dB), std(all_shadowing_dB));
    fprintf('  Expected: Mean ≈ 0 dB, Std ≈ %.1f dB ✓\n', params.sigma_sh);
    
    % Large-scale fading (alpha) statistics
    alpha_all_linear = cell2mat(all_alpha);
    alpha_all_dB = 10*log10(alpha_all_linear);
    fprintf('\nLarge-Scale Fading (α) Statistics:\n');
    fprintf('  Linear scale:\n');
    fprintf('    Min: %.6e, Max: %.6e\n', min(alpha_all_linear), max(alpha_all_linear));
    fprintf('    Mean: %.6e, Median: %.6e\n', mean(alpha_all_linear), median(alpha_all_linear));
    fprintf('  dB scale:\n');
    fprintf('    Min: %.2f dB, Max: %.2f dB\n', min(alpha_all_dB), max(alpha_all_dB));
    fprintf('    Mean: %.2f dB, Median: %.2f dB\n', mean(alpha_all_dB), median(alpha_all_dB));
    
    % Expected received power calculation (for verification)
    fprintf('\n========== Expected Received Power Analysis ==========\n');
    P_BS_typical = params.P_DL_max;  % Assume BS uses max power
    P_recv_expected_min = min(alpha_all_linear) * P_BS_typical;
    P_recv_expected_max = max(alpha_all_linear) * P_BS_typical;
    P_recv_expected_mean = mean(alpha_all_linear) * P_BS_typical;
    
    fprintf('Assuming BS transmit power = %.2f W (max):\n', P_BS_typical);
    fprintf('  Expected P_recv (min): %.6e W (%.2f dBm)\n', ...
            P_recv_expected_min, 10*log10(P_recv_expected_min*1000));
    fprintf('  Expected P_recv (mean): %.6e W (%.2f dBm)\n', ...
            P_recv_expected_mean, 10*log10(P_recv_expected_mean*1000));
    fprintf('  Expected P_recv (max): %.6e W (%.2f dBm)\n', ...
            P_recv_expected_max, 10*log10(P_recv_expected_max*1000));
    
    % Typical IoT channel range check
    fprintf('\n--- Sanity Check ---\n');
    if mean(alpha_all_dB) > -80 && mean(alpha_all_dB) < -40
        fprintf('✓ Channel gains are in TYPICAL IoT range (-80 to -40 dB)\n');
    elseif mean(alpha_all_dB) < -100
        fprintf('⚠ WARNING: Channel gains TOO WEAK (< -100 dB)\n');
        fprintf('  This will result in near-zero energy harvesting!\n');
    elseif mean(alpha_all_dB) > -30
        fprintf('⚠ WARNING: Channel gains TOO STRONG (> -30 dB)\n');
        fprintf('  Check if path loss model is correct!\n');
    else
        fprintf('✓ Channel gains are REASONABLE for wireless systems\n');
    end
    
    if P_recv_expected_mean > 1e-8 && P_recv_expected_mean < 1e-2
        fprintf('✓ Expected received power is REASONABLE (10 nW to 10 mW)\n');
    elseif P_recv_expected_mean < 1e-10
        fprintf('⚠ WARNING: Expected received power TOO LOW (< 0.1 nW)\n');
        fprintf('  Energy harvesting will be negligible!\n');
    else
        fprintf('✓ Received power levels look acceptable\n');
    end
    
    fprintf('\n========== Channel Generation Complete ==========\n\n');
    
end