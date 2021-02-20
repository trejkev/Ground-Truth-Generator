%----------------------------------------------%
% Universidad de Costa Rica
% Engineering Faculty
% Electrical Engineering School
% Graduation project: 
% SLAM Algorithms comparison 
% using ROS nodes
%
% Created by: Kevin Trejos Vargas
% email: kevin.trejosvargas@ucr.ac.cr
%
% Description: This script takes the .world
%     files created with Gazebo to generate
%     a set of x,y,z coordinated points
%     representing the models boundaries
%     in the world, which represent the 
%     ground truth for simulation purposes.
%
% Instructions for use:
%     1. Take the .world file and put it in
%        the same directory where is located
%        this .m file.
%     2. Rename it as 'ground_truth.world'.
%     3. Run the script and wait for its
%        completion, it will generate a csv
%        with the points coordinates and a set
%        of data matrices, one for each model.
%
% Note: The script only considers yaw rotation,
%       which is around Z axis (see sdf format
%       documentation).
%----------------------------------------------%

%%

mkdir individual_models_dim_properties

% Global variables
actual_box = 0;
actual_cilinder = 0;

poseFound = 0;
scaleFound = 0;

model_name = "";
xPosition = 0;
yPosition = 0;
yawRotation = 0;
cylRadius = 0;
xScale = 0;
yScale = 0;

base_file_id = fopen('ground_truth.world', 'r');
actual_line = string(fgetl(base_file_id));

%Look for the place where the world state modifier starts
actual_line_token = regexp(actual_line, 'state world_name', 'match');
while (size(actual_line_token) ~= 1)
    actual_line = string(fgetl(base_file_id));
    actual_line_token = regexp(actual_line, 'state world_name', 'match');
end

% Look for the models
while(actual_line ~= "</world>")
    
    actual_line_token = regexp(actual_line, 'model name', 'match');
    if (size(actual_line_token) == 1)
        model_name = get_model_name(actual_line);
        poseFound = 0;
        scaleFound = 0;
    end
    
    actual_line_token = regexp(actual_line, 'pose frame', 'match');
    if (size(actual_line_token) == 1 & poseFound == 0)
        [xPosition, yPosition, yawRotation] = get_model_pose(actual_line);
        poseFound = 1;
    end
    
    actual_line_token = regexp(actual_line, '<scale>', 'match');
    if (size(actual_line_token) == 1 & scaleFound == 0)
        [xScale, yScale] = get_model_scale(actual_line);
        scaleFound = 1;
    end
    
    actual_box      = regexp(model_name, 'box', 'match');
    actual_cylinder = regexp(model_name, 'cylinder', 'match');
    
    % if it is a box
    if (size(actual_box) == 1)
        box_corners(xPosition, yPosition, xScale, yScale, yawRotation*180/pi, model_name)
    elseif (size(actual_cylinder) == 1)
        cylinder_dimensions(xPosition, yPosition, xScale, model_name)
    end
    

    actual_line = string(fgetl(base_file_id));
end

%% 
% Function to get the name of the different models involved

function mod_name = get_model_name(actual_line)
    mod_name = regexp(actual_line, '''\w+''', 'match'); % Gets the model name with quotes
    mod_name = extractBetween(mod_name, "'", "'"); % Removes the quotes
end

function [xPos, yPos, yawRot] = get_model_pose(actual_line)
    actual_line = extractBetween(actual_line, "<pose frame=''>", "</pose>");
      out       = regexp(actual_line, ' ', 'split');
      xPos      = str2double(out(1));
      yPos      = str2double(out(2));
      yawRot    = str2double(out(6));
end

function [xScale, yScale] = get_model_scale(actual_line)
    actual_line = extractBetween(actual_line, "<scale>", "</scale>");
    out         = regexp(actual_line, ' ', 'split');
      xScale    = str2double(out(1));
      yScale    = str2double(out(2));
end

%%
% Function to calculate figures dimensions to plot
function box_corners(Center_X, Center_Y, Scale_X, Scale_Y, Rotation_deg, boxName)
    box    = zeros(9,0); % x and y positions, supports up to 300 boxes
    box(1) = boxName;
    box(2) = Center_X + Scale_X/2*cos(Rotation_deg) + Scale_Y/2*sin(Rotation_deg);
    box(3) = Center_Y + Scale_X/2*sin(Rotation_deg) - Scale_Y/2*cos(Rotation_deg);
    box(4) = Center_X + Scale_X/2*cos(Rotation_deg) - Scale_Y/2*sin(Rotation_deg);
    box(5) = Center_Y + Scale_X/2*sin(Rotation_deg) + Scale_Y/2*cos(Rotation_deg);   
    box(6) = Center_X - Scale_X/2*cos(Rotation_deg) + Scale_Y/2*sin(Rotation_deg);
    box(7) = Center_Y - Scale_X/2*sin(Rotation_deg) - Scale_Y/2*cos(Rotation_deg);
    box(8) = Center_X - Scale_X/2*cos(Rotation_deg) - Scale_Y/2*sin(Rotation_deg);
    box(9) = Center_Y - Scale_X/2*sin(Rotation_deg) + Scale_Y/2*cos(Rotation_deg);
    
end

function cylinder_dimensions(Center_X, Center_Y, Radius, cylinderName)
    cylinder    = zeros(4);
    cylinder(1) = cylinderName;
    cylinder(2) = Center_X;
    cylinder(3) = Center_Y;
    cylinder(4) = Radius;
    plot(cylinder)
end