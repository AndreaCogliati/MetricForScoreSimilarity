%% Load results

clear; close all;

%% Load score similarity results
load('resultsWithAlignment.mat')

%% Load key
programs = {'lilypond', 'musescore', 'finale', 'garageband'}; % lilypond is CDT
key = zeros(19,4);
key_file = fopen(fullfile('evaluations','key.txt'), 'r');
keys = textscan(key_file, '%s %s\n');
fclose(key_file);

for row = 1:size(key,1)
    start_row = 2 + (row - 1) * 5;
    for prg = 1:4
        key(row,prg) = find(strcmp(programs, keys{2}{start_row+prg-1}));
    end
end

%% Load results

N = 5;
scores = zeros(N,4,19,3);

for evaluator = 1:N
    
    filename = [num2str(evaluator), '.csv'];
    delimiter = ',';
    startRow = 2;
    endRow = 77;
    formatSpec = '%*s%f%f%f%*s%*s%*s%*s%*s%[^\n\r]';
    fileID = fopen(fullfile('evaluations',filename),'r');
    dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', delimiter, 'HeaderLines', startRow-1, 'ReturnOnError', false);
    fclose(fileID);

    raw_scores = [dataArray{1:end-1}];
    for i = 1:size(raw_scores,1)
        piece = ceil(i/4);
        sample = mod(i-1,4)+1;
        scores(evaluator, key(piece, sample), piece, :) = raw_scores(i,:); 
    end

end

%% Constants for plots

titles = {'Pitch Notation', 'Rhythm Notation', 'Note Positioning'};
labels = {'Proposed','MuseScore','Finale','GarageBand'};
METHODS = {'C','M','F','G'};

%% Normalize scores

norm_scores = zeros(4, 19 * N, 3);
for rev = 1:N
    rev_scores = squeeze(scores(rev,:,:,:));
    zscores = reshape(zscore(rev_scores(:)), size(rev_scores));
    norm_scores(:, (rev-1)*19+1:rev*19, :) = zscores * 2 + 5;
end

%% Prepare regression matrix

Y = [];
X = [];
pieces = {};
for method = 1:4
    for piece = 1:size(results,2)
        if results(method, piece, 1) >= 0
            Y(end+1,:) = mean(norm_scores(method, (0:4) * 19 + piece, :));
            X(end+1,:) = [1, squeeze(results(method, piece, :))'];
            pieces{end+1} = strcat(METHODS{method},'-',num2str(piece));
        end
    end
end

%% Calculate linear regression

B = X\Y; % Linear regression
YCalc = X * B;
Rsq = 1 - sum((Y - YCalc).^2)/sum((Y - mean(Y)).^2)

Rsq_pitch = 1 - sum((Y(:,1) - YCalc(:,1)).^2)/sum((Y(:,1) - mean(Y(:,1))).^2)
Rsq_rhythm = 1 - sum((Y(:,2) - YCalc(:,2)).^2)/sum((Y(:,2) - mean(Y(:,2))).^2)
Rsq_note_positioning = 1 - sum((Y(:,3) - YCalc(:,3)).^2)/sum((Y(:,3) - mean(Y(:,3))).^2)

figure; scatter(Y(:,1),YCalc(:,1)); title('Pitch Notation')
xlabel('Evaluator score');
ylabel('Predicted score');
figure; scatter(Y(:,2),YCalc(:,2)); title('Rhythm Notation')
xlabel('Evaluator score');
ylabel('Predicted score');
figure; scatter(Y(:,3),YCalc(:,3)); title('Note Positioning')
xlabel('Evaluator score');
ylabel('Predicted score');