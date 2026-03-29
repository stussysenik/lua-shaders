local Recorder = {}
Recorder.__index = Recorder

--- Creates a new Recorder that captures frames from a Presenter.
--- Frames are saved as PNGs to the LÖVE save directory.
--- @param presenter table Presenter instance
--- @param output_name string Name for the output (e.g., "01_coordinates")
--- @return Recorder
function Recorder.new(presenter, output_name)
    local self = setmetatable({}, Recorder)
    self.presenter = presenter
    self.output_name = output_name
    self.frame_dir = "frames/" .. output_name
    self.frame_count = 0
    self.total_frames = math.ceil(presenter.duration * presenter.fps)
    self.dt = 1.0 / presenter.fps
    self.finished = false

    -- Create output directory in save directory
    love.filesystem.createDirectory(self.frame_dir)

    print(string.format(
        "Recording: %s (%d frames, %ds at %dfps)",
        output_name, self.total_frames, presenter.duration, presenter.fps
    ))

    return self
end

--- Captures one frame. Call this in love.update().
--- Uses fixed timestep (not wall clock) for deterministic output.
--- @return boolean done True when all frames have been captured
function Recorder:captureFrame()
    if self.finished then
        return true
    end

    -- Advance presenter by fixed dt
    self.presenter:update(self.dt)
    self.presenter:render()

    -- Capture the canvas to PNG
    local canvas = self.presenter:getCanvas()
    local image_data = canvas:newImageData()
    local filename = string.format("%s/frame_%04d.png", self.frame_dir, self.frame_count)
    image_data:encode("png", filename)

    self.frame_count = self.frame_count + 1

    -- Progress reporting every 30 frames
    if self.frame_count % 30 == 0 or self.frame_count == self.total_frames then
        print(string.format(
            "  Frame %d/%d (%.0f%%)",
            self.frame_count, self.total_frames,
            (self.frame_count / self.total_frames) * 100
        ))
    end

    if self.frame_count >= self.total_frames then
        self.finished = true
        print("Recording complete: " .. self.total_frames .. " frames")
        return true
    end

    return false
end

--- Returns the directory where frames were saved (absolute path).
--- @return string
function Recorder:getFrameDir()
    return love.filesystem.getSaveDirectory() .. "/" .. self.frame_dir
end

--- Returns progress as a fraction 0→1.
--- @return number
function Recorder:getProgress()
    return self.frame_count / self.total_frames
end

return Recorder
