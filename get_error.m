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

undistort_points = true; %set to false to use raw points

%GO THROUGH ALL FRAMES IN RANGE, PROMPTS WHETHER TO RECORD ACCURACY OR NOT
%(OR NO TO SKIP A FRAME, OR STOP TO EXIT)
%CLICK ON THE POINT OF GAZE AND THE POINT WHERE THE PPT SHOULD HAVE LOOKED
gazex = NaN(length(starti:stopi),1);
gazey = gazex;
targetx = gazex;
targety = gazex;

for i = starti:stopi
    im = imread(strcat(id,'/',num2str(i),'.jpg'),'JPG');
    imshow(im)
    ButtonName = questdlg('Record accuracy?','Record accuracy?','Yes', 'No','Stop','No');
    if strcmp(ButtonName,'Yes')
        [gazex(i-starti+1), gazey(i-starti+1)] = ginput(1);
        [targetx(i-starti+1), targety(i-starti+1)] = ginput(1);
    elseif strcmp(ButtonName,'Stop')
        break;
    end
end

im_size = size(im);

fov_res_x = im_size(1); %SCENE CAMERA PIXELS X
fov_res_y = im_size(2); %SCENE CAMERA PIXELS Y

to_degreesx = fov_res_x/fov_x;
to_degreesy = fov_res_y/fov_y;
distx_uncorr = abs(gazex - targetx) ./ to_degreesx;
disty_uncorr = abs(gazey - targety) ./ to_degreesy;
dist_center_uncorr = sqrt(distx_uncorr.^2 + disty_uncorr.^2); %Use the distance formula to calculate average of XY errors

points = length(dist_center_uncorr(dist_center_uncorr > 0)) %Display the number of points used to calculate error
acc_uncorr = mean(dist_center_uncorr(dist_center_uncorr > 0)) %Display the average error across points

if undistort_points
    try 
        load camparamsnf %Must match both camera and resolution of images used
        xmin = undistortPoints([0 fov_res_y/2], cam_nf);
        xmax = undistortPoints([fov_res_x fov_res_y/2], cam_nf);
        ymin = undistortPoints([fov_res_x/2 0], cam_nf);
        ymax = undistortPoints([fov_res_x/2 fov_res_y], cam_nf);
        
        eye_tmp = NaN(size([gazex gazey]));
        for j = 1:length(gazex)
            if not(isnan(gazex(j))) && not(isnan(gazey(j)))
                eye_tmp(j,:) = undistortPoints([gazex(j) gazey(j)], cam_nf);
            end
        end
        gazex_corr = (eye_tmp(:,1)-fov_res_x/2)./(xmax(1) - xmin(1)).*fov_x;
        gazey_corr = (eye_tmp(:,2)-fov_res_y/2)./(ymax(2) - ymin(2)).*fov_y;
        
        eye_tmp = NaN(size([targetx targety]));
        for j = 1:length(targetx)
            if not(isnan(targetx(j))) && not(isnan(targety(j)))
                eye_tmp(j,:) = undistortPoints([targetx(j) targety(j)], cam_nf);
            end
        end
        targetx_corr = (eye_tmp(:,1)-fov_res_x/2)./(xmax(1) - xmin(1)).*fov_x;
        targety_corr = (eye_tmp(:,2)-fov_res_y/2)./(ymax(2) - ymin(2)).*fov_y;
        
        distx_corr = abs(gazex_corr - targetx_corr);
        disty_corr = abs(gazey_corr - targety_corr);
        dist_center_corr = sqrt(distx_corr.^2 + disty_corr.^2);
        
        acc_corr = mean(dist_center_corr(dist_center_corr > 0)) %Display the average error across points
    catch
        disp("Could not undistort points, reverting to default distortion");
        gazex_corr = NaN(size(gazex));
        gazey_corr = NaN(size(gazex));
        targetx_corr = NaN(size(gazex));
        targety_corr = NaN(size(gazex));
        dist_center_corr = NaN(size(gazex));
    end
end

%Where to save the file
outfile = fopen(strcat(num2str(id), '_calibration_', num2str(starti),'_', num2str(stopi),'.csv'),'w');
fprintf(outfile, 'Folder,Frame,XGaze,YGaze,XTarget,YTarget,Error,XGazeCorr,YGazeCorr,XTargetCorr,YTargetCorr,ErrorCorr\n');

frames = find(dist_center_uncorr > 0);
for j = 1:length(frames)
    i = frames(j);
    fprintf(outfile, '%s,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', id, i+starti-1, gazex(i), gazey(i), targetx(i), targety(i), dist_center_uncorr(i), gazex_corr(i), gazey_corr(i), targetx_corr(i), targety_corr(i), dist_center_corr(i));
end

fclose(outfile);