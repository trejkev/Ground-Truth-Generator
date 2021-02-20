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
figuresMatrix = zeros(1,8);
cilindersMatrix = zeros(1,3);

%header = {'Name', 'X1', 'Y1', 'X2', 'Y2', 'X3', 'Y3', 'X4', 'Y4'};
%writecell(header, 'figures_container.xls')

base_file_id = fopen('ground_truth.world', 'r');
actual_line = string(fgetl(base_file_id));

%Look for the place where the world state modifier starts
actual_line_token = regexp(actual_line, 'state world_name', 'match');
while (size(actual_line_token) ~= 1)
    actual_line = string(fgetl(base_file_id));
    actual_line_token = regexp(actual_line, 'state world_name', 'match');
end

% Look for the models
while(actual_line ~= '-1')
    
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
        
        actual_box      = regexp(model_name, 'box', 'match');
        actual_cylinder = regexp(model_name, 'cylinder', 'match');

        % if it is a box
        if (size(actual_box) == 1)
            b = zeros(1, 8);
            [b(1,1), b(1,2), b(1,3), ... 
                b(1,4), b(1,5), b(1,6), ...
                b(1,7), b(1,8)] ...
                = box_corners(xPosition, yPosition, xScale, yScale, yawRotation*180/pi, model_name);
            figuresMatrix = [figuresMatrix; b(1:8)];
        end
        if(size(actual_cylinder) == 1)
            c = zeros(1, 3);
            [c(1,1), c(1,2), c(1,3)] = cylinder_dimensions(xPosition, yPosition, xScale, model_name);
            cilindersMatrix = [cilindersMatrix; c(1:3)];
        end
    end

    actual_line = string(fgetl(base_file_id));    
end
writematrix(figuresMatrix, 'figures_container.xlsx')
data = xlsread('figures_container.xlsx');
data = reshape(data, [], 2, 4);
data = permute(data, [2 3 1]);
n = size(data, 3);
p = arrayfun(@(k) polyshape(data(1,:,k),data(2,:,k)), 1:n);
q = p(1);
for k=2:n
    q = union(q,p(k));
end
plot(q)
axis equal
fprintf("Completed \n")

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
function [b2, b3, b4, b5, b6, b7, b8, b9] = box_corners(Center_X, Center_Y, Scale_X, Scale_Y, Rotation_deg, boxName)
    b1 = boxName;
    b6 = Center_X + Scale_X/2*cos(Rotation_deg) + Scale_Y/2*sin(Rotation_deg);
    b7 = Center_Y + Scale_X/2*sin(Rotation_deg) - Scale_Y/2*cos(Rotation_deg);
    b8 = Center_X + Scale_X/2*cos(Rotation_deg) - Scale_Y/2*sin(Rotation_deg);
    b9 = Center_Y + Scale_X/2*sin(Rotation_deg) + Scale_Y/2*cos(Rotation_deg);   
    b4 = Center_X - Scale_X/2*cos(Rotation_deg) + Scale_Y/2*sin(Rotation_deg);
    b5 = Center_Y - Scale_X/2*sin(Rotation_deg) - Scale_Y/2*cos(Rotation_deg);
    b2 = Center_X - Scale_X/2*cos(Rotation_deg) - Scale_Y/2*sin(Rotation_deg);
    b3 = Center_Y - Scale_X/2*sin(Rotation_deg) + Scale_Y/2*cos(Rotation_deg);
end

function [c2, c3, c4] = cylinder_dimensions(Center_X, Center_Y, Radius, cylinderName)
    c1 = cylinderName;
    c2 = Center_X;
    c3 = Center_Y;
    c4 = Radius;
end