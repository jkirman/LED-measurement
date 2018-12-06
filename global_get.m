function [var] = global_get(name)

    global JV_gb phtd_current_gb luminance_gb EQE_gb EL_gb brightness_gb solid_angle_gb;

    switch{name}
        case 'JV'
            var = JV_gb;
        case 'phtd_current'
            var = phtd_current_gb;
        case 'luminance'
            var = luminance_gb;
        case 'EQE'
            var = EQE_gb;
        case 'EL'
            var = EL_gb;
        case 'brightness'
            var = brightness_gb;
        case 'solid_angle'
            var = solid_angle_gb;
    end
    
end