--- Presentation timeline for Koan 01: The Canvas is a Map
--- Total duration: 20 seconds at 30fps
return {
    duration = 20,
    fps = 30,

    timeline = {
        { at = 0,  show = "title",    fade_in = 0.5 },
        { at = 3,  show = "lesson",   fade_in = 0.8 },
        { at = 9,  show = "code",     fade_in = 0.5 },
        { at = 15, show = "concepts", fade_in = 0.5 },
    },
}
