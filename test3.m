clear
close all
clc

rng(1000);

% nemvagott, negybevagott, vagott, vagott_negybevagott
images = read_images('img/vagott');

% Itt kell atirni hogy mit valasztunk szet mitol
% images.rat: TRPA1 1, TRPV1 2, BL6 3
C1 = images([images.type] == 1 & [images.rat] == 2); % TRPV1 IMQ
C2 = images([images.type] == 1 & [images.rat] == 3); % TRPA1 IMQ


% IMQ_96 = images([images.type] == 1 & [images.time] == 96 & [images.zoom] == 100);
% VAZ_96 = images([images.type] == 2 & [images.time] == 96 & [images.zoom] == 100);

% C1 = images([images.rat] == 1 & [images.zoom] >40);
% C2 = images([images.rat] == 3 & [images.zoom] >40);

% IMQ_24h = images([images.type] == 1 & [images.time] == 24 & [images.zoom] == 100);
% VAZ_24h = images([images.type] == 2 & [images.time] == 24 & [images.zoom] == 100);
% 
% IMQ_96 = images([images.type] == 1 & [images.time] == 96);
% VAZ_96 = images([images.type] == 2 & [images.time] == 96);

% IMQ_96 = images([images.type] == 1 & [images.time] == 24);
% VAZ_96 = images([images.type] == 2 & [images.time] == 24);


%% INNENTOL NEM KELL BELENYULNI

% LBP paraméterei: hány darab szomszédot nézünk és milyen távolságra
params.n = 8; % 8 darab szomszédot nézünk
params.rel_r = 20/100; % a távolság meg majd a zoom-tól függ, 100-as nagyítás esetén 20 pixel


% MINDEN KÉPHEZ KISZÁMOLJUK A FETAURE VEKTORT (AZAZ MEGHÍVJUK AZ LBP-t a
% megfeelelő zoom-al, stb)
C1 = cell2mat(arrayfun(@(image)generateFeatureVector(image, params), C1, 'UniformOutput',false));
C2 = cell2mat(arrayfun(@(image)generateFeatureVector(image, params), C2, 'UniformOutput',false));


%% Plot the feature vectors

% Megnézzük, hogy mennyire különülnek el a különböző kategóriák feature
% vektorai. Ha egybefolynak, az nem jó. Ha nem, akkor szuper, mert ez
% alapján szét lehet válogatni.
figure;
hold on; grid on;
plot(C1, 'r-');
plot(C2, 'b-');
plot(mean(C1, 2), 'r-', 'LineWidth',2);
plot(mean(C2, 2), 'b-', 'LineWidth',2);

%% Classification using support vector machines

% az osszes feature vektort bepakoljuk egy nagy X matrixba
% [--- elso kep vektora ----
%  --- masodik kep      ----
%  ----   stb
%                            ]
% meret: ahany kep van X 64 (ahany feature)

X = [transpose(C1); transpose(C2)];

% es a helyes valaszok oszlopvektora
% [ elso kep helyes valasz (1 vagy 2 kategoria) 
%   masodik kep helyes valasz
%         stb
%                              ]
% meret: ahany kep van X 1
              
y = [ones(size(C1, 2), 1); 2*ones(size(C2, 2), 1)];

% Levalasztjuk a kepek egy reszet tesztcsoportnak (akin nem tanulunk)
cv = cvpartition(size(X,1),'HoldOut',0.2); % 0.2, azaz 20% megy tesztnek
idx = cv.test;

X_train = X(~idx, :);
X_test = X(idx, :);

y_train = y(~idx);
y_test = y(idx);

% Illesztunk SVM-et a tanulocsoportra
SVMModel = fitcsvm(X_train,y_train, 'Standardize',true);

% Az SVM segitsegevel megprobaljuk osztalyozni a kepeket
y_pred_train = predict(SVMModel, X_train); % legalabb azt jol mondja-e amin tanult
y_pred_test = predict(SVMModel, X_test); % es jol mondja-e a tesztet

% Szamolunk szazalekos pontossagot a tanulo es a tesztcsoporton
accuracy = @(y, y_pred)100*(1-sum(y~=y_pred)/length(y));
fprintf('Accuracy on train set: %f\n', accuracy(y_train, y_pred_train));
fprintf('Accuracy on test set: %f\n', accuracy(y_test, y_pred_test));












%% Helper functions

function V = generateFeatureVector(image, params)
V = transpose(extractLBPFeatures(image.I, "NumNeighbors",params.n, "Radius", round(params.rel_r * image.zoom)));
end


% EZ OLVASSA BE AZ OSSZES KEPET
function images = read_images(directory)

files = dir(directory); % lekéri a mappában levő fájlok nevének listáját

images = []; %ebbe kerülnek majd a képek

for k = 1:length(files) % végiglépkedünk az összes fájlon a tömbben
    file = files(k);
    if file.isdir, continue, end % megnézzük, hogy mappa-e vagy tényleg fájl
    im = read_image([directory, '/', file.name]); % beolvassa a képet
    images = [images, im]; % hozzáadja az images tömb végéhez
end
end

% EZ TUD BEOLVASNI EGY DARAB KEPET
function im = read_image(image)

% kitaláljuk a fájl nevéből, hogy milyen típus (IMQ vagy VAZ), milyen
% patkány (BL6 vagy TRPa1 vagy TRPV1), hogy milyen nagyítás, stb
% image = img/balazs/TRPA1_VAZ_...

tokens = split(image, '/'); % tokens tomb: [img, balazs, TRPA1...]
filename = tokens{end}; % ez lesz a nev: TRPA1...

tokens = split(filename, {'_', '.'}); % szetvagja . es _ menten, tokens: [TRPA1, VAZ, 96...]

idx = 1;
im.rat = tokens{idx}; idx = idx + 1;
im.type = tokens{idx}; idx = idx + 1;
im.time = tokens{idx}; idx = idx + 1;
im.zoom = str2num(tokens{idx}); idx = idx + 1;
im.num1 = str2num(tokens{idx}); idx = idx + 1;
im.num2 = str2num(tokens{idx}); idx = idx + 1;
im.I = imread(image);

im.time = im.time(1:end-1);
im.time = str2num(im.time);

if strcmp(im.type, 'IMQ')
    im.type = 1;
elseif strcmp(im.type, 'VAZ')
    im.type = 2;
else
    im.type = 'ERROR'; % itt haltunk meg a kis Z betun a VAz-ban :D
end

if strcmp(im.rat, 'TRPA1')
    im.rat = 1;
elseif strcmp(im.rat, 'TRPV1')
    im.rat = 2;
elseif strcmp(im.rat, 'BL6')
    im.rat = 3;
else
    im.rat = 0;
end

end


% Árnyékok: a histogramon lesz egy pici hupli
% Gradiens kép, abszolútérték szummázva (van-e valami különbség -
% fehér-fekete váltakozások)
% histogram variancia (floodfillel kiszedni a szélét)
% ImageNet
% Kézzel berajzolgatni dolgokat, és vonalhosszt / területet / akármit
% számoltatni rá