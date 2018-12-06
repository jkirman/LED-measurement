function [interpolated_wavelengths, radiant_flux, luminous_intensity, luminance, current_efficiency] = calculate_luminance(wavelengths, noise_spec, EL_Spec, I_LED, I_det, responsivity, lum_function, solid_angle, device_area)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    
    K = 683.002;
    
    % Interpolate EL responsivity curve
    interpolated_wavelengths = 360:0.1:max(wavelengths);
    responsivity_interp = interp1(responsivity(:,1), responsivity(:,2), interpolated_wavelengths);

    % Fit and normalize EL spectra
    EL_Spec = abs(EL_Spec - noise_spec); % Zero noise
    for i = 1:size(EL_Spec, 2)
        EL_cfit = fit(wavelengths*1e-9, EL_Spec(:,i), 'gauss3');
        EL_fit(:,i) = feval(EL_cfit, interpolated_wavelengths*1e-9);
        [~,index] = max(EL_fit(:,i));
        centre_wavelength(i) = interpolated_wavelengths(index);
    end
    
%   wavelengths: the wavelengths covered by the radiant flux (in nm)
%   radient_flux: the radiant flux of the device (in W)
%   device_current: the current of the specific pixel in question (in A)
      
    I_det_total = trapz(interpolated_wavelengths*1e-9, responsivity_interp' .* EL_fit);
    k = (I_det' ./ I_det_total);
    radiant_flux = interpolated_wavelengths'*1e-9 .* EL_fit .* k;
    radiant_intensity = radiant_flux ./ solid_angle;
    
    radient_intensity_dwv = diff(radiant_intensity)./diff(interpolated_wavelengths'*1e-9);
    wavelengths_dwv = diff(interpolated_wavelengths)/2+interpolated_wavelengths(1:end-1);
    luminosity_interp = interp1(lum_function(:,1), lum_function(:,2), wavelengths_dwv,'linear','extrap');
    
    luminous_intensity = K * trapz(wavelengths_dwv'*1e-9, luminosity_interp' .* radient_intensity_dwv);
    luminance = luminous_intensity / device_area;
    current_efficiency = luminous_intensity ./ I_LED';
    [luminous_intensity_approx, luminance_approx, current_efficiency_approx] = approximate_luminance(centre_wavelength, I_LED, I_det, responsivity, lum_function, solid_angle, device_area);
    
end