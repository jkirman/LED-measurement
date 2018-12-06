function [current_efficiency] = calculate_current_efficiency(device_area, luminance, device_current)

    current_efficiency = luminance*device_area ./ device_current;

end

