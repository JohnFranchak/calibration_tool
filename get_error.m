clear all

%USE EXTRACT_FRAMES_TIME TO CREATE A DIRECTORY OF JPG IMAGES
%RENAME THAT DIRECTORY TO SOMETHING SENSIBLE

%CHANGE THESE VALUES TO SELECT THE RIGHT FOLDER AND RANGE OF FRAMES
id = '3'; %NAME OF DIRECTORY THAT CONTAINS FRAMES
starti = 344; %START FRAME
stopi = 350; %END FRAME

%ADJUST THESE VALUES TO MATCH FOV AND RESOLUTION OF YOUR ET
%CAMERA/RECORDING
fov_x = 101.55; %SCENE CAMERA DEGREES X
fov_y = 73.6; %SCENE CAMERA DEGREES Y

%GO THROUGH ALL FRAMES IN RANGE, PROMPTS WHETHER TO RECORD ACCURACY OR NOT
%(OR NO TO SKIP A FRAME, OR STOP TO EXIT)
%CLICK ON THE POINT OF GAZE AND THE POINT WHERE THE PPT SHOULD HAVE LOOKED
for i = starti:stopi
    im = imread(strcat(id,'/',num2str(i),'.jpg'),'JPG');
    imshow(im)
    ButtonName = questdlg('Record accuracy?','Record accuracy?','Yes', 'No','Stop','No');
    if strcmp(ButtonName,'Yes')
        [gazex(i), gazey(i)] = ginput(1);
        [targetx(i), targety(i)] = ginput(1);
    elseif strcmp(ButtonName,'Stop')
        break;
    end
end

im_size = size(im);

fov_res_x = im_size(1); %SCENE CAMERA PIXELS X
fov_res_y = im_size(2); %SCENE CAMERA PIXELS Y
to_degreesx = fov_res_x/fov_x;
to_degreesy = fov_res_y/fov_y;


distx = abs(gazex - targetx) ./ to_degreesx;
disty = abs(gazey - targety) ./ to_degreesy;
dist_center = sqrt(distx.^2 + disty.^2); %Use the distance formula to calculate average of XY errors

points = length(dist_center(dist_center > 0)) %Display the number of points used to calculate error
acc = mean(dist_center(dist_center > 0)) %Display the average error across points

outfile = fopen(strcat(num2str(id), '_calibration_', num2str(starti),'_', num2str(stopi),'.txt'),'w');

%fprintf(outfile, 'Overall accuracy: %.2f\n', acc);
%fprintf(outfile, 'Number of calibration points: %d\n', points);
fprintf(outfile, 'Folder\tFrame\tXGaze\tYGaze\tXTarget\tYTarget\tError\n');

frames = find(dist_center > 0);
for i = frames 
    fprintf(outfile, '%s\t%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.2f\n', id, i, gazex(i), gazey(i), targetx(i), targety(i), dist_center(i));

end

fclose(outfile);