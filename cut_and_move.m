clear
close
clc

sourcedir = 'img/vagott/BL6'; % eredeti mappa, hogy honnan
destinationdir = 'img/balazs_vagott'; % ahova tenni kell

negybevag = false;


%% innentol nem kell piszkalni

files = dir(sourcedir);

result_images = {};

for k = 1:length(files)
    clear im;
    file = files(k);
    if file.isdir, continue, end

    tokens = split(file.name, {'_', '(x', ').'});
    idx = 1;
    im.rat = tokens{idx}; idx = idx + 1;
    im.type = tokens{idx}; idx = idx + 1;
    im.time = tokens{idx}; idx = idx + 1;
    
    if length(tokens) == 5, im.num = '1'; 
        else, im.num = tokens{idx}; idx = idx + 1; end

   im.zoom = tokens{idx}; idx = idx + 1;
   assert(idx == length(tokens));
   

   
   im.I = imread([sourcedir, '/', file.name]);
   im.I = im2gray(im.I(:, :, 1:3));
   disp(im)
%    disp(size(im.I))
   if length(size(im.I)) > 2, disp('Not grayskale image, skipping'); continue; end

   im.I = im.I(1:end-120, :); % ALSO CSIK KIVAGASA -- ha nem kell vagni, kommenteld ki
   im.num2 = '1';
   
   s = size(im.I) / 2;
   s1 = floor(s(1));
   s2 = floor(s(2));

   im1 = im;
   im1.I = im.I(1:s1, 1:s2);
   im1.num2 = '1';

   im2 = im;
   im2.I = im.I(s1+1:end, 1:s2);
   im2.num2 = '2';

   im3 = im;
   im3.I = im.I(1:s1, s2+1:end);
   im3.num2 = '3';

   im4 = im;
   im4.I = im.I(s1+1:end, s2+1:end);
   im4.num2 = '4';

   if negybevag
        result_images = [result_images, {im1}, {im2}, {im3}, {im4}];
   else
        result_images = [result_images, im];
   end
end

for k = 1:length(result_images)
   im = result_images{k};
   
   im.filename = sprintf('%s_%s_%s_%s_%s_%s.png', im.rat, im.type, im.time, im.zoom, im.num, im.num2);
   
   imwrite(im.I, [destinationdir, '/', im.filename]);
end