function extract_frames_time(start_frame, end_frame)
%Prompts the user to choose a video file, and exports JPG images to a
%directory called 'frame_export' within the parent directory

[file_name, folder_name] = uigetfile({'*mp4', 'Quicktime files only'}, 'Choose a video file');

mov = VideoReader(strcat(folder_name, file_name));

if ~exist(strcat(folder_name,'frame_export'),'dir')
    mkdir(folder_name,'frame_export');
end
filepath = strcat(folder_name, 'frame_export');

h = waitbar(0,'Exporting frames...', 'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)
steps = length(start_frame:end_frame);

for k = start_frame:end_frame
    if getappdata(h,'canceling')
        break
    end
    
    waitbar((k-start_frame + 1) / steps)
    imwrite(read(mov,k), strcat(filepath,'/', num2str(k), '.jpg'), 'JPG')
end
if getappdata(h,'canceling')
    disp('frame export canceled')
else
    disp('frame export complete')
end

delete(h)

