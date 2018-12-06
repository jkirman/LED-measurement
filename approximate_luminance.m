function [radiant_flux, luminous_intensity, luminance, current_efficiency] = approximate_luminance(wavelength, I_det, I_LED, responsivity, lum_function, solid_angle, device_area)
%approximate_EQE
%
%   wavelength: the centre wavelength of emission (nm)
%   PDcal: the photodetector calibration curve (responsivity in A/W)
%   I_det: photodetector current (A)
%   I_LED: LED current (A)

    K = 683.002;

    % Approximate radient flux
    interpolated_wavelengths = 360:0.1:max(responsivity(:,1));
    wavelengths_rf = round(interpolated_wavelengths,1);
    PDcal_interp = interp1(responsivity(:,1), responsivity(:,2), interpolated_wavelengths);
    luminosity_interp = interp1(lum_function(:,1), lum_function(:,2), interpolated_wavelengths,'linear','extrap');
    wavelength = round(wavelength,1);    
    
    for i = 1:size(wavelength,2)
        wv_index = wavelengths_rf == wavelength(i);
        if size(wavelength,2) == 1
            radiant_flux = I_det' ./ PDcal_interp(wv_index);
            lum_function_value = luminosity_interp(wv_index);
        else
            radiant_flux(i) = I_det(i) ./ PDcal_interp(wv_index);
            lum_function_value(i) = luminosity_interp(wv_index);
        end
    end
    
    radiant_intensity = radiant_flux ./ solid_angle;
    luminous_intensity = K * lum_function_value .* radiant_intensity;
    luminance = luminous_intensity / device_area;    
    current_efficiency = luminous_intensity ./ I_LED';
    
end

