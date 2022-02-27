function [att, unatt] =  LMMSE(e_d,s_a,s_u,att_prev,unatt_prev,lag)

% Lagged speech matrices
S_a = zeros(length(s_a),lag);
S_u = zeros(length(s_a),lag);

for m = 0:lag-1

  if m > 0

    S_a(:,m+1) = [zeros(m,1) ; s_a(1:end-m,1)];

    S_u(:,m+1) = [zeros(m,1) ; s_u(1:end-m,1)];

  elseif m == 0

    S_a(:,m+1) = s_a;

    S_u(:,m+1) = s_u;

  end

end  


%% Estimate of attended encoder
% Define Parameters
M = 1; %number of electrodes
K = lag; %number of transmitters 
N = length(s_a); % number of symbols ie. window length 

% Orthagonal projector
P_ort = eye(M*N) - S_a * pinv(S_a);

% LS estimate of the sample cov matrix of r 
C_rr = e_d*e_d.';

% Estimate c_N
c_n = 1/(M*(N-K))* trace(P_ort*C_rr*P_ort);

% Estimate of C_ww
C_ww = eye(M*N)*c_n;

% Estimate of C_theta
C_theta = eye(lag);

% LMMSE
att = att_prev + (C_theta*S_a.')*((S_a*C_theta*S_a.' + C_ww)\(e_d - S_a*att_prev));

%% Estimate of unattended encoder

% Orthagonal projector
P_ort = eye(M*N) - S_u * pinv(S_u);

% Estimate c_N
c_n = 1/(M*(N-K))* trace(P_ort*C_rr*P_ort);

% Estimate of C_ww
C_ww = eye(M*N)*c_n;

% Estimate of C_theta
% C_theta = eye(lag);

unatt = unatt_prev + (C_theta*S_u.')*((S_u*C_theta*S_u.' + C_ww)\(e_d - S_u*unatt_prev));
end