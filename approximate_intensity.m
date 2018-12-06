function [radiant_flux, luminous_intensity, luminance] = approximate_intensity(PDcal, wavelength, phdt_current, lum_function, device_area)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    
    K = 683.002;
    solid_angle = 2*pi; % Half the entire sphere
    
    % Approximate radient flux
    interpolated_wavelengths = 360:0.1:max(PDcal(:,1));
    wavelengths_rf = interpolated_wavelengths;
    PDcal_interp = interp1(PDcal(:,1), PDcal(:,2), interpolated_wavelengths);
    
    wv_index = find(wavelengths_rf == wavelength*10^9);
    radiant_flux = PDcal_interp(wv_index) * phdt_current;
    radiant_intensity = radiant_flux / solid_angle; % Constant half of sphere
    
    % Interpolate luminance function
    lum_fn_interp = interp1(lum_function(:,1)/10^9, lum_function(:,2), wv);
    lum_fn_interp(isnan(lum_fn_interp)) = 0;
    lum_fn_interp = repelem(lum_fn_interp,20,1);
    
    % Calculate luminous intensity
    luminous_intensity = K * lum_fn_interp(wv_index) * radiant_intensity;
    
    % Calculate luminance
    luminance = luminous_intensity / device_area;
        
end