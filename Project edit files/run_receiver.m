% run_receiver.m
init_receiver;

% Run simulation
sim_out = sim('manchester_receiver.slx');

% Plot results
figure('Position', [100, 100, 1200, 800]);

subplot(3,2,1);
plot(sim_out.tout, sim_out.ax);
title('Acceleration X'); grid on;

subplot(3,2,2);
plot(sim_out.tout, sim_out.ay);
title('Acceleration Y'); grid on;

subplot(3,2,3);
plot(sim_out.tout, sim_out.az);
title('Acceleration Z'); grid on;

subplot(3,2,4);
plot(sim_out.tout, sim_out.ir);
title('IR Sensor'); grid on;

subplot(3,2,5);
stairs(sim_out.tout, sim_out.status);
title('Packet Status (1=Valid)'); grid on;
ylim([-0.1, 1.1]);

% Display statistics
valid_packets = sum(sim_out.status);
disp(['Valid packets received: ', num2str(valid_packets)]);