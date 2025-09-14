function CRC = compute_crc8_mexstyle(data)
    % Simple CRC-8 (poly 0x07) — input: uint8 vector
    crc = uint8(0);
    for ii = 1:numel(data)
        crc = bitxor(crc, data(ii));
        for b=1:8
            if bitand(crc, 128)
                crc = bitxor( bitshift(crc,1,'uint8'), uint8(7) ); % poly 0x07
            else
                crc = bitshift(crc,1,'uint8');
            end
        end
    end
    CRC = crc;
end