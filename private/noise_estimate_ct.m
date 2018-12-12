function sd = noise_estimate_ct(Nii,speak,K)
% Estimate noise in a CT image by fitting a variational Gaussian mixture
% model (GMM) to a range of its intensity histogram, and taking the
% component with a mean estimate closest to the value of air (HU = -1000)
% _______________________________________________________________________
%  Copyright (C) 2018 Wellcome Trust Centre for Neuroimaging


% Intensity distribution hyper-parameters
MU0 = ones([1 K]);
b0  = ones([1 K]);
n0  = ones([1 K]);
V0  = ones([1 1 K]);
    
if nargin < 2, speak = false; end
if nargin < 3, K     = 3; end
% Get image date (vectorised)
f = Nii.dat(:);

% Only keep voxels with values close to air (-1000)
f(~isfinite(f)) = [];
f(f == min(f))  = [];
f(f >= -980)    = [];
f(f <- 1020)    = [];

% Histogram bin voxels
x = min(f):max(f);
c = hist(f(:),x);

x = x';
c = c';

% Fit GMM
[~,MU,A] = spm_gmm(x,K,c,'BinWidth',1,'GaussPrior',{MU0,b0,V0,n0}, ...
                   'Tolerance',1e-5,'Start','linspace','Verbose',0,'Prune',true);

% Compute variance for each class
V = zeros(size(A));
for k=1:size(V,3)
    V(:,:,k) = inv(A(:,:,k));
end

% Get standard deviation of class closest to air (-1000)
[~,ix] = min(abs(abs(squeeze(MU)) - 1000));
sd     = sqrt(squeeze(V(:,:,ix)));

if speak
    p = zeros([numel(x) K],'single');
    for k=1:K
        p(:,k) = PI(k)*mvnpdf(x(:),MU(:,k),V(:,:,k));
    end
    sp = sum(p,2) + eps;    
    md = mean(diff(x));
    
    subplot(121)
    plot(x(:),p,'--',x(:),c/sum(c)/md,'b.',x(:),sp,'r'); 
    subplot(122)
    hist(f(:),x')
    drawnow
end

if 0
    figure;
    dm  = Nii.dat.dim;
    img = Nii.dat(:,:,ceil(dm(3)/2));   
    imagesc(img',[0 100]); axis off xy image; colormap(gray)
    title(['sd=' num2str(SD)]);
end
%==========================================================================