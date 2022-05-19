function WrtArry(flNm, dt)
% writes a float64 array into a binary array

    fd = fopen(flNm, 'w');
    fwrite(fd,length(dt),'int64');
    fwrite(fd,dt,'double');
    fclose(fd);
end