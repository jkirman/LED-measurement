function [] = move_motors(ESP, dist_x, dist_y, stop_button_handle)
%MOVE_MOTORS Summary of this function goes here
%   Detailed explanation goes here

    drawnow()
    stop_state = get(stop_button_handle, 'Value');

    if ~stop_state
        motor_x_coord = strcat('1PA',num2str(dist_x));
        motor_y_coord = strcat('2PA',num2str(dist_y));

        fprintf(ESP,motor_x_coord); %move x
        fprintf(ESP,motor_y_coord); %move y
        status = 0;
        while status ~= 10000 % [power-to-motors axis4 axis3 axis2 axis1]
            fprintf(ESP,'TS');temp = scanstr(ESP,'%f');
            status_marker = dec2bin(uint8(char(temp)));
            status=str2double(status_marker(3:7));
        end
    end
    
end