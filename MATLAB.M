clear; clc; close all;

%% ===================== GUI MODE =====================
createGUI();
return;

%% ===================== GUI FUNCTION =====================
function createGUI()
    fig = uifigure('Name','Sargam + Fourier Visualizer','Position',[200 100 1100 650]);
    fig.Color = [0.1 0.1 0.2];

    uilabel(fig,'Text','Sargam + Pressure Frequency Visualizer','Position',[240 590 650 40],...
        'FontSize',20,'FontWeight','bold','FontColor',[1 1 1]);

    % ===================== INPUTS =====================
    uilabel(fig,'Text','Enter Pressure Array (e.g., [1000 1500 2000 ...])','Position',[40 520 420 25],'FontColor',[1 1 1]);
    pressureField = uieditfield(fig,'text','Position',[40 490 420 30],'Value','[1000 1500 2000 2500 3000 3500 4000]');

    uilabel(fig,'Text','Resistance (Ohm)','Position',[40 450 120 25],'FontColor',[1 1 1]);
    RField = uieditfield(fig,'numeric','Position',[170 450 120 30],'Value',1000);

    uilabel(fig,'Text','Capacitance (F)','Position',[40 410 120 25],'FontColor',[1 1 1]);
    CField = uieditfield(fig,'numeric','Position',[170 410 120 30],'Value',1e-6);

    % ===================== SARGAM OPTIONS =====================
    uilabel(fig,'Text','Base Sa Frequency (Hz)','Position',[40 360 180 25],'FontColor',[1 1 1]);
    baseSaField = uieditfield(fig,'numeric','Position',[230 360 120 30],'Value',240);

    uilabel(fig,'Text','Intonation Mode','Position',[40 320 180 25],'FontColor',[1 1 1]);
    intonation = uidropdown(fig,'Items',{'Equal Temperament','Just Intonation'},'Position',[230 320 200 30],'Value','Equal Temperament');

    uilabel(fig,'Text','Note Duration (s)','Position',[40 280 180 25],'FontColor',[1 1 1]);
    durationField = uieditfield(fig,'numeric','Position',[230 280 120 30],'Value',0.6);

    uilabel(fig,'Text','Volume (0-1)','Position',[40 240 180 25],'FontColor',[1 1 1]);
    volumeField = uislider(fig,'Position',[230 250 200 3],'Limits',[0 1],'Value',0.8);

    % ===================== (BUTTONS REMOVED) =====================
    % Removed Sa-Re-Ga-Ma buttons here

    % Pressure play button
    uilabel(fig,'Text','Pressure Value to Note','Position',[40 140 180 25],'FontColor',[1 1 1]);
    pressureValue = uieditfield(fig,'numeric','Position',[230 140 120 30],'Value',2000);
    uibutton(fig,'Text','Play Pressure Note','Position',[370 140 170 30],...
        'ButtonPushedFcn', @(btn,event) playPressureNoteGUI(pressureValue.Value));

    % ===================== GRAPH BUTTONS =====================
    uibutton(fig,'Text','Run Fourier Animation','Position',[40 80 200 35],...
        'ButtonPushedFcn', @(btn,event) runFourier(pressureField.Value, RField.Value, CField.Value));

    uibutton(fig,'Text','Run Audio Visualization','Position',[260 80 200 35],...
        'ButtonPushedFcn', @(btn,event) runAudioVisual(pressureField.Value, RField.Value, CField.Value));

    uibutton(fig,'Text','Run Spectrum + Pressure-Freq','Position',[480 80 250 35],...
        'ButtonPushedFcn', @(btn,event) runSpectrum(pressureField.Value, RField.Value, CField.Value));

    % Status label
    statusLabel = uilabel(fig,'Text','Status: Ready','Position',[40 40 800 25],'FontColor',[1 1 1]);

    % ===================== KEYBOARD SUPPORT =====================
    fig.KeyPressFcn = @(src,event) keyboardPlay(src,event);

    function keyboardPlay(~, event)
        key = event.Key;
        switch key
            case '1'
                playNoteGUI(1);
            case '2'
                playNoteGUI(2);
            case '3'
                playNoteGUI(3);
            case '4'
                playNoteGUI(4);
            case '5'
                playNoteGUI(5);
            case '6'
                playNoteGUI(6);
            case '7'
                playNoteGUI(7);
            case '8'
                playNoteGUI(8);
        end
    end

    function playNoteGUI(idx)
        SARGAM = getSargam(baseSaField.Value, intonation.Value);

        % ----- NEW LIMIT CONDITION -----
        % Base Sa must be > 501.6 Hz
        if baseSaField.Value <= 501.6
            uialert(fig,'Base Sa must be > 501.6 Hz','Invalid Base Frequency');
            return;
        end

        % Highest frequency limit by RC
        HPF = 1/(2*pi*RField.Value*CField.Value);
        if SARGAM.freqs(idx) > HPF
            uialert(fig,sprintf('Note exceeds RC limit (%.2f Hz)',HPF),'Frequency Limit');
            return;
        end

        play_note(SARGAM.freqs(idx), 44100, durationField.Value, volumeField.Value);
        statusLabel.Text = sprintf('Playing %s', SARGAM.names{idx});
    end

    function playPressureNoteGUI(p)
        SARGAM = getSargam(baseSaField.Value, intonation.Value);

        idx = pressure_to_note(p);
        play_note(SARGAM.freqs(idx), 44100, durationField.Value, volumeField.Value);
        statusLabel.Text = sprintf('Pressure %d Pa → %s', p, SARGAM.names{idx});
    end
end


%% ===================== CORE FUNCTIONS =====================

function SARGAM = getSargam(baseSa, mode)
    if strcmp(mode,'Equal Temperament')
        ratios = 2.^([0 2 4 5 7 9 11 12]/12);
    else
        ratios = [1 9/8 5/4 4/3 3/2 5/3 15/8 2];
    end
    SARGAM.freqs = baseSa * ratios;
    SARGAM.names = {'Sa','Re','Ga','Ma','Pa','Dha','Ni',"Sa'"};
end

function play_note(freq, fs, duration, volume)
    t = 0:1/fs:duration;
    env = exp(-3*t);
    y = sin(2*pi*freq*t).*env;
    y = y/max(abs(y));
    sound(volume*y, fs);
end

function note_idx = pressure_to_note(P)
    Pmin = 1000;
    Pmax = 4000;
    P = max(min(P, Pmax), Pmin);
    note_idx = ceil( (P - Pmin)/(Pmax-Pmin) * 8 );
    note_idx = max(1, min(note_idx, 8));
end


%% ===================== GRAPH FUNCTIONS =====================

function [FILTERED_F2, FILTERED_P, freqs, amps] = processData(P, R, C)
    P = evalPressure(P);
    V = ptoV(P);
    L = vtol(V);
    F = Ltof(L);
    F2 = F + 501.6;

    HPF = 1/(2*pi*R*C);
    LPF = 98;

    IDX = (F2 < HPF) & (F2 > LPF);
    if sum(IDX) == 0
        IDX = (F2 < max(F2)*1.1) & (F2 > min(F2)*0.9);
    end

    FILTERED_F2 = F2(IDX);
    FILTERED_P = P(IDX);

    if isempty(FILTERED_F2)
        FILTERED_F2 = [110 220 330 440 550];
        FILTERED_P = P(1:length(FILTERED_F2));
    end

    x = sum(FILTERED_P);
    amps = FILTERED_P/x;
    amps = amps*1.5;
    freqs = FILTERED_F2;
end

function P = evalPressure(Pstr)
    if ischar(Pstr) || isstring(Pstr)
        P = eval(Pstr);
    end
end

function runFourier(P, R, C)
    [FILTERED_F2, FILTERED_P, freqs, amps] = processData(P, R, C);

    N_freqs = length(freqs);
    anim_time = 4;
    anim_samples = 200;
    anim_x = linspace(0, anim_time*2*pi, anim_samples);

    figure('Position', [50 50 1400 700], 'Color', [0.1 0.1 0.2]);

    color_map = hsv(N_freqs);
    components = zeros(N_freqs, length(anim_x));
    for k = 1:N_freqs
        components(k, :) = amps(k) * sin(freqs(k) * anim_x / max(freqs) * 2);
    end
    composite_signal = sum(components, 1);

    for frame = 1:10:length(anim_x)
        clf;
        subplot(2, 2, [1, 3]);
        hold on; grid on; axis equal;
        cumulative_x = 0; cumulative_y = 0;
        for k = 1:N_freqs
            phase = freqs(k) * anim_x(frame) / max(freqs) * 2;
            vec_x = amps(k) * cos(phase);
            vec_y = amps(k) * sin(phase);

            theta_circle = linspace(0, 2*pi, 50);
            circle_x = amps(k) * cos(theta_circle);
            circle_y = amps(k) * sin(theta_circle);
            plot(circle_x + cumulative_x, circle_y + cumulative_y, '--', 'Color', color_map(k,:));

            line([cumulative_x, cumulative_x + vec_x], ...
                [cumulative_y, cumulative_y + vec_y], ...
                'Color', color_map(k,:), 'LineWidth', 2);

            cumulative_x = cumulative_x + vec_x;
            cumulative_y = cumulative_y + vec_y;
        end

        plot(cumulative_x, cumulative_y, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0], 'MarkerEdgeColor', 'w');

        xlim([-1.2 1.2]); ylim([-1.2 1.2]);
        title('Fourier Epicycles','Color',[1 1 1]);

        subplot(2, 2, 2);
        hold on; grid on;
        for k = 1:N_freqs
            plot(anim_x(1:frame), components(k, 1:frame), 'LineWidth', 1.5);
        end
        title('Frequency Components','Color',[1 1 1]);

        subplot(2, 2, 4);
        plot(anim_x(1:frame), composite_signal(1:frame), 'LineWidth', 2.5);
        title('Composite Signal','Color',[1 1 1]);

        drawnow;
    end
end

function runAudioVisual(P, R, C)
    [FILTERED_F2, FILTERED_P, freqs, amps] = processData(P, R, C);

    fs = 44100;
    T = 8;
    t = 0:1/fs:T;
    x = sum(FILTERED_P);
    amplitudes = FILTERED_P/x;
    amplitudes = amplitudes*1.5;
    audio_signal = zeros(size(t));
    for k = 1:length(FILTERED_F2)
        audio_signal = audio_signal + amplitudes(k) * sin(2*pi*FILTERED_F2(k)*t);
    end
    audio_signal = audio_signal / max(abs(audio_signal));

    figure('Position', [100 100 1200 500], 'Color', [0.1 0.1 0.2]);

    window_size = 2000;
    step_size = 100;
    num_frames = floor((length(audio_signal)-window_size)/step_size);

    h_plot = plot(t(1:window_size), audio_signal(1:window_size), 'LineWidth', 2);
    hold on; grid on;
    player = audioplayer(audio_signal, fs);
    play(player);

    for frame = 1:num_frames
        start_idx = (frame-1)*step_size + 1;
        end_idx = start_idx + window_size - 1;
        set(h_plot,'XData',t(start_idx:end_idx),'YData',audio_signal(start_idx:end_idx));
        xlim([t(start_idx) t(start_idx)+window_size/fs]);
        drawnow;
        if ~isplaying(player), break; end
    end
end

function runSpectrum(P, R, C)
    [FILTERED_F2, FILTERED_P, freqs, amps] = processData(P, R, C);

    fs = 44100;
    T = 8;
    t = 0:1/fs:T;
    x = sum(FILTERED_P);
    amplitudes = FILTERED_P/x;
    amplitudes = amplitudes*1.5;
    audio_signal = zeros(size(t));
    for k = 1:length(FILTERED_F2)
        audio_signal = audio_signal + amplitudes(k) * sin(2*pi*FILTERED_F2(k)*t);
    end
    audio_signal = audio_signal / max(abs(audio_signal));

    figure('Position',[100 100 1300 500],'Color',[0.1 0.1 0.2]);

    subplot(1,3,1);
    N = length(audio_signal);
    Y = fft(audio_signal);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1)=2*P1(2:end-1);
    f = (0:(N/2))*fs/N;
    stem(f(1:2000),P1(1:2000),'Marker','none');
    title('Frequency Spectrum','Color',[1 1 1]);
    set(gca,'Color',[0.15 0.15 0.25],'XColor',[1 1 1],'YColor',[1 1 1]);

    subplot(1,3,2);
    scatter(FILTERED_P, freqs, 100, amps, 'filled');
    title('Pressure vs Frequency','Color',[1 1 1]);
    set(gca,'Color',[0.15 0.15 0.25],'XColor',[1 1 1],'YColor',[1 1 1]);
    colorbar;

    subplot(1,3,3);
    plot(FILTERED_F2, amps,'-o');
    title('Amplitude vs Frequency','Color',[1 1 1]);
    set(gca,'Color',[0.15 0.15 0.25],'XColor',[1 1 1],'YColor',[1 1 1]);
end


%% ===================== PHYSICS FUNCTIONS =====================

function v = ptoV(p)
    d  = 400e-12;
    t  = 5e-4;
    eo = 8.854e-12;
    er = 2000;
    v = (d .* p .* t) ./ (er * eo);
end

function L = vtol(v)
    k = 1e4;
    L = v ./ k;
end

function f = Ltof(L)
    Ls = 0.7;
    E  = 5e9;
    A  = pi*(0.8e-3)^2;
    mu = 7.3e-3;
    T = (E * A / Ls) .* L;
    f = (1./(2*Ls)) .* sqrt(T ./ mu);
end
