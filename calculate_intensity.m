function [wavelengths_rf, radiant_flux, luminous_intensity, luminance] = calculate_intensity(PDcal, wavelengths, ELSpec, phdt_current, lum_function, solid_angle, device_area)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    
    K = 683.002;
    
    % Normalize EL spectrum
    k = trapz(wavelengths, ELSpec);
    ELSpec_normalized = ELSpec/k;
    
    % Calculate radiant flux
    interpolated_wavelengths = 360:0.1:max(wavelengths);
    wavelengths_rf = interpolated_wavelengths;
    PDcal_interp = interp1(PDcal(:,1), PDcal(:,2), interpolated_wavelengths);
    ELSpec_normalized_interp = interp1(wavelengths, ELSpec_normalized, interpolated_wavelengths);
    radiant_flux = (PDcal_interp .^ -1) .* ELSpec_normalized_interp * phdt_current;
    
    % Calculate radiant intensity
    
    % Calculate spectral flux
%     spectral_flux = diff(radient_flux) ./ diff(interpolated_wavelengths);
%     wv = (interpolated_wavelengths(1:end-1) + interpolated_wavelengths(2:end));    
    
    % Calculate luminous flux
    lum_fn_interp = interp1(lum_function(:,1), lum_function(:,2), wv);
    luminous_flux = K * trapz(wv, lum_fn_interp .* spectral_flux);
    
    % Calculate luminous intensity
    luminous_intensity = luminous_flux / solid_angle;
    
    % Calculate luminance
    luminance = luminous_intensity / device_area;
    
end