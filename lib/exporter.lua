local Exporter = {}

--- Exports a PNG frame sequence to GIF and MP4 using ffmpeg.
--- @param frame_dir string Absolute path to directory containing frame_NNNN.png files
--- @param output_name string Base name for output files (e.g., "01_coordinates")
--- @param fps number Frame rate
--- @return boolean success, string|nil error
function Exporter.export(frame_dir, output_name, fps)
    -- Ensure export directory exists in the project directory
    local project_dir = love.filesystem.getSourceBaseDirectory()
    if love.filesystem.getSource() ~= project_dir then
        project_dir = love.filesystem.getSource()
    end
    local export_dir = project_dir .. "/export"
    os.execute('mkdir -p "' .. export_dir .. '"')

    local frame_pattern = frame_dir .. "/frame_%04d.png"
    local gif_path = export_dir .. "/" .. output_name .. ".gif"
    local mp4_path = export_dir .. "/" .. output_name .. ".mp4"

    -- Export MP4 (H.264, yuv420p for Instagram compatibility)
    print("Exporting MP4...")
    local mp4_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -c:v libx264 -pix_fmt yuv420p -crf 18 "%s" 2>&1',
        fps, frame_pattern, mp4_path
    )
    local mp4_ok = os.execute(mp4_cmd)
    if mp4_ok ~= 0 then
        return false, "ffmpeg MP4 export failed"
    end
    print("  MP4: " .. mp4_path)

    -- Export GIF (two-pass for optimized palette)
    print("Exporting GIF...")
    local palette_path = frame_dir .. "/palette.png"
    local palette_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -vf "fps=%d,scale=540:-1:flags=lanczos,palettegen=max_colors=128" "%s" 2>&1',
        fps, frame_pattern, fps, palette_path
    )
    local palette_ok = os.execute(palette_cmd)
    if palette_ok ~= 0 then
        return false, "ffmpeg palette generation failed"
    end

    local gif_cmd = string.format(
        'ffmpeg -y -framerate %d -i "%s" -i "%s" -lavfi "fps=%d,scale=540:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" "%s" 2>&1',
        fps, frame_pattern, palette_path, fps, gif_path
    )
    local gif_ok = os.execute(gif_cmd)
    if gif_ok ~= 0 then
        return false, "ffmpeg GIF export failed"
    end
    print("  GIF: " .. gif_path)

    -- Clean up frame PNGs
    print("Cleaning up frames...")
    os.execute('rm -rf "' .. frame_dir .. '"')

    return true, nil
end

return Exporter
