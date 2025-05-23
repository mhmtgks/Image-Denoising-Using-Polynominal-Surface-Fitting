function image_denoising_polynomial_fitting()
    % Main function for image denoising using polynomial surface fitting
    
    % Load a sample noisy image (replace with your image path)
    noisy_img = imread('noisy.png');
    
    % Convert to grayscale if needed
    if size(noisy_img, 3) == 3
        noisy_img = rgb2gray(noisy_img);
    end
    
    % Convert to double for calculations
    noisy_img = im2double(noisy_img);
    
    % Parameters
    patch_size = 15;       % Size of each patch (odd number recommended)
    polynomial_degree = 2; % Degree of polynomial to fit
    
    % Denoise the image
    denoised_img = denoise_with_polynomial(noisy_img, patch_size, polynomial_degree);
    
    % Apply Gaussian smoothing for comparison
    gaussian_smoothed = imgaussfilt(noisy_img, 2);
    
    % Display results
    figure;
    subplot(1,3,1); imshow(noisy_img); title('Noisy Image');
    subplot(1,3,2); imshow(denoised_img); title('Polynomial Denoised');
    subplot(1,3,3); imshow(gaussian_smoothed); title('Gaussian Smoothed');
    
    % Calculate and display PSNR values
    psnr_poly = psnr(denoised_img, noisy_img);
    psnr_gauss = psnr(gaussian_smoothed, noisy_img);
    fprintf('PSNR Values:\n');
    fprintf('Polynomial Denoising: %.2f dB\n', psnr_poly);
    fprintf('Gaussian Smoothing: %.2f dB\n', psnr_gauss);
end

function denoised_img = denoise_with_polynomial(img, patch_size, degree)
    % Denoise image using polynomial surface fitting
    
    [rows, cols] = size(img);
    denoised_img = zeros(rows, cols);
    counts = zeros(rows, cols); % For averaging overlapping patches
    
    % Calculate patch radius
    radius = floor(patch_size/2);
    
    % Create grid coordinates centered at (0,0)
    [X, Y] = meshgrid(-radius:radius, -radius:radius);
    X = X(:);
    Y = Y(:);
    
    % Construct the design matrix for polynomial fitting
    A = [];
    for d = 0:degree
        for k = 0:d
            A = [A, X.^(d-k) .* Y.^k];
        end
    end
    disp(A);
    % Process each patch
    for i = radius+1:rows-radius
        for j = radius+1:cols-radius
            % Extract patch
            patch = img(i-radius:i+radius, j-radius:j+radius);
            patch_values = patch(:);
            
            % Fit polynomial surface using least squares
            coeffs = A \ patch_values;
            
            % Reconstruct the patch
            reconstructed_patch = reshape(A * coeffs, [patch_size, patch_size]);
            
            % Add to output image (averaging overlapping regions)
            denoised_img(i-radius:i+radius, j-radius:j+radius) = ...
                denoised_img(i-radius:i+radius, j-radius:j+radius) + reconstructed_patch;
            counts(i-radius:i+radius, j-radius:j+radius) = ...
                counts(i-radius:i+radius, j-radius:j+radius) + 1;
        end
    end
    
    % Average overlapping regions
    denoised_img = denoised_img ./ counts;
    
    % Handle edge pixels by copying from original image
    denoised_img(counts == 0) = img(counts == 0);
end